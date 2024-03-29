//
//  MenuBar.swift
//  PinchBar Mac
//
//  Created by Zac White on 2/9/24.
//

import SwiftUI

extension Server.Status {
    var color: Color {
        switch self {
        case .disconnected:
            return .red
        case .advertising:
            return .gray
        case .connecting:
            return .yellow
        case .connected:
            return .green
        }
    }
}

struct MenuBar: View {

    @Environment(Server.self) private var server

    var body: some View {
        VStack {
            HStack {
                Text("􀀁  ")
                    .foregroundStyle(server.status.color) +
                Text(server.localIP)
            }

            switch server.status {
            case .advertising:
                Text("Listening…")
            case .connected:
                Text("Connected")
            case .connecting:
                Text("Connecting…")
            case .disconnected:
                Text("Disconnected")
            }

            Divider()

            Button {
                if server.status == .disconnected {
                    server.startListening()
                } else if server.status == .advertising {
                    server.stopListening()
                } else if server.status == .connected {
                    server.disconnect()
                }
            } label: {
                switch server.status {
                case .advertising:
                    Text("Stop Listening")
                case .connected:
                    Text("Disconnect")
                case .disconnected, .connecting:
                    Text("Start Listening")
                }
            }
            .disabled(server.status == .connecting)

            Divider()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("Quit")
            }.keyboardShortcut("q")
        }
    }
}

#Preview {
    MenuBar()
}
