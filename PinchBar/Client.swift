//
//  Client.swift
//  PinchBar
//
//  Created by Zac White on 3/27/24.
//

import SwiftUI
import Network
import os

extension Logger {
    static let client = Logger(subsystem: "io.positron.PinchBar", category: "Client")
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
        guard let txt = result.endpoint.txtRecord, let peerID = txt[TXTRecordKeys.peer_id], let uuid = UUID(uuidString: peerID) else {
            Logger.client.warning("could not get peerID from endpoint: \(result.endpoint.debugDescription)")
            return UUID()
        }

        return uuid
    }

    let result: NWBrowser.Result
}

@Observable
class Client {
    enum Status {
        case disconnected
        case browsing
        case connecting
        case connected
    }

    var servers: [ServerInfo] = []
    var status: Status = .disconnected

    private var browser: NWBrowser?
    private var connection: NWConnection?

    func startBrowsing() {
        if let connection {
            connection.cancel()
        }

        if let browser {
            browser.cancel()
        }

        servers.removeAll()

        let params = NWParameters(secret: "1234", identity: "abcd")
        let browser = NWBrowser(for: .bonjourWithTXTRecord(type: "_pinchbar._tcp", domain: nil), using: params)

        browser.stateUpdateHandler = { [weak self] state in
            guard let self else { return }

            switch state {
            case .failed(let error):
                Logger.client.error("browser failed: \(error.localizedDescription)")
                self.startBrowsing()
            case .ready:
                self.status = .browsing
            case .cancelled:
                self.servers.removeAll()
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

    func stopBrowsing() {
        browser?.cancel()
        browser = nil

        status = .disconnected
    }
}
