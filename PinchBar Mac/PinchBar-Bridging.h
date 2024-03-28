//
//  PinchBar-Bridging.h
//  PinchBar Mac
//
//  Created by Zac White on 2/20/24.
//

#ifndef PinchBar_Bridging_h
#define PinchBar_Bridging_h

#import <Cocoa/Cocoa.h>

/* From DFRFoundation.framework */
@interface DFRTouchBarSimulator: NSObject
@end

@interface DFRTouchBar: NSObject
@end

typedef enum  {
    DFRTouchBarFirstGeneration = 2,
    DFRTouchBarSecondGeneration = 3,
} DFRTouchBarStyle;

/*!
 @function DFRTouchBarSimulatorCreate
 @abstract C-style initializer for DFRTouchBarSimulator
 @param generation First generation (2) uses legacy API, second generation (3) uses newer API as shown in this project
 @param properties This is always NULL so I'm really not sure what options exist.
 @param sameAsGeneration Not sure why this is needed but if it holds a different value than generation, it won't work.
 */
DFRTouchBarSimulator* DFRTouchBarSimulatorCreate(DFRTouchBarStyle generation, id properties, DFRTouchBarStyle sameAsGeneration);

DFRTouchBar* DFRTouchBarSimulatorGetTouchBar(DFRTouchBarSimulator*);

BOOL DFRTouchBarSimulatorPostEventWithMouseActivity(DFRTouchBarSimulator*, NSEventType type, NSPoint p);

CGDisplayStreamRef DFRTouchBarCreateDisplayStream(DFRTouchBar *touchBar, int displayID, dispatch_queue_t queue, CGDisplayStreamFrameAvailableHandler handler);

void DFRTouchBarSimulatorInvalidate(DFRTouchBarSimulator*);

#endif /* PinchBar_Bridging_h */
