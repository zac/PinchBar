//
//  WindowSource.swift
//  PinchBar
//
//  Created by Zac White on 3/28/24.
//

import Foundation
import CoreMedia

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
}
