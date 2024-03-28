//
//  PeerConnection.swift
//  PinchBar
//
//  Created by Zac White on 3/28/24.
//

import Foundation
import Network

class PeerConnection<Source: WindowSource> {
    private let connection: NWConnection
    private let windowSource: Source

    init(connection: NWConnection, windowSource: Source) {
        self.connection = connection
        self.windowSource = windowSource
    }
}
