#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "UIKit/UIGestureRecognizer.h"

@interface SimplePathGestureRecognizer : UIGestureRecognizer
{
@protected
	CGPoint _start;
	BOOL _active;
	int _taps;
}

@end

@interface SwipeGestureRecognizer : SimplePathGestureRecognizer
{
	BOOL _onRelease;
	NSDate *_startTime;
	CGFloat _max;
	CGPoint _location;
	CGPoint _angle;
	CGFloat _minDistance;
	CGFloat _maxDistance;
	CGPoint _aspect;
}

- (void) setAngle: (CGFloat) angle;

@end
