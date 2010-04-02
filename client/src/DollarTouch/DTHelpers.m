//
//  DTHelpers.m
//  DollarTouch
//
//  Created by Dave Dunkin on 10/3/09.
//  Copyright 2009 Dave Dunkin. All rights reserved.
//
//  An implementation of the $1 Unistroke Recognizer by Jacob O. Wobbrock, Andrew D. Wilson and Yang Li.
//  http://depts.washington.edu/aimgroup/proj/dollar/dollar.pdf
//

#include "DTHelpers.h"
#include <UIKit/UIGeometry.h>

#if CGFLOAT_IS_DOUBLE
#define CGSQRT sqrt
#define CGATAN2 atan2
#define CGFMIN fmin
#else
#define CGSQRT sqrtf
#define CGATAN2 atan2f
#define CGFMIN fminf
#endif

#define PHI 0.618033989 /* 0.5 * (-1.0 + sqrtf(5.0)); // Golden Ratio */

NSArray *DTResample(NSArray *thePoints, int n)
{
	CGFloat I = DTPathLength(thePoints) / (n - 1); // interval length
	CGFloat D = 0.0;
	
	NSMutableArray *points = [NSMutableArray arrayWithCapacity:[thePoints count]];
	[points addObjectsFromArray:thePoints];

	NSMutableArray *newPoints = [NSMutableArray arrayWithCapacity:n];
	[newPoints addObject:[[points objectAtIndex:0] copy]];

	for (int i = 1; i < [points count]; i++)
	{
		CGPoint pt = [[points objectAtIndex:i] CGPointValue];
		CGPoint prevPt = [[points objectAtIndex:i - 1] CGPointValue];
		CGFloat d = DTDistance(prevPt, pt);
		if ((D + d) >= I)
		{
			CGFloat qx = prevPt.x + ((I - D) / d) * (pt.x - prevPt.x);
			CGFloat qy = prevPt.y + ((I - D) / d) * (pt.y - prevPt.y);
			CGPoint q = CGPointMake(qx, qy);
			NSValue *qVal = [NSValue valueWithCGPoint:q];
			[newPoints addObject:qVal]; // append new point 'q'
			[points insertObject:qVal atIndex: i]; // insert 'q' at position i in points s.t. 'q' will be the next i
			D = 0.0;
		}
		else D += d;
	}
	// somtimes we fall a rounding-error short of adding the last point, so add it if so
	if ([newPoints count] == n - 1)
	{
		CGPoint prevPt = [[points lastObject] CGPointValue];
		[newPoints addObject:[NSValue valueWithCGPoint:CGPointMake(prevPt.x, prevPt.y)]];
	}
	
	return newPoints;
}

CGFloat DTIndicativeAngle(NSArray *points)
{
	CGPoint c = DTCentroid(points);
	CGPoint pt = [[points lastObject] CGPointValue];
	return CGATAN2(c.y - pt.y, c.x - pt.x);
}

NSArray *DTRotateBy(NSArray *points, CGFloat radians)
{
	CGPoint c = DTCentroid(points);
	CGFloat cos = cosf(radians);
	CGFloat sin = sinf(radians);
	
	NSMutableArray *newPoints = [NSMutableArray arrayWithCapacity:[points count]];
	for (int i = 0; i < [points count]; i++)
	{
		CGPoint pt = [[points objectAtIndex:i] CGPointValue];
		CGFloat qx = (pt.x - c.x) * cos - (pt.y - c.y) * sin + c.x;
		CGFloat qy = (pt.x - c.x) * sin + (pt.y - c.y) * cos + c.y;
		[newPoints addObject:[NSValue valueWithCGPoint: CGPointMake(qx, qy)]];
	}
	
	return newPoints;
}

NSArray *DTScaleTo(NSArray *points, CGFloat size) // non-uniform scale; assumes 2D gestures (i.e., no lines)
{
	CGRect B = DTBoundingBox(points);
	NSMutableArray *newPoints = [NSMutableArray arrayWithCapacity:[points count]];
	for (int i = 0; i < [points count]; i++)
	{
		CGPoint pt = [[points objectAtIndex:i] CGPointValue];
		CGFloat qx = pt.x * (size / B.size.width);
		CGFloat qy = pt.y * (size / B.size.height);
		[newPoints addObject:[NSValue valueWithCGPoint: CGPointMake(qx, qy)]];
	}
	return newPoints;
}

