//
//  ContentView.swift
//  PinchBar
//
//  Created by Zac White on 3/27/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

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
                Text(server.name)
            }
        }
        .padding()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
