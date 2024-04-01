# PinchBar

Everyone misses the Touch Bar, right? This demo project screen captures the Mac's build-in Touch Bar simulator and encodes and transmits it over a peer-to-peer wifi network to  Vision Pro. 

## Demo

https://github.com/zac/PinchBar/assets/2525/6766aa1b-7fa6-4375-a0c1-68c0fc679597

## Technical Details
- A Mac menubar app accesses the raw frames from the Touch Bar simulator, which still exists on macOS Sonoma.
- Mac app broadcasts bonjour service and visionOS securely connects.
- Frames from the simulator are compressed on the Mac, sent to  Vision Pro and decompressed for display.
- When tapping and dragging on visionOS view, events are sent back to the Mac application which emulates those as clicks and drags.

## Gotchas

- The Mac Virtual Display feature on visionOS has a 'feature' which (sometimes?) makes all windows in the frontmost application 'inactive' when interacting or focusing on other windows in visionOS. This makes sense almost all the time... except if you want to interact with a Touch Bar 😡
- The quality isn't great. There's probably plenty of headroom on most networks to up the quality of the video, but needed it to be more performant for my testing so I was fine with low quality.
- The transport protocol supports password protecting the connection with a PIN, but hard-codes it to "1234" for demo purposes.

## Acknowledgements
- Thanks to Daniel Jalkut's [Touché](https://redsweater.com/touche/) for the inspiration.
- Thanks to @finnvoor's [Transcoding](https://github.com/finnvoor/Transcoding) for the video encoding / decoding implementation.
- Thanks to @jslegendre's [TouchBar-Simulator](https://github.com/jslegendre/TouchBar-Simulator) for defining the undocumented APIs to get frames from the Touch Bar simulator.
