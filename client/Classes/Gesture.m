#import "Gesture.h"

#import <math.h>

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

@implementation SwipeGestureRecognizer

- (id) init
{
	if (self = [super init]) {
		_angle.x = 1.0;
		_angle.y = 0.0;
		_minDistance = -10;
		_maxDistance = 70;
		_aspect.x = 0.8;
		_aspect.y = 1;
		_max = 0;
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

	[_startTime autorelease];
	_startTime = [NSDate date];
	_max = 0;
	_location.x = 0;
	_location.y = 0;
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
	}
}

- (void) touchesEnded: (NSSet *) touches withEvent: (UIEvent *) event
{
	CGPoint location = [[touches anyObject] locationInView:self.view];

	location.x -= _start.x;
	location.y -= _start.y;

	_location.x = location.x * _angle.x + location.y * _angle.y;

	if (_location.x > _maxDistance) {
		CGFloat ratio = 1 - [_startTime timeIntervalSinceNow];

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