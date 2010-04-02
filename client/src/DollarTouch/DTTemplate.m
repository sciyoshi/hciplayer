//
//  DTTemplate.m
//  DollarTouch
//
//  Created by Dave Dunkin on 10/3/09.
//  Copyright 2009 Dave Dunkin. All rights reserved.
//

#import "DTTemplate.h"

@implementation DTTemplate

@synthesize name;
@synthesize points;

- (id)initWithName:(NSString *)theName points:(NSArray *)thePoints squareSize:(CGFloat)squareSize
{
	if (self = [super init])
	{
		self.name = theName;
		NSArray *pts = DTResample(thePoints, DT_NUM_POINTS);
		CGFloat radians = DTIndicativeAngle(pts);
		pts = DTRotateBy(pts, -radians);
		pts = DTScaleTo(pts, squareSize);
		pts = DTTranslateTo(pts, CGPointZero);
		self.points = pts;
	}
	return self;
}

- (void)dealloc
{
    self.name = nil;
    [super dealloc];
}

@end
