#import <Foundation/Foundation.h>
#import <Foundation/NSMapTable.h>
#import <UIKit/UIKit.h>

typedef enum {
	GESTURE_STATE_READY,
	GESTURE_STATE_STARTED,
	GESTURE_STATE_UPDATED,
	GESTURE_STATE_RECOGNIZED,
	GESTURE_STATE_CANCELLED,
} GestureState;

@interface Gesture : NSObject
{
	UIView *_view;
	GestureState _state;
	id _target;
	SEL _selector;
}

@property (retain) UIView *view;
@property (assign) GestureState state;
@property (retain) id target;
@property (assign) SEL selector;

- (id) initWithTarget: (id) target selector: (SEL) selector;

- (void) touchesBegan: (NSSet *) touches withEvent: (UIEvent *) event;
- (void) touchesMoved: (NSSet *) touches withEvent: (UIEvent *) event;
- (void) touchesEnded: (NSSet *) touches withEvent: (UIEvent *) event;
- (void) touchesCancelled: (NSSet *) touches withEvent: (UIEvent *) event;

- (void) reset;
- (void) invoke;

@end

@interface TapGesture : Gesture
{
	BOOL _active;
	int _maxDistance;
	CFTimeInterval _tapDuration;
	CFTimeInterval _tapInterval;
	NSTimer *_timer;
	int _tapCount;
	int _numberOfTaps;
	int _numberOfTouches;
	NSMapTable *_activeTouches;
}

@property (assign, readonly) NSMapTable *activeTouches;
@property (assign) int numberOfTaps;
@property (assign) int numberOfTouches;

- (id) initWithTarget: (id) target selector: (SEL) selector;

@end

@interface LongPressGesture : Gesture
{
	BOOL _active;
	BOOL _onRelease;
	int _maxDistance;
	int _numberOfTaps;
	int _numberOfTouches;
	CFTimeInterval _delay;
	NSMapTable *_activeTouches;
	NSTimer *_timer;
}

@property (assign, readonly) NSMapTable *activeTouches;
@property (assign) BOOL onRelease;
@property (assign) int numberOfTaps;
@property (assign) int numberOfTouches;
@property (assign) CFTimeInterval delay;

- (id) initWithTarget: (id) target selector: (SEL) selector;

- (BOOL) touchStillValid: (UITouch *) touch start: (CGPoint) start location: (CGPoint) location;
- (BOOL) touchesStillValid;

- (void) touchesBegan: (NSSet *) touches withEvent: (UIEvent *) event;
- (void) touchesMoved: (NSSet *) touches withEvent: (UIEvent *) event;
- (void) touchesEnded: (NSSet *) touches withEvent: (UIEvent *) event;
- (void) touchesCancelled: (NSSet *) touches withEvent: (UIEvent *) event;

- (void) reset;

@end

@interface SwipeGesture : LongPressGesture
{
	CGFloat _max;
	CGPoint _location;
	CGPoint _angle;
	CGFloat _minDistance;
	CGPoint _aspect;
	CGPoint _position;
}

@property (assign, readonly) CGPoint position;

- (void) setAngle: (CGFloat) angle;

- (void) touchesEnded: (NSSet *) touches withEvent: (UIEvent *) event;

- (BOOL) touchStillValid: (UITouch *) touch start: (CGPoint) start location: (CGPoint) location;

@end

@interface GestureView : UIView
{
	NSMutableSet *_gestures;
}

@property (retain, readwrite) NSMutableSet *gestures;

- (id) initWithFrame: (CGRect) frame;
- (id) initWithCoder: (NSCoder *) coder;

- (void) touchesBegan: (NSSet *) touches withEvent: (UIEvent *) event;
- (void) touchesMoved: (NSSet *) touches withEvent: (UIEvent *) event;
- (void) touchesEnded: (NSSet *) touches withEvent: (UIEvent *) event;
- (void) touchesCancelled: (NSSet *) touches withEvent: (UIEvent *) event;

- (void) addGesture: (Gesture *) gesture;

@end
