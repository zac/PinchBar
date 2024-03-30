//
//  ContentView.swift
//  PinchBar
//
//  Created by Zac White on 3/27/24.
//

import SwiftUI

struct ContentView: View {
    @State private var client = Client()

    var body: some View {
        VStack {
            Button {
                if client.status == .disconnected {
                    client.startBrowsing()
                } else {
                    client.stopBrowsing()
                }
            } label: {
                Text(client.status == .disconnected ? "Start" : "Stop")
            }
            List(client.servers, id: \.self) { server in
                let status = client.status(for: server)
                HStack {
                    Text(server.name)
                    Spacer()
                    Button {
                        if status == .disconnected {
                            client.connect(to: server)
                        } else {
                            client.disconnect()
                        }
                    } label: {
                        if status == .disconnected {
                            Text("Connect")
                        } else {
                            Text("Disconnect")
                        }
                    }
                }
            }

            StreamView(videoGravity: .resizeAspect, frames: client.frames, touches: client.sendTouch)
                .frame(height: 60)
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .bottomOrnament) {
                Text(client.status.rawValue)
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
