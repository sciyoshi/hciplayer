#import "Gesture.h"

#import <math.h>

NSArray *NSArrayFromValueArray(CGPoint *points, int length)
{
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:length];
	for (int i = 0; i < length; i++)
		[array addObject:[NSValue valueWithCGPoint:points[i]]];
	return array;
}


@implementation SimplePathGestureRecognizer

- (void) touchesBegan: (NSSet *) touches withEvent: (UIEvent *) event
{
	_active = NO;
	_taps = [[touches anyObject] tapCount];
	_start = [[touches anyObject] locationInView:self.view];
}

- (void) touchesMoved: (NSSet *) touches withEvent: (UIEvent *) event
{
	if (!_active) {
		CGPoint location = [[touches anyObject] locationInView:self.view];
		
		if (abs(location.x - _start.x) > 30 || abs(location.y - _start.y) > 30) {
			_active = YES;
		}
	}
}

- (void) reset
{
	[super reset];
	
	_active = NO;
}

@end

@implementation	ElasticScaleGestureRecognizer
@synthesize location = _location;
@synthesize measure = _measure;
- (id)initWithTarget:(id)target action:(SEL)action {
	if (self = [super initWithTarget:target action:action]) {
		_angle.x = 1.0;
		_angle.y = 0.0;
		_minDistance = 40;
		_aspect.x = 0.8;
		_aspect.y = 1;
		_max = 0;
		_startTime = [NSDate alloc];
		[self setDelay: 0];		
	}
	return self;
}
- (void) setAngle: (CGFloat) angle {
	_angle.x = cos(angle);
	_angle.y = sin(angle);
}
- (void) reset {
	[super reset];
	_location.x = _location.x = _start.x = _start.y = 0;
	_max = 0;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	
	[self _delayedUpdateGesture];
	if ([[touches anyObject] tapCount] == [self numberOfTaps]) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
		_start = [[touches anyObject] locationInView:self.view];
		_startTime = [_startTime init];
		_measure = 0;
		_location.x = 0;
		_location.y = 0;
	}
	
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesMoved:touches withEvent:event]; 
	if ([[touches anyObject] tapCount] != _numberOfTaps || self.state == UIGestureRecognizerStateCancelled) {
		NSArray *args = [NSArray arrayWithObjects:[NSSet setWithSet:touches], event, nil];
		
        [self performSelector:@selector(endTouches:) withObject:args afterDelay:[self delay]];
		return;
	}
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	CGFloat elapsed = 0-[_startTime timeIntervalSinceNow] ;
	
	
	CGPoint loc = [[touches anyObject] locationInView:self.view];
	CGFloat x = _location.x, y = _location.y;
	
	loc.x -= _start.x;
	loc.y -= _start.y;
	
	_location.x = loc.x * _angle.x + loc.y * _angle.y;
	_location.y = loc.y * _angle.x - loc.x * _angle.y;
	_max = MAX(abs(_location.x), _max);
	if (_location.x >= x ){
		_measure = _measure  - abs(x - _location.x ) / MIN(MAX(elapsed,1.5),2.00);
	} else {
		_measure = _measure  + abs(x - _location.x ) / MIN(MAX(elapsed,1.5),2.00);
	}
	
	
	_startTime = [[NSDate alloc] init];

	if (self.state == UIGestureRecognizerStatePossible ) {
		if (abs(_max) > _minDistance) {
			[NSObject cancelPreviousPerformRequestsWithTarget:self];
			self.state = UIGestureRecognizerStateBegan;
		}
	} else if (abs(_location.y) > abs(_location.x) * _aspect.y + _minDistance) {
		self.state = UIGestureRecognizerStateCancelled;		
		NSArray *args = [NSArray arrayWithObjects:[NSSet setWithSet:touches], event, nil];
		
        [self performSelector:@selector(endTouches:) withObject:args afterDelay:[self delay]];
	} else if (self.state == UIGestureRecognizerStateBegan){
		self.state = UIGestureRecognizerStateChanged;
	}
	if (self.state == UIGestureRecognizerStateChanged){
		NSArray *args = [NSArray arrayWithObjects:[NSSet setWithSet:touches], event, nil];
		
		[self performSelector:@selector(moveTouches:) withObject:args afterDelay:0.1];
	}
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (self.state == UIGestureRecognizerStatePossible && [[touches anyObject] tapCount] == [self numberOfTaps]) {
		self.state = UIGestureRecognizerStateFailed;
	}
	NSArray *args = [NSArray arrayWithObjects:[NSSet setWithSet:touches], event, nil];
	
	[self performSelector:@selector(endTouches:) withObject:args afterDelay:[self delay]];
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesCancelled:touches withEvent:event];
	self.state = UIGestureRecognizerStateFailed;
}

- (void)moveTouches:(NSArray *)args {
    [self _clearUpdateTimer];
	[[self target] performSelector:[self action] withObject:self];
	[self touchesMoved:[args objectAtIndex:0] withEvent:[args objectAtIndex:1]];
}
- (void)endTouches:(NSArray *)args {
    [self _clearUpdateTimer];	
	[super touchesEnded:[args objectAtIndex:0] withEvent:[args objectAtIndex:1]];
}



- (int) numberOfTaps {
	return _numberOfTaps;
}

- (void) setNumberOfTaps: (int) newValue {
	_numberOfTaps = newValue;
}


- (CGFloat) delay {
	return _delay;
}

- (void) setDelay: (CGFloat) newValue {
	_delay = newValue;
}

@end


@implementation SwipeGestureRecognizer

