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

    var localIP: String {
        return IP.local() ?? "Unknown"
    }

    func startAdvertising() {
        if let connection {
            connection.cancel()
        }

        if let listener {
            listener.cancel()
        }

        guard let listener = try? NWListener(using: NWParameters(secret: "1234", identity: "abcd")) else {
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
            case .setup, .waiting, .cancelled:
                break
            case .ready:
                self.status = .advertising
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
            guard let self else { return }
            Logger.server.info("received connection: \(connection.debugDescription)")
            self.status = .connected
            self.connection = connection
        }

        listener.start(queue: .main)
    }

    func disconnect() {
        connection?.cancel()
        connection = nil
        listener?.cancel()
        listener = nil

        status = .disconnected
    }
}
