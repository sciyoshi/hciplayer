#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <UIKit/UIGestureRecognizer.h>
#import <UIKit/UITapGestureRecognizer.h>
#import <UIKit/UILongPressGestureRecognizer.h>
#import <UIKit/UIPanGestureRecognizer.h>

#import "DTRecognizer.h"

typedef enum {     
	UIGestureRecognizerStatePossible,           
	UIGestureRecognizerStateBegan,      
	UIGestureRecognizerStateChanged,     
	UIGestureRecognizerStateEnded,      
	UIGestureRecognizerStateCancelled,           
	UIGestureRecognizerStateFailed,           
	UIGestureRecognizerStateRecognized = UIGestureRecognizerStateEnded  
} UIGestureRecognizerState;

@interface SimplePathGestureRecognizer : UIGestureRecognizer
{
@protected
	CGPoint _start;
	BOOL _active;
	int _taps;
}

@end

@interface ElasticScaleGestureRecognizer : UIPanGestureRecognizer
{
	NSDate *_startTime;	
	CGPoint _start;
	CGPoint _location;
	CGFloat _measure;	
	CGPoint _angle;
	CGFloat _max;
	CGFloat _minDistance;
	CGFloat _maxDistance;
	CGPoint _aspect;
	CGFloat _delay;
	int _numberOfTaps;

}
@property (assign) CGPoint location;
@property (assign) CGFloat measure;
- (void) setAngle: (CGFloat) angle;

- (int) numberOfTaps;
- (void) setNumberOfTaps: (int) newValue;
- (CGFloat) delay;
- (void) setDelay: (CGFloat) newValue;
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

@interface DollarTouchGestureRecognizer : UIGestureRecognizer
{
	NSMutableArray *points;
	DTRecognizer *recognizer;
	IBOutlet id resultLabel;
	DTResult *result;
}
@property (retain) DTResult *result;

@end