//
//  DTTemplate.h
//  DollarTouch
//
//  Created by Dave Dunkin on 10/3/09.
//  Copyright 2009 Dave Dunkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTHelpers.h"

@interface DTTemplate : NSObject
{
	NSString *name;
	NSArray *points;
}

@property (retain) NSString *name;
@property (retain) NSArray *points;

- (id)initWithName:(NSString *)theName points:(NSArray *)thePoints squareSize:(CGFloat)squareSize;

@end
