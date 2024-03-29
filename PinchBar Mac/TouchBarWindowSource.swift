//
//  TouchBarWindowSource.swift
//  PinchBar Mac
//
//  Created by Zac White on 2/20/24.
//

import Foundation
import CoreMedia

import CoreImage
import CoreMedia
import os

extension Logger {
    static let frame = Logger(subsystem: "io.positron.PinchBar", category: "Frame")
}

class TouchBarWindowSource: WindowSource {

    private var stream: CGDisplayStream!
    private var simulator: DFRTouchBarSimulator?
    private var touchBar: DFRTouchBar!

    let frames: AsyncStream<Frame>
    private let queue = DispatchQueue(label: "io.positron.PinchBar.bufferProcessingQueue", qos: .userInitiated)
    private let streamContinuation: AsyncStream<Frame>.Continuation

    init() {
        Logger.frame.trace("TouchBarWindowSource.init()")
        (frames, streamContinuation) = AsyncStream<Frame>.makeStream()
    }

    func startCapture() {
        Logger.frame.trace("startCapture()")

        simulator = DFRTouchBarSimulatorCreate(.init(rawValue: 3), 0, .init(rawValue: 3));
        touchBar = DFRTouchBarSimulatorGetTouchBar(simulator)

        stream = DFRTouchBarCreateDisplayStream(touchBar, 0, .main, { [weak self] status, displayTime, frameSurface, update in
            guard let self, status == .frameComplete else {
                Logger.frame.trace("status: \(status.rawValue)")
                return
            }

            Logger.frame.trace("got frame: \(displayTime)")

            var rectCount: Int = 0
            var allRects: [CGRect] = []
            if let rects = update?.getRects(.dirtyRects, rectCount: &rectCount) {
                for i in 0..<rectCount {
                    allRects.append(rects[i])
                }
            }

            queue.async { [weak self] in
                guard let self else { return }
                do {
                    if let surface = frameSurface {
                        streamContinuation.yield(
                            .init(
                                buffer: try PixelBuffer(surface),
                                metadata: .init(frameCount: displayTime, dirtyRects: [])
                            )
                        )
                    }
                } catch {
                    Logger.frame.error("Could not create cmSampleBuffer: \(error)")
                }
            }
        }).takeRetainedValue()

        Logger.frame.debug("stream \(self.stream.debugDescription)")

        if stream.start() != CGError(rawValue: 0) {
            Logger.frame.error("error strarting stream")
        }
    }

    func stopCapture() async throws {
        guard let stream else {
            return
        }

        stream.stop()
        self.stream = nil

        DFRTouchBarSimulatorInvalidate(simulator)
        self.simulator = nil
    }

    deinit {
        Task { try await stopCapture() }
    }
}

enum SampleBufferCreationError: Error {
    case bufferCreationFailed(OSStatus)
    case noBuffer
}

extension IOSurfaceRef {
    var cmSampleBuffer: CMSampleBuffer {
        get throws {
            var pixelBuffer: Unmanaged<CVPixelBuffer>?

            let status = CVPixelBufferCreateWithIOSurface(kCFAllocatorDefault, self, nil, &pixelBuffer)

            if status != kCVReturnSuccess {
                // Handle error
                throw SampleBufferCreationError.bufferCreationFailed(status)
            }

            guard let newPixelBuffer = pixelBuffer else {
                throw SampleBufferCreationError.noBuffer
            }

            let format = try CMVideoFormatDescription(imageBuffer: newPixelBuffer.takeUnretainedValue())

            let timing = CMSampleTimingInfo(duration: CMTime.invalid, presentationTimeStamp: CMTime.zero, decodeTimeStamp: CMTime.invalid)

            let buffer = try CMSampleBuffer(imageBuffer: newPixelBuffer.takeUnretainedValue(), formatDescription: format, sampleTiming: timing)

            return buffer
        }
    }
}
