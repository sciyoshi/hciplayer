#import "Gestures.h"

#import <math.h>

@implementation Gesture

@synthesize view = _view;
@synthesize state = _state;
@synthesize target = _target;
@synthesize selector = _selector;

- (id) initWithTarget: (id) target selector: (SEL) selector
{
	if (self = [self init]) {
		self.state = GESTURE_STATE_READY;
		self.target = target;
		self.selector = selector;
	}
	return self;
}

- (void) touchesBegan: (NSSet *) touches withEvent: (UIEvent *) event
{

}

- (void) touchesMoved: (NSSet *) touches withEvent: (UIEvent *) event
{

}

- (void) touchesEnded: (NSSet *) touches withEvent: (UIEvent *) event
{

}

- (void) touchesCancelled: (NSSet *) touches withEvent: (UIEvent *) event
{

}

- (void) setState: (GestureState) state
{
	GestureState oldState = _state;

	_state = state;

	if (state != GESTURE_STATE_READY) {
		[self invoke];

		if (state == GESTURE_STATE_UPDATED) {
			_state = oldState;
		} else if (state == GESTURE_STATE_RECOGNIZED || state == GESTURE_STATE_CANCELLED) {
			[self reset];
		}
	}
}

- (void) reset
{
	self.state = GESTURE_STATE_READY;
}

- (void) invoke
{
	[self.target performSelector:self.selector withObject:self];
}

@end

@implementation TapGesture

@synthesize numberOfTaps = _numberOfTaps;
@synthesize numberOfTouches = _numberOfTouches;
@synthesize activeTouches = _activeTouches;

- (id) initWithTarget: (id) target selector: (SEL) selector
{
	if (self = [super initWithTarget:target selector:selector]) {
		_activeTouches = [[NSMapTable mapTableWithWeakToStrongObjects] retain];

		_maxDistance = 10;
		_tapDuration = 0.3;
		_tapInterval = 0.3;

		self.numberOfTaps = 1;
		self.numberOfTouches = 1;
	}
	return self;
}

- (void) reset
{
	[super reset];
	[_activeTouches removeAllObjects];
	if (_timer != nil) {
		[_timer invalidate];
		_timer = nil;
	}
	_active = NO;
	_tapCount = 0;
}

- (void) touchesBegan: (NSSet *) touches withEvent: (UIEvent *) event
{
	for (UITouch *touch in touches) {
		CGPoint point = [touch locationInView:self.view];
		[_activeTouches setObject:[NSValue value:&point withObjCType:@encode(CGPoint)] forKey:touch];
	}

	if ([_activeTouches count] == self.numberOfTouches) {
		_tapCount++;
		if (_tapCount > self.numberOfTaps) {
			[self reset];
			return;
		}
		_timer = [NSTimer scheduledTimerWithTimeInterval:_tapDuration target:self selector:@selector(timerElapsed:) userInfo:nil repeats:NO];
	} else if ([_activeTouches count] > self.numberOfTouches) {
		[self reset];
	}
}

- (BOOL) touchStillValid: (UITouch *) touch start: (CGPoint) start location: (CGPoint) location
{
	return abs(start.x - location.x) < _maxDistance && abs(start.y - location.y) < _maxDistance;
}

- (BOOL) touchesStillValid
{
	for (UITouch *touch in _activeTouches) {
		NSValue *value = [_activeTouches objectForKey:touch];

		if (!value) {
			continue;
		}

		CGPoint start;
		[value getValue:&start];
		CGPoint location = [touch locationInView:self.view];

		if (![self touchStillValid:touch start:start location:location]) {
			return NO;
		}
	}

	return YES;
}

- (void) touchesMoved: (NSSet *) touches withEvent: (UIEvent *) event
{
	if (_timer != nil && ![self touchesStillValid]) {
		[self reset];
	}
}

- (void) touchesEnded: (NSSet *) touches withEvent: (UIEvent *) event
{
	for (UITouch *touch in touches) {
		[_activeTouches removeObjectForKey:touch];
	}

	if ([_activeTouches count] == 0 && _timer != nil) {
		[_timer invalidate];
		if (_tapCount == self.numberOfTaps) {
			_active = YES;
		}
		_timer = [NSTimer scheduledTimerWithTimeInterval:_tapInterval target:self selector:@selector(timerElapsed:) userInfo:nil repeats:NO];
	}
}

- (void) touchesCancelled: (NSSet *) touches withEvent: (UIEvent *) event
{
	[self reset];
}

- (void) timerElapsed: (NSTimer *) timer
{
	if (_active) {
		self.state = GESTURE_STATE_RECOGNIZED;
	}

	[self reset];
}

@end

@implementation LongPressGesture

@synthesize activeTouches = _activeTouches;
@synthesize onRelease = _onRelease;
@synthesize numberOfTaps = _numberOfTaps;
@synthesize numberOfTouches = _numberOfTouches;
@synthesize delay = _delay;

- (id) initWithTarget: (id) target selector: (SEL) selector
{
	if (self = [super initWithTarget:target selector:selector]) {
		_activeTouches = [[NSMapTable mapTableWithWeakToStrongObjects] retain];

		_maxDistance = 20;

		self.onRelease = YES;
		self.numberOfTaps = 1;
		self.numberOfTouches = 1;
		self.delay = 0.5;
	}
	return self;
}

- (void) reset
{
	[super reset];
	[_activeTouches removeAllObjects];
	_active = NO;
}

