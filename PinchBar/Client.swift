//
//  Client.swift
//  PinchBar
//
//  Created by Zac White on 3/27/24.
//

import SwiftUI
import Network
import os
import Transcoding
import CoreMedia
import UIKit

extension Logger {
    static let client = Logger(subsystem: "io.positron.PinchBar", category: "Client")
}

extension NWConnection.State {
    var debugDescription: String {
        switch self {
        case .setup:
            "setup"
        case .waiting(let error):
            "waiting - \(error.localizedDescription)"
        case .preparing:
            "preparing"
        case .ready:
            "ready"
        case .failed(let error):
            "failed - \(error.localizedDescription)"
        case .cancelled:
            "cancelled"
        @unknown default:
            "unknown"
        }
    }
}

struct ServerInfo: Hashable {
    var name: String {
        guard case let .bonjour(txt) = result.metadata, let name = txt[TXTRecordKeys.name] else {
            Logger.client.warning("could not get name from metadata: \(result.metadata.debugDescription)")
            return result.endpoint.debugDescription
        }

        return name
    }

    var peerID: UUID {
        guard case let .bonjour(txt) = result.metadata, let peerID = txt[TXTRecordKeys.peer_id], let uuid = UUID(uuidString: peerID) else {
            Logger.client.warning("could not get peerID from endpoint: \(result.endpoint.debugDescription)")
            return UUID()
        }

        return uuid
    }

    let result: NWBrowser.Result
}

@Observable
class Client {
    enum Status: String {
        case disconnected
        case browsing
        case connecting
        case connected
    }

    var servers: [ServerInfo] = []
    var status: Status = .disconnected
    let frames: AsyncStream<CMSampleBuffer>
    private let frameContinuation: AsyncStream<CMSampleBuffer>.Continuation

    func status(for server: ServerInfo) -> Status {
        guard server.result.endpoint == connection?.endpoint else {
            return .disconnected
        }

        return status
    }

    private var browser: NWBrowser?
    private var connection: NWConnection?

    private let videoDecoder = VideoDecoder(config: .init(realTime: true))
    private let videoDecoderAnnexBAdaptor: VideoDecoderAnnexBAdaptor
    private var videoDecoderTask: Task<Void, Error>?

    init() {
        videoDecoderAnnexBAdaptor = VideoDecoderAnnexBAdaptor(
            videoDecoder: videoDecoder,
            codec: .hevc
        )

        (frames, frameContinuation) = AsyncStream<CMSampleBuffer>.makeStream()
    }

    func startBrowsing() {
        if let connection {
            connection.cancel()
            self.connection = nil
        }

        if let browser {
            browser.cancel()
            self.browser = nil
        }

        servers.removeAll()

        let parameters = NWParameters()
        parameters.requiredInterfaceType = .wifi
        parameters.includePeerToPeer = true
        let browser = NWBrowser(for: .bonjourWithTXTRecord(type: "_pinchbar._tcp", domain: nil), using: parameters)

        browser.stateUpdateHandler = { [weak self] state in
            guard let self else { return }

            switch state {
            case .failed(let error):
                Logger.client.error("browser failed: \(error.localizedDescription)")
                self.startBrowsing()
            case .ready:
                self.status = .browsing
            default:
                break
            }
        }

        browser.browseResultsChangedHandler = { [weak self] results, _ in
            guard let self else { return }
            servers = results.map { ServerInfo(result: $0) }
        }

        browser.start(queue: .main)
    }

    func connect(to server: ServerInfo) {
        // connect to the server.
        let connection = NWConnection(
            to: server.result.endpoint,
            using: NWParameters(passcode: "1234")
        )

        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            Logger.client.info("connection state update: \(state.debugDescription)")
            switch state {
            case .setup, .waiting, .preparing:
                self.status = .connecting
            case .ready:
                self.status = .connected
                self.receiveNextMessage()
            case .failed:
                self.disconnect()
            default:
                break
            }
        }

        videoDecoderTask = Task { [weak self] in
            guard let self else { return }
            Logger.client.trace("videoDecoderTask enter")
            for await decodedSampleBuffer in videoDecoder.decodedSampleBuffers {
                try? decodedSampleBuffer.setOutputPresentationTimeStamp(CMClockGetTime(.hostTimeClock))
                frameContinuation.yield(decodedSampleBuffer)
            }
            Logger.client.trace("videoDecoderTask exit")
        }

        self.connection = connection

        connection.start(queue: .main)
    }

    func disconnect() {
        if let connection {
            connection.cancel()
            self.connection = nil
        }

        videoDecoderTask?.cancel()
    }

    func sendTouch(_ uiTouch: UITouch) {
        guard let connection else { return }
        guard let data = try? JSONEncoder().encode(MouseEvent(uiTouch)) else { return }

        let message = NWProtocolFramer.Message(messageType: .control)
        let context = NWConnection.ContentContext(
            identifier: "NewFrame",
            metadata: [message]
        )

        Logger.client.trace("sending control message with data length: \(data.count)")

        connection.send(content: data, contentContext: context, isComplete: true, completion: .idempotent)
    }

    func receiveNextMessage() {
        Logger.client.log("receiveNextMessage")
        guard let connection else { return }

        connection.receiveMessage { [weak self] (content, context, isComplete, error) in
            guard let self else { return }
            Logger.client.log("connection.receiveMessage")
            // Extract your message type from the received context.
            if let message = context?.protocolMetadata(definition: PinchBarProtocol.definition) as? NWProtocolFramer.Message, message.messageType == .newFrame, let data = content {
                Logger.client.log("got frame! \(message.messageType.rawValue)")
                self.videoDecoderAnnexBAdaptor.decode(data)
            } else {
                Logger.client.info("no correct frame data in context: \(context.debugDescription)")
            }

            if let error {
                Logger.client.error("receive message error: \(error.localizedDescription)")
            } else {
                self.receiveNextMessage()
            }
        }
    }

    func stopBrowsing() {
        browser?.cancel()
        browser = nil

        status = .disconnected
    }
}

extension MouseEvent {
    init(_ uiTouch: UITouch) {
        let type: MouseEvent.EventType
        switch uiTouch.phase {
        case .began:
            type = .down
        case .moved:
            type = .dragged
        case .ended:
            type = .up
        default:
            type = .up
        }

        guard let view = uiTouch.view else {
            fatalError()
        }

        let point = uiTouch.location(in: view)
        let adjustedPoint = CGPoint(
            x: point.x / view.frame.width,
            y: point.y / view.frame.height
        )

        self = MouseEvent(type: type, location: adjustedPoint)
    }
}
