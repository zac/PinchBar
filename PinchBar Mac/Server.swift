//
//  Server.swift
//  PinchBar Mac
//
//  Created by Zac White on 3/27/24.
//

import Foundation
import SwiftIP
import os
import Network
import Transcoding

extension Logger {
    static let server = Logger(subsystem: "io.positron.PinchBar", category: "Server")
}

extension NWListener.State {
    var debugDescription: String {
        switch self {
        case .setup:
            "setup"
        case .waiting(let error):
            "waiting - \(error.localizedDescription)"
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

@Observable
class Server {
    enum Status {
        case disconnected
        case advertising
        case connecting
        case connected
    }

    private(set) var status: Status = .disconnected
    private let peerId: UUID = UUID()
    private let name: String = Host.current().localizedName ?? "No Name"

    private var listener: NWListener?
    private var connection: NWConnection?

    private let windowSource: TouchBarWindowSource = TouchBarWindowSource()
    private let videoEncoder = VideoEncoder(config: .ultraLowLatency)
    private var videoEncoderAnnexBAdaptor: VideoEncoderAnnexBAdaptor

    private var captureTask: Task<Void, Error>?
    private var videoEncoderTask: Task<Void, Error>?

    init() {
        videoEncoderAnnexBAdaptor = VideoEncoderAnnexBAdaptor(videoEncoder: videoEncoder)
    }

    var localIP: String {
        return IP.local() ?? "Unknown"
    }

    func startAdvertising() {
        if let connection {
            connection.cancel()
        }

        connection = nil

        if let listener {
            listener.cancel()
        }

        if let captureTask {
            captureTask.cancel()
        }

        if let videoEncoderTask {
            videoEncoderTask.cancel()
        }

        guard let listener = try? NWListener(using: NWParameters(passcode: "1234")) else {
            Logger.server.error("Could not create listener.")
            return
        }

        self.listener = listener

        var txtRecord = NWTXTRecord()
        txtRecord[TXTRecordKeys.name] = name
        txtRecord[TXTRecordKeys.peer_id] = peerId.uuidString

        listener.service = NWListener.Service(type: "_pinchbar._tcp", txtRecord: txtRecord)

        listener.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            Logger.server.info("updated state: \(state.debugDescription)")

            switch state {
            case .setup, .waiting:
                break
            case .ready:
                self.status = .advertising
            case .cancelled:
                self.disconnect()
            case .failed(let error):
                Logger.server.error("listener failed: \(error)")
                self.status = .disconnected

                // retry
                self.startAdvertising()
            @unknown default:
                break
            }
        }
        
        listener.newConnectionHandler = { [weak self] connection in
            guard let self, self.connection == nil else {
                Logger.server.info("reject connection: \(connection.debugDescription)")
                // reject the connection
                connection.cancel()
                return
            }

            Logger.server.info("received connection: \(connection.debugDescription)")
            self.connection = connection

            connection.start(queue: .main)

            self.startStreaming()
        }

        listener.start(queue: .main)
    }

    private func startStreaming() {

        guard let connection else { return }

        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .setup, .waiting, .preparing:
                break
            case .ready:
                self.status = .connected
                self.startStreaming()
            case .failed(let error):
                Logger.server.error("connection failed: \(error.localizedDescription)")
            case .cancelled:
                self.disconnect()
            @unknown default:
                break
            }
        }

        captureTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try await windowSource.startCapture()
            // Replace `captureSession.pixelBuffers` with your video data source
            for await frame in windowSource.frames {
                videoEncoder.encode(frame.data)
            }
        }

        videoEncoderTask = Task { [weak self] in
            guard let self else { return }
            for await data in videoEncoderAnnexBAdaptor.annexBData {

                let message = NWProtocolFramer.Message(messageType: .newFrame)
                let context = NWConnection.ContentContext(
                    identifier: "NewFrame",
                    metadata: [message]
                )

                self.connection?.send(content: data, contentContext: context, isComplete: true, completion: .idempotent)
            }
        }
    }

    func disconnect() {
        Task {
            captureTask?.cancel()
            captureTask = nil
            try await windowSource.stopCapture()

            videoEncoderTask?.cancel()
            videoEncoderTask = nil
        }

        connection?.cancel()
        connection = nil
        listener?.cancel()
        listener = nil

        status = .disconnected
    }
}
