//
//  NALUFramer.swift
//  PinchBar
//
//  Created by Zac White on 3/27/24.
//

import Foundation
import Network

class AnnexBProtocol: NWProtocolFramerImplementation {
    static let definition = NWProtocolFramer.Definition(implementation: AnnexBProtocol.self)
    static var label: String { return "Annex B (ITU-T-REC-H.265)" }

    // NALU start code prefix
    private let naluStartCode: [UInt8] = [0x00, 0x00, 0x00, 0x01]

    required init(framer: NWProtocolFramer.Instance) {}

    func start(framer: NWProtocolFramer.Instance) -> NWProtocolFramer.StartResult {
        return .ready
    }

    func handleInput(framer: NWProtocolFramer.Instance) -> Int {
        while true {
            // Find the NALU start code prefix in the network buffer
            let parsed = framer.parseInput(minimumIncompleteLength: 4, maximumLength: 0) { buffer, isComplete in
                // ?
                return 0
            }

            return 0
        }
    }

    func handleOutput(framer: NWProtocolFramer.Instance, message: NWProtocolFramer.Message, messageLength: Int, isComplete: Bool) {
        try? framer.writeOutputNoCopy(length: messageLength)
    }

    func wakeup(framer: NWProtocolFramer.Instance) {}

    func stop(framer: NWProtocolFramer.Instance) -> Bool {
        return true
    }

    func cleanup(framer: NWProtocolFramer.Instance) {}
}

// Extend framer messages to handle storing your command types in the message metadata.
extension NWProtocolFramer.Message {
    convenience init(data: Data) {
        self.init(definition: AnnexBProtocol.definition)
        self["frame"] = data
    }

    var frame: Data {
        if let frame = self["frame"] as? Data {
            return frame
        } else {
            return Data()
        }
    }
}
