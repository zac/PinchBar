//
//  ContentView.swift
//  PinchBar
//
//  Created by Zac White on 3/27/24.
//

import SwiftUI

struct ContentView: View {
    @State private var client = Client()
    @State private var isPresented = false

    var body: some View {
        VStack {
            Spacer(minLength: 60)
            HStack {
                StreamView(videoGravity: .resizeAspect, frames: client.frames, touches: client.sendTouch)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .frame(width: 2008, height: 60)

                Button {
                    isPresented.toggle()
                } label: {
                    Image(systemName: "ellipsis")
                }
                .popover(isPresented: $isPresented, content: {
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
                    .padding()
                    .frame(width: 400, height: 600)
                })
            }
        }
        .padding(.horizontal, 60)
        .padding(.bottom, 20)
//        .toolbar {
//            ToolbarItem(placement: .bottomOrnament) {
//                Text(client.status.rawValue)
//            }
//        }
        .onAppear {
            client.startBrowsing()
        }
        .onDisappear {
            client.stopBrowsing()
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