- (id)initWithTarget:(id)target action:(SEL)action {
	if (self = [super initWithTarget:target action:action]) {
		_angle.x = 1.0;
		_angle.y = 0.0;
		_minDistance = -10;
		_maxDistance = 50;
		_aspect.x = 0.8;
		_aspect.y = 1;
		_max = 0;
		_startTime = [NSDate alloc];
	}
	return self;
}

- (void) setAngle: (CGFloat) angle
{
	_angle.x = cos(angle);
	_angle.y = sin(angle);
}

- (void) touchesBegan: (NSSet *) touches withEvent: (UIEvent *) event
{
	[super touchesBegan:touches withEvent:event];
	CGPoint location = [[touches anyObject] locationInView:self.view];
	_startTime = [_startTime init];
	_max = 0;
	_location.x = 0;
	_location.y = 0;
	_start.x = location.x;
	_start.y = location.y;
}

- (void) touchesMoved: (NSSet *) touches withEvent: (UIEvent *) event
{
	CGPoint location = [[touches anyObject] locationInView:self.view];
	
	location.x -= _start.x;
	location.y -= _start.y;
	
	_location.x = location.x * _angle.x + location.y * _angle.y;
	_location.y = location.y * _angle.x - location.x * _angle.y;
	
	if (_active) {
		self.state = 2;
		return;
	}
	
	if (_location.x < _minDistance) {
		self.state = 4;
		return;
	}
	
	if (!_onRelease && _location.x > _maxDistance) {
		// FIXME
		/*
		 ratio = 1 + time.time() - self._startTime
		 if self._max > abs(x) * (self.aspect[0] + (self.aspect[1] - self.aspect[0]) / ratio):
		 self.setState_(4)
		 else:
		 self._active = True
		 self.setState_(1)
		 return
		 */
	}
	
	if (abs(_location.y) > _max) {
		_max = abs(_location.y);
	}
	
	if (abs(_location.y) > abs(_location.x) * _aspect.y) {
		self.state = 4;
		return;
	}
}

- (void) touchesEnded: (NSSet *) touches withEvent: (UIEvent *) event
{
	CGPoint location = [[touches anyObject] locationInView:self.view];
	
	location.x -= _start.x;
	location.y -= _start.y;
	
	_location.x = location.x * _angle.x + location.y * _angle.y;
	
	if (_location.x > _maxDistance) {
		CGFloat ratio = 1 - [_startTime timeIntervalSinceNow] ;
		
		if (_max > abs(_location.x) * (_aspect.x + (_aspect.y - _aspect.x) / (ratio < 1 ? ratio : 1))) {
			self.state = 4;
		} else {
			self.state = 3;
		}
	}
}

- (void) reset
{
	[super reset];
	
	_max = 0;
}

@end





@implementation DollarTouchGestureRecognizer

- (id)initWithTarget:(id)target action:(SEL)action {
	if (self = [super initWithTarget:target action:action]) {		
		CGPoint circlePoints[] = { CGPointMake(127,141),CGPointMake(124,140),CGPointMake(120,139),CGPointMake(118,139),CGPointMake(116,139),CGPointMake(111,140),CGPointMake(109,141),CGPointMake(104,144),CGPointMake(100,147),CGPointMake(96,152),CGPointMake(93,157),CGPointMake(90,163),CGPointMake(87,169),CGPointMake(85,175),CGPointMake(83,181),CGPointMake(82,190),CGPointMake(82,195),CGPointMake(83,200),CGPointMake(84,205),CGPointMake(88,213),CGPointMake(91,216),CGPointMake(96,219),CGPointMake(103,222),CGPointMake(108,224),CGPointMake(111,224),CGPointMake(120,224),CGPointMake(133,223),CGPointMake(142,222),CGPointMake(152,218),CGPointMake(160,214),CGPointMake(167,210),CGPointMake(173,204),CGPointMake(178,198),CGPointMake(179,196),CGPointMake(182,188),CGPointMake(182,177),CGPointMake(178,167),CGPointMake(170,150),CGPointMake(163,138),CGPointMake(152,130),CGPointMake(143,129),CGPointMake(140,131),CGPointMake(129,136),CGPointMake(126,139) };
				
		NSArray *templates = [NSArray arrayWithObjects:
							  [[[DTTemplate alloc] initWithName:@"circle" points:NSArrayFromValueArray(circlePoints, sizeof(circlePoints)/sizeof(CGPoint)) squareSize:250] autorelease],
							  nil];
		recognizer = [[DTRecognizer alloc] initWithSquareSize:250 templates:templates];
	}
	return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	points = [[NSMutableArray alloc] init];
	// Enumerate through all the touch objects.
	for (UITouch *touch in touches)
	{
		CGPoint point = [touch locationInView:touch.view];
		NSLog(@"touchesBegan %f, %f", point.x, point.y);
		[points addObject:[NSValue valueWithCGPoint:point]];
	}	
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{  
	for (UITouch *touch in touches)
	{
		CGPoint point = [touch locationInView:touch.view];
		NSLog(@"touchesMoved %f, %f", point.x, point.y);
		[points addObject:[NSValue valueWithCGPoint:point]];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event { 
	result = [recognizer recognize:points];
	NSLog(@"Recognized %@ (%f)", result.name, result.score);

	if (result.score > 0.80){
		[[self target] performSelector:[self action] withObject:self];
		self.state = UIGestureRecognizerStateRecognized;
	} else {
		self.state = UIGestureRecognizerStateFailed;
	}
	[points release];
	points = nil;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesCancelled:touches withEvent:event];
	self.state = UIGestureRecognizerStateFailed;
}

@end

	