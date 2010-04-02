//
//  DTResult.h
//  DollarTouch
//
//  Created by Dave Dunkin on 10/4/09.
//  Copyright 2009 Dave Dunkin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DTResult : NSObject
{
	NSString *name;
	float score;
}

@property (copy) NSString *name;
@property float score;

- (id)initWithName:(NSString *)theName score:(float)theScore;

@end
