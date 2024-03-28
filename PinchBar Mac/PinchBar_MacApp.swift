//
//  PinchBar_MacApp.swift
//  PinchBar Mac
//
//  Created by Zac White on 3/27/24.
//

import SwiftUI

extension Server.Status {
    var systemImageName: String {
        switch self {
        case .disconnected:
            "visionpro.slash"
        case .advertising:
            "visionpro"
        case .connecting, .connected:
            "visionpro.fill"
        }
    }
}

@main
struct PinchBar_MacApp: App {
    @State var server = Server()

    var body: some Scene {
        MenuBarExtra("PinchBar", systemImage: server.status.systemImageName) {
            MenuBar()
                .environment(server)
        }
    }
}
