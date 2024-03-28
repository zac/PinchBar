//
//  StreamView.swift
//  PinchBar
//
//  Created by Zac White on 3/28/24.
//

import SwiftUI
import AVFoundation
import CoreMedia

struct StreamView: UIViewRepresentable {
    typealias UIViewType = StreamUIView

    @State var videoGravity: AVLayerVideoGravity
    @State var frames: AsyncStream<CMSampleBuffer>

    func makeCoordinator() -> Coordinator {
        Coordinator(videoGravity: videoGravity, frames: frames)
    }

    class Coordinator {
        var videoGravity: AVLayerVideoGravity
        var frames: AsyncStream<CMSampleBuffer>

        init(videoGravity: AVLayerVideoGravity = .resizeAspect, frames: AsyncStream<CMSampleBuffer>) {
            self.videoGravity = videoGravity
            self.frames = frames
        }
    }

    func makeUIView(context: Context) -> StreamUIView {
        StreamUIView()
    }
    
    func updateUIView(_ uiView: StreamUIView, context: Context) {
        uiView.videoGravity = context.coordinator.videoGravity
        uiView.frames = context.coordinator.frames
    }
}
//
//#Preview {
//    StreamView()
//}
