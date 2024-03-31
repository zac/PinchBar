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

    var frames: AsyncStream<Frame>
    private var streamContinuation: AsyncStream<Frame>.Continuation

    private var lastFrame: Frame?
    private var frameTimer: Timer?

    init() {
        Logger.frame.trace("TouchBarWindowSource.init()")
        (frames, streamContinuation) = AsyncStream<Frame>.makeStream()
    }

    func startCapture() {
        (frames, streamContinuation) = AsyncStream<Frame>.makeStream()

        Logger.frame.trace("startCapture()")

        simulator = DFRTouchBarSimulatorCreate(.init(rawValue: 3), 0, .init(rawValue: 3));
        let touchBar = DFRTouchBarSimulatorGetTouchBar(simulator)

        self.frameTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] _ in
            guard let self, let lastFrame else { return }
            streamContinuation.yield(lastFrame)
        })

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

            do {
                if let surface = frameSurface {
                    let frame = Frame(
                        buffer: try PixelBuffer(surface),
                        metadata: .init(frameCount: displayTime, dirtyRects: [])
                    )

                    lastFrame = frame
                    streamContinuation.yield(frame)
                }
            } catch {
                Logger.frame.error("Could not create cmSampleBuffer: \(error)")
            }
        }).takeRetainedValue()

        Logger.frame.debug("stream \(self.stream.debugDescription)")

        if stream.start() != CGError(rawValue: 0) {
            Logger.frame.error("error strarting stream")
        }
    }

    func perform(event: MouseEvent) {
        guard let simulator else { return }

        let size = CGSize(width: 1004, height: 30)//DFRGetScreenSize()
        let adjustedPoint = NSPoint(
            x: size.width * event.location.x,
            y: size.height * event.location.y
        )

        DFRTouchBarSimulatorPostEventWithMouseActivity(simulator, event.type.nsEventType, adjustedPoint)
    }

    func stopCapture() {
        guard let stream else {
            return
        }

        stream.stop()
        self.stream = nil

        frameTimer?.invalidate()
        frameTimer = nil

        DFRTouchBarSimulatorInvalidate(simulator)
        self.simulator = nil

        (frames, streamContinuation) = AsyncStream<Frame>.makeStream()
    }

    deinit {
        stopCapture()
    }
}

extension MouseEvent.EventType {
    var nsEventType: NSEvent.EventType {
        switch self {
        case .down:
            return .leftMouseDown
        case .dragged:
            return .leftMouseDragged
        case .up:
            return .leftMouseUp
        }
    }
}
