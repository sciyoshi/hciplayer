//
//  DTRecognizer.h
//  DollarTouch
//
//  Created by Dave Dunkin on 10/3/09.
//  Copyright 2009 Dave Dunkin. All rights reserved.
//
//  An implementation of the $1 Unistroke Recognizer by Jacob O. Wobbrock, Andrew D. Wilson and Yang Li.
//  http://depts.washington.edu/aimgroup/proj/dollar/dollar.pdf
//

#import <Foundation/Foundation.h>
#import <UIKit/UIGeometry.h>
#import "DTTemplate.h"
#import "DTResult.h"
#import "DTHelpers.h"

@interface DTRecognizer : NSObject
{
	CGFloat squareSize;
	NSArray *templates;
	CGFloat diagonal;
	CGFloat halfDiagonal;
	CGFloat angleRange;
	CGFloat anglePrecision;	
}

@property (retain) NSArray *templates;

- (id)initWithSquareSize:(CGFloat)theSquareSize templates:(NSArray *)theTemplates;
- (DTResult *)recognize:(NSArray *)points;

@end
