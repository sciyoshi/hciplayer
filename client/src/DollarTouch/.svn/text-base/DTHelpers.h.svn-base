//
//  DTHelpers.h
//  DollarTouch
//
//  Created by Dave Dunkin on 10/3/09.
//  Copyright 2009 Dave Dunkin. All rights reserved.
//
//  An implementation of the $1 Unistroke Recognizer by Jacob O. Wobbrock, Andrew D. Wilson and Yang Li.
//  http://depts.washington.edu/aimgroup/proj/dollar/dollar.pdf
//

#include <stdlib.h>
#include <math.h>
#include <CoreGraphics/CGGeometry.h>

#define DT_NUM_POINTS 64

NSArray *DTResample(NSArray *thePoints, int n);
CGFloat DTIndicativeAngle(NSArray *points);
NSArray *DTRotateBy(NSArray *points, CGFloat radians);
NSArray *DTScaleTo(NSArray *points, CGFloat size);
NSArray *DTTranslateTo(NSArray *points, CGPoint pt);
CGFloat DTDistanceAtBestAngle(NSArray *points1, NSArray *points2, CGFloat a, CGFloat b, CGFloat threshold);
CGFloat DTDistanceAtAngle(NSArray *points1, NSArray *points2, CGFloat radians);
CGPoint DTCentroid(NSArray *points);
CGRect DTBoundingBox(NSArray *points);
CGFloat DTPathDistance(NSArray *pts1, NSArray *pts2);
CGFloat DTPathLength(NSArray *points);
CGFloat DTDistance(CGPoint p1, CGPoint p2);
CGFloat DTDeg2Rad(CGFloat d);
CGFloat DTRad2Deg(CGFloat r);