- (void) touchesBegan: (NSSet *) touches withEvent: (UIEvent *) event
{
	if (_active) {
		return;
	}

	for (UITouch *touch in touches) {
		CGPoint point = [touch locationInView:self.view];
		[_activeTouches setObject:[NSValue value:&point withObjCType:@encode(CGPoint)] forKey:touch];
	}

	for (UITouch *touch in _activeTouches) {
		if ([touch tapCount] != self.numberOfTaps) {
			return;
		}
	}

	if ([_activeTouches count] == self.numberOfTouches && _timer == nil) {
		_timer = [NSTimer scheduledTimerWithTimeInterval:self.delay target:self selector:@selector(timerElapsed:) userInfo:nil repeats:NO];
	}
}

- (BOOL) touchStillValid: (UITouch *) touch start: (CGPoint) start location: (CGPoint) location
{
	return abs(start.x - location.x) < _maxDistance && abs(start.y - location.y) < _maxDistance;
}

- (BOOL) touchesStillValid
{
	for (UITouch *touch in _activeTouches) {
		NSValue *value = [_activeTouches objectForKey:touch];

		if (!value) {
			continue;
		}

		CGPoint start;
		[value getValue:&start];
		CGPoint location = [touch locationInView:self.view];

		if (![self touchStillValid:touch start:start location:location]) {
			return NO;
		}
	}

	return YES;
}

- (void) touchesMoved: (NSSet *) touches withEvent: (UIEvent *) event
{
	if (![self touchesStillValid]) {
		if (self.state == GESTURE_STATE_STARTED) {
			self.state = GESTURE_STATE_CANCELLED;
		} else {
			[self reset];
		}
	} else {
		if (!self.onRelease && self.state == GESTURE_STATE_STARTED) {
			self.state = GESTURE_STATE_UPDATED;
			return;
		}
	}
}

- (void) touchesEnded: (NSSet *) touches withEvent: (UIEvent *) event
{
	if (_active) {
		self.state = GESTURE_STATE_RECOGNIZED;
		return;
	}
 
	for (UITouch *touch in touches) {
		[_activeTouches removeObjectForKey:touch];
	}
}

- (void) touchesCancelled: (NSSet *) touches withEvent: (UIEvent *) event
{
	if (_active) {
		self.state = GESTURE_STATE_CANCELLED;
		return;
	}

	for (UITouch *touch in touches) {
		[_activeTouches removeObjectForKey:touch];
	}
}

- (void) timerElapsed: (NSTimer *) timer
{
	_timer = nil;

	_active = YES;

	if ([_activeTouches count] != self.numberOfTouches || ![self touchesStillValid]) {
		[self reset];
		return;
	}

	if (!self.onRelease) {
		self.state = GESTURE_STATE_STARTED;
	}
}

@end

@implementation SwipeGesture

@synthesize position = _position;

- (id) initWithTarget: (id) target selector: (SEL) selector;
{
	if (self = [super initWithTarget:target selector:selector]) {
		self.delay = 0.25;

		[self setAngle:0.0];

		_minDistance = -10;
		_aspect.x = 0.8;
		_aspect.y = 1;
	}
	return self;
}

- (void) setAngle: (CGFloat) angle
{
	_angle.x = cos(angle);
	_angle.y = sin(angle);
}

- (BOOL) touchStillValid: (UITouch *) touch start: (CGPoint) start location: (CGPoint) location
{
	CGPoint normalized;

	location.x -= start.x;
	location.y -= start.y;

	_position.x = normalized.x = location.x * _angle.x + location.y * _angle.y;
	_position.y = normalized.y = location.y * _angle.x - location.x * _angle.y;

	if (_active) {
		if (!self.onRelease) {
			return YES;
		}

		if (normalized.x < _maxDistance) {
			return NO;
		}		
	}

	if (normalized.x < _minDistance) {
		return NO;
	}

	if (abs(normalized.y) > abs(normalized.x) * _aspect.y) {
		return NO;
	}

	return YES;
}

- (void) touchesEnded: (NSSet *) touches withEvent: (UIEvent *) event
{
	if (_timer) {
		_active = YES;

		if ([_activeTouches count] == self.numberOfTouches && [self touchesStillValid]) {
			self.state = GESTURE_STATE_RECOGNIZED;
		} else {
			[self reset];
		}

		return;
	}

	[super touchesEnded:touches withEvent:event];
}

@end

@implementation GestureView

@synthesize gestures = _gestures;

- (id) initWithFrame: (CGRect) frame
{
	if (self = [super initWithFrame:frame]) {
		_gestures = [[NSMutableSet alloc] init];
	}
	return self;
}

- (id) initWithCoder: (NSCoder *) coder
{
	if (self = [super initWithCoder:coder]) {
		_gestures = [[NSMutableSet alloc] init];
	}
	return self;
}

- (void) addGesture: (Gesture *) gesture
{
	gesture.view = self;
	[_gestures addObject:gesture];
}

- (void) touchesBegan: (NSSet *) touches withEvent: (UIEvent *) event
{
	for (Gesture *gesture in self.gestures) {
		[gesture touchesBegan:touches withEvent:event];
	}
}

- (void) touchesMoved: (NSSet *) touches withEvent: (UIEvent *) event
{
	for (Gesture *gesture in _gestures) {
		[gesture touchesMoved:touches withEvent:event];
	}
}

- (void) touchesEnded: (NSSet *) touches withEvent: (UIEvent *) event
{
	for (Gesture *gesture in _gestures) {
		[gesture touchesEnded:touches withEvent:event];
	}
}

- (void) touchesCancelled: (NSSet *) touches withEvent: (UIEvent *) event
{
	for (Gesture *gesture in _gestures) {
		[gesture touchesCancelled:touches withEvent:event];
	}
}

@end
