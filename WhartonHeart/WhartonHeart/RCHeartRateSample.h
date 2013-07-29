//
//  RCHeartRateSample.h
//  WhartonHeart
//
//  Created by Robert Carlsen on 7/28/13.
//  Copyright (c) 2013 Robert Carlsen. All rights reserved.
//

#import <Parse/Parse.h>

@interface RCHeartRateSample : PFObject
<PFSubclassing>
+ (NSString *)parseClassName;

@property(nonatomic) NSInteger  pulse;
@property(nonatomic) NSDate     *date;

@end
