//
//  StreamUIView.swift
//  PinchBar
//
//  Created by Zac White on 3/28/24.
//

import AVFoundation
import Foundation
import UIKit
import os

extension Logger {
    static let video = Logger(subsystem: "io.positron.PinchBar", category: "Video")
}

class StreamUIView: UIView {

    /// The view’s background color.
    public static var defaultBackgroundColor: UIColor = .black

    /// Returns the class used to create the layer for instances of this class.
    override public class var layerClass: AnyClass {
        AVSampleBufferDisplayLayer.self
    }

    /// The view’s Core Animation layer used for rendering.
    override public var layer: AVSampleBufferDisplayLayer {
        super.layer as! AVSampleBufferDisplayLayer
    }

    /// A value that specifies how the video is displayed within a player layer’s bounds.
    public var videoGravity: AVLayerVideoGravity = .resizeAspect {
        didSet {
            layer.videoGravity = videoGravity
        }
    }

    public var frames: AsyncStream<CMSampleBuffer>? {
        didSet {
            if let frames {
                Task { @MainActor in
                    for await frame in frames {
                        enqueue(frame)
                    }
                }
            }
        }
    }

    /// Returns an object initialized from data in a given unarchiver.
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = Self.defaultBackgroundColor
        layer.backgroundColor = Self.defaultBackgroundColor.cgColor
        layer.videoGravity = videoGravity
    }

    func enqueue(_ sampleBuffer: CMSampleBuffer?) {
        Logger.video.info("enqueued sample buffer")
        if Thread.isMainThread {
            if let sampleBuffer = sampleBuffer {
                layer.sampleBufferRenderer.enqueue(sampleBuffer)
            }
        } else {
            DispatchQueue.main.async {
                self.enqueue(sampleBuffer)
            }
        }
    }
}