NSArray *DTTranslateTo(NSArray *points, CGPoint pt) // translates points' centroid
{
	CGPoint c = DTCentroid(points);
	NSMutableArray *newPoints = [NSMutableArray arrayWithCapacity:[points count]];
	for (int i = 0; i < [points count]; i++)
	{
		CGPoint pt1 = [[points objectAtIndex:i] CGPointValue];
		CGFloat qx = pt1.x + pt.x - c.x;
		CGFloat qy = pt1.y + pt.y - c.y;
		[newPoints addObject:[NSValue valueWithCGPoint: CGPointMake(qx, qy)]];
	}
	return newPoints;
}

CGFloat DTDistanceAtBestAngle(NSArray *points1, NSArray *points2, CGFloat a, CGFloat b, CGFloat threshold)
{
	CGFloat x1 = PHI * a + (1.0 - PHI) * b;
	CGFloat f1 = DTDistanceAtAngle(points1, points2, x1);
	CGFloat x2 = (1.0 - PHI) * a + PHI * b;
	CGFloat f2 = DTDistanceAtAngle(points1, points2, x2);
	while (fabsf(b - a) > threshold)
	{
		if (f1 < f2)
		{
			b = x2;
			x2 = x1;
			f2 = f1;
			x1 = PHI * a + (1.0 - PHI) * b;
			f1 = DTDistanceAtAngle(points1, points2, x1);
		}
		else
		{
			a = x1;
			x1 = x2;
			f1 = f2;
			x2 = (1.0 - PHI) * a + PHI * b;
			f2 = DTDistanceAtAngle(points1, points2, x2);
		}
	}
	return CGFMIN(f1, f2);
}

CGFloat DTDistanceAtAngle(NSArray *points1, NSArray *points2, CGFloat radians)
{
	// TODO: check for failure
	NSArray *newPoints = DTRotateBy(points1, radians);
	CGFloat d = DTPathDistance(newPoints, points2);
	return d;
}	

CGPoint DTCentroid(NSArray *points)
{
	CGFloat x = 0.0, y = 0.0;
	for (int i = 0; i < [points count]; i++)
	{
		CGPoint pt = [[points objectAtIndex:i] CGPointValue];
		x += pt.x;
		y += pt.y;
	}
	x /= [points count];
	y /= [points count];
	return CGPointMake(x, y);
}

CGRect DTBoundingBox(NSArray *points)
{
	CGFloat minX = CGFLOAT_MAX, maxX = CGFLOAT_MIN, minY = CGFLOAT_MAX, maxY = CGFLOAT_MIN;
	for (int i = 0; i < [points count]; i++)
	{
		CGPoint pt = [[points objectAtIndex:i] CGPointValue];
		if (pt.x < minX)
			minX = pt.x;
		if (pt.x > maxX)
			maxX = pt.x;
		if (pt.y < minY)
			minY = pt.y;
		if (pt.y > maxY)
			maxY = pt.y;
	}
	return CGRectMake(minX, minY, maxX - minX, maxY - minY);
}

CGFloat DTPathDistance(NSArray *pts1, NSArray *pts2)
{
	CGFloat d = 0.0;
	for (int i = 0; i < [pts1 count]; i++) // assumes pts1.length == pts2.length
		d += DTDistance([[pts1 objectAtIndex:i] CGPointValue], [[pts2 objectAtIndex:i] CGPointValue]);
	return d / [pts1 count];
}

CGFloat DTPathLength(NSArray *points)
{
	CGFloat d = 0.0;
	for (int i = 1; i < [points count]; i++)
		d += DTDistance([[points objectAtIndex:i - 1] CGPointValue], [[points objectAtIndex:i] CGPointValue]);
	return d;
}

CGFloat DTDistance(CGPoint p1, CGPoint p2)
{
	CGFloat dx = p2.x - p1.x;
	CGFloat dy = p2.y - p1.y;
	return CGSQRT(dx * dx + dy * dy);
}

CGFloat DTDeg2Rad(CGFloat d) { return (d * M_PI / 180.0); }
CGFloat DTRad2Deg(CGFloat r) { return (r * 180.0 / M_PI); }
