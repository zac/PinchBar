//
//  Server.swift
//  PinchBar Mac
//
//  Created by Zac White on 3/27/24.
//

import Foundation
import SwiftIP

@Observable
class Server {
    enum Status {
        case disconnected
        case advertising
        case connecting
        case connected
    }

    private(set) var status: Status = .disconnected

    var localIP: String {
        return IP.local() ?? "Unknown"
    }

    func startAdvertising() {
        status = .advertising
    }

    func disconnect() {
        status = .disconnected
    }
}
