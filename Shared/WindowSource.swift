//
//  WindowSource.swift
//  PinchBar
//
//  Created by Zac White on 3/28/24.
//

import Foundation
import CoreMedia

struct MouseEvent: Codable {
    enum EventType: Int, Codable {
        case down
        case dragged
        case up
    }

    var type: EventType
    var location: CGPoint
}

struct Frame {

    struct Metadata {
        var frameCount: UInt64
        var dirtyRects: [CGRect]
    }

    var buffer: PixelBuffer
    var metadata: Metadata
}

protocol WindowSource {
    var frames: AsyncStream<Frame> { get }

    func startCapture() async throws
    func stopCapture() async throws

    func perform(event: MouseEvent)
}

struct AnyWindowSource: WindowSource {
    let base: WindowSource

    var frames: AsyncStream<Frame> {
        base.frames
    }

    func startCapture() async throws {
        try await base.startCapture()
    }

    func stopCapture() async throws {
        try await base.stopCapture()
    }

    func perform(event: MouseEvent) {
        base.perform(event: event)
    }
}
