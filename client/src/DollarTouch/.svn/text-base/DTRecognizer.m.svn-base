//
//  DTRecognizer.m
//  DollarTouch
//
//  Created by Dave Dunkin on 10/3/09.
//  Copyright 2009 Dave Dunkin. All rights reserved.
//
//  An implementation of the $1 Unistroke Recognizer by Jacob O. Wobbrock, Andrew D. Wilson and Yang Li.
//  http://depts.washington.edu/aimgroup/proj/dollar/dollar.pdf
//

#import "DTRecognizer.h"

@implementation DTRecognizer

@synthesize templates;

- (id)initWithSquareSize:(CGFloat)theSquareSize templates:(NSArray *)theTemplates
{
    if (self = [super init])
	{
		squareSize = theSquareSize;
		self.templates = theTemplates;
		diagonal = sqrtf(squareSize * squareSize + squareSize * squareSize);
		halfDiagonal = 0.5 * diagonal;
		angleRange = DTDeg2Rad(45.0);
		anglePrecision = DTDeg2Rad(2.0);
    }
    return self;
}

- (DTResult *)recognize:(NSArray *)points
{
	NSArray *points2 = DTResample(points, DT_NUM_POINTS);
	CGFloat radians = DTIndicativeAngle(points2);
	points2 = DTRotateBy(points2, -radians);
	points2 = DTScaleTo(points2, squareSize);
	points2 = DTTranslateTo(points2, CGPointZero);
		
	CGFloat b = CGFLOAT_MAX;
	int t = 0;
	for (int i = 0; i < [templates count]; i++)
	{
		DTTemplate *tpl = [templates objectAtIndex:i];
		CGFloat d = DTDistanceAtBestAngle(points2, tpl.points, -angleRange, +angleRange, anglePrecision);
		if (d < b)
		{
			b = d;
			t = i;
		}
	}
	float score = 1.0 - (b / halfDiagonal);
	return [[[DTResult alloc] initWithName:[[templates objectAtIndex:t] name] score:score] autorelease];
}

- (void)dealloc
{
    self.templates = nil;
    [super dealloc];
}

@end
