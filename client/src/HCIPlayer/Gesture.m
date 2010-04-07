#import "Gesture.h"

#import <math.h>


@implementation NSArray (Reverse)
NSArray *NSArrayFromValueArray(CGPoint *points, int length)
{
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:length];
	for (int i = 0; i < length; i++)
		[array addObject:[NSValue valueWithCGPoint:points[i]]];
	return array;
}

- (NSArray *)reversedArray {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self count]];
    NSEnumerator *enumerator = [self reverseObjectEnumerator];
    for (id element in enumerator) {
        [array addObject:element];
    }
    return array;
}

@end

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
	if ([[touches anyObject] tapCount] > 1){
		self.state = UIGestureRecognizerStateFailed;
		[super touchesEnded:touches withEvent:event];
		return;
	}
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
@synthesize result;
- (id)initWithTarget:(id)target action:(SEL)action {
	if (self = [super initWithTarget:target action:action]) {		
		CGPoint circlePoints[] = { CGPointMake(127,141),CGPointMake(124,140),CGPointMake(120,139),CGPointMake(118,139),CGPointMake(116,139),CGPointMake(111,140),CGPointMake(109,141),CGPointMake(104,144),
		CGPointMake(100,147),CGPointMake(96,152),CGPointMake(93,157),CGPointMake(90,163),CGPointMake(87,169),CGPointMake(85,175),CGPointMake(83,181),CGPointMake(82,190),CGPointMake(82,195),CGPointMake(83,200),
		CGPointMake(84,205),CGPointMake(88,213),CGPointMake(91,216),CGPointMake(96,219),CGPointMake(103,222),CGPointMake(108,224),CGPointMake(111,224),CGPointMake(120,224),CGPointMake(133,223),CGPointMake(142,222),
		CGPointMake(152,218),CGPointMake(160,214),CGPointMake(167,210),CGPointMake(173,204),CGPointMake(178,198),CGPointMake(179,196),CGPointMake(182,188),CGPointMake(182,177),CGPointMake(178,167),
		CGPointMake(170,150),CGPointMake(163,138),CGPointMake(152,130),CGPointMake(143,129),CGPointMake(140,131),CGPointMake(129,136),CGPointMake(126,139) };
		
		CGPoint alphaPoints[] = { CGPointMake(200, 33),CGPointMake(198, 33),CGPointMake(195, 36),CGPointMake(195, 36),CGPointMake(191, 40),CGPointMake(191, 40),CGPointMake(187, 45),CGPointMake(185, 47),
		CGPointMake(182, 49),CGPointMake(177, 53),CGPointMake(175, 55),CGPointMake(172, 57),CGPointMake(167, 60),CGPointMake(164, 62),CGPointMake(161, 63),CGPointMake(156, 66),CGPointMake(153, 68),
		CGPointMake(151, 69),CGPointMake(145, 72),CGPointMake(140, 75),CGPointMake(140, 75),CGPointMake(134, 77),CGPointMake(128, 79),CGPointMake(126, 80),CGPointMake(122, 81),CGPointMake(116, 82),
		CGPointMake(113, 83),CGPointMake(110, 84),CGPointMake(104, 86),CGPointMake(99, 87),CGPointMake(98, 87),CGPointMake(92, 88),CGPointMake(87, 89),CGPointMake(85, 89),CGPointMake(79, 90),CGPointMake(75, 90),
		CGPointMake(73, 90),CGPointMake(67, 90),CGPointMake(64, 90),CGPointMake(61, 89),CGPointMake(55, 88),CGPointMake(49, 86),CGPointMake(45, 85),CGPointMake(43, 83),CGPointMake(40, 81),CGPointMake(38, 80),
		CGPointMake(38, 80),CGPointMake(38, 77),CGPointMake(38, 75),CGPointMake(38, 74),CGPointMake(40, 70),CGPointMake(42, 69),CGPointMake(44, 68),CGPointMake(48, 67),CGPointMake(50, 66),CGPointMake(54, 65),
		CGPointMake(55, 65),CGPointMake(59, 65),CGPointMake(60, 65),CGPointMake(65, 65),CGPointMake(66, 65),CGPointMake(72, 67),CGPointMake(78, 69),CGPointMake(84, 72),CGPointMake(85, 72),CGPointMake(90, 74),
		CGPointMake(95, 76),CGPointMake(98, 77),CGPointMake(101, 78),CGPointMake(107, 81),CGPointMake(111, 83),CGPointMake(112, 84),CGPointMake(118, 86),CGPointMake(124, 88),CGPointMake(124, 88),CGPointMake(130, 91),
		CGPointMake(135, 94),CGPointMake(138, 95),CGPointMake(141, 96),CGPointMake(147, 98),CGPointMake(152, 101),CGPointMake(153, 101),CGPointMake(158, 103),CGPointMake(164, 105),CGPointMake(170, 108),
		CGPointMake(176, 110),CGPointMake(181, 112),CGPointMake(184, 113),CGPointMake(187, 114),CGPointMake(193, 117),CGPointMake(196, 118),CGPointMake(199, 119),CGPointMake(205, 120),CGPointMake(207, 120),
		CGPointMake(211, 121),CGPointMake(215, 122),CGPointMake(217, 123),CGPointMake(223, 125),CGPointMake(227, 126),CGPointMake(229, 126),CGPointMake(229, 126)};
		CGPoint questionPoints[] = { CGPointMake(72, 81),CGPointMake(71, 81),CGPointMake(70, 81),CGPointMake(68, 81),CGPointMake(67, 80),CGPointMake(65, 78),CGPointMake(64, 77),CGPointMake(60, 73),CGPointMake(59, 72),CGPointMake(57, 70),CGPointMake(54, 66),CGPointMake(54, 66),CGPointMake(52, 61),CGPointMake(51, 60),CGPointMake(51, 57),CGPointMake(51, 55),CGPointMake(51, 52),CGPointMake(50, 48),CGPointMake(50, 47),CGPointMake(51, 43),CGPointMake(52, 42),CGPointMake(55, 39),CGPointMake(57, 37),CGPointMake(59, 36),CGPointMake(63, 33),CGPointMake(66, 31),CGPointMake(67, 31),CGPointMake(72, 29),CGPointMake(77, 27),CGPointMake(77, 27),CGPointMake(81, 26),CGPointMake(86, 25),CGPointMake(91, 24),CGPointMake(96, 24),CGPointMake(101, 23),CGPointMake(104, 22),CGPointMake(106, 22),CGPointMake(111, 22),CGPointMake(115, 22),CGPointMake(120, 22),CGPointMake(122, 22),CGPointMake(125, 22),CGPointMake(130, 23),CGPointMake(135, 23),CGPointMake(137, 23),CGPointMake(140, 24),CGPointMake(144, 27),CGPointMake(145, 27),CGPointMake(148, 30),CGPointMake(148, 30),CGPointMake(149, 32),CGPointMake(149, 34),CGPointMake(149, 39),CGPointMake(149, 44),CGPointMake(149, 44),CGPointMake(147, 49),CGPointMake(147, 50),CGPointMake(146, 54),CGPointMake(145, 55),CGPointMake(143, 58),CGPointMake(141, 60),CGPointMake(140, 62),CGPointMake(138, 65),CGPointMake(137, 66),CGPointMake(135, 70),CGPointMake(133, 72),CGPointMake(132, 74),CGPointMake(129, 78),CGPointMake(126, 82),CGPointMake(123, 85),CGPointMake(123, 86),CGPointMake(119, 89),CGPointMake(117, 92),CGPointMake(116, 93),CGPointMake(114, 98),CGPointMake(113, 100),CGPointMake(112, 102),CGPointMake(111, 107),CGPointMake(110, 109),CGPointMake(109, 111),CGPointMake(107, 116),CGPointMake(107, 117),CGPointMake(107, 121),CGPointMake(106, 126),CGPointMake(106, 131),CGPointMake(106, 134),CGPointMake(106, 136),CGPointMake(105, 141),CGPointMake(105, 143),CGPointMake(105, 146),CGPointMake(105, 150),CGPointMake(105, 151),CGPointMake(105, 155),CGPointMake(105, 158),CGPointMake(105, 160),CGPointMake(105, 160),CGPointMake(106, 164),CGPointMake(106, 165),CGPointMake(106, 166),CGPointMake(106, 167),CGPointMake(106, 168),CGPointMake(106, 169),CGPointMake(106, 170),CGPointMake(106, 170),CGPointMake(106, 171),CGPointMake(108, 171),CGPointMake(108, 173)};
		CGPoint checkPoints[]  = {CGPointMake(91,185),CGPointMake(93,185),CGPointMake(95,185),CGPointMake(97,185),CGPointMake(100,188),CGPointMake(102,189),CGPointMake(104,190),CGPointMake(106,193),CGPointMake(108,195),CGPointMake(110,198),CGPointMake(112,201),CGPointMake(114,204),CGPointMake(115,207),CGPointMake(117,210),CGPointMake(118,212),CGPointMake(120,214),CGPointMake(121,217),CGPointMake(122,219),CGPointMake(123,222),CGPointMake(124,224),CGPointMake(126,226),CGPointMake(127,229),CGPointMake(129,231),CGPointMake(130,233),CGPointMake(129,231),CGPointMake(129,228),CGPointMake(129,226),CGPointMake(129,224),CGPointMake(129,221),CGPointMake(129,218),CGPointMake(129,212),CGPointMake(129,208),CGPointMake(130,198),CGPointMake(132,189),CGPointMake(134,182),CGPointMake(137,173),CGPointMake(143,164),CGPointMake(147,157),CGPointMake(151,151),CGPointMake(155,144),CGPointMake(161,137),CGPointMake(165,131),CGPointMake(171,122),CGPointMake(174,118),CGPointMake(176,114),CGPointMake(177,112),CGPointMake(177,114),CGPointMake(175,116),CGPointMake(173,118)}; 
		NSArray *templates = [NSArray arrayWithObjects:	
							  [[[DTTemplate alloc] initWithName:@"circle" points:NSArrayFromValueArray(circlePoints, sizeof(circlePoints)/sizeof(CGPoint)) squareSize:250] autorelease],	
							  [[[DTTemplate alloc] initWithName:@"circle" points:[NSArrayFromValueArray(circlePoints, sizeof(circlePoints)/sizeof(CGPoint)) reversedArray] squareSize:250] autorelease], 
							  [[[DTTemplate alloc] initWithName:@"alpha" points:NSArrayFromValueArray(alphaPoints, sizeof(alphaPoints)/sizeof(CGPoint)) squareSize:250] autorelease],
							  [[[DTTemplate alloc] initWithName:@"alpha" points:[NSArrayFromValueArray(alphaPoints, sizeof(alphaPoints)/sizeof(CGPoint)) reversedArray] squareSize:250] autorelease], 
							  [[[DTTemplate alloc] initWithName:@"question" points:NSArrayFromValueArray(questionPoints, sizeof(questionPoints)/sizeof(CGPoint)) squareSize:250] autorelease],
							  
							  [[[DTTemplate alloc] initWithName:@"check" points:NSArrayFromValueArray(checkPoints, sizeof(checkPoints)/sizeof(CGPoint)) squareSize:250] autorelease],
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
		[points addObject:[NSValue valueWithCGPoint:point]];
	}	
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{  
	if ([touches count] > 1) {
		self.state = UIGestureRecognizerStateFailed;
		[self touchesCancelled:touches withEvent:event];
		return;
	}
	for (UITouch *touch in touches)
	{
		CGPoint point = [touch locationInView:touch.view];

		[points addObject:[NSValue valueWithCGPoint:point]];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event { 
	CGRect B = DTBoundingBox(points);
	if (B.size.width < 50 || B.size.height < 50 || [touches count] > 1) {
		self.state = UIGestureRecognizerStateFailed;
		[self touchesCancelled:touches withEvent:event];
		return;
	}
	result = [recognizer recognize:points];
	NSLog(@"DT recognized %@(%f)", result.name, result.score);
	if (result.score > 0.80){
		//[[self target] performSelector:[self action] withObject:self];
		self.state = UIGestureRecognizerStateRecognized;
	} else {
		self.state = UIGestureRecognizerStateFailed;
	}
	[super touchesEnded:touches withEvent:event];
	[points release];
	points = nil;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesCancelled:touches withEvent:event];
	self.state = UIGestureRecognizerStateFailed;
}

@end

	