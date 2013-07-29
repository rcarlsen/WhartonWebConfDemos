//
//  RCHeartRateSample.m
//  WhartonHeart
//
//  Created by Robert Carlsen on 7/28/13.
//  Copyright (c) 2013 Robert Carlsen. All rights reserved.
//

#import "RCHeartRateSample.h"
#import <Parse/PFObject+Subclass.h>

@implementation RCHeartRateSample

@dynamic pulse;
@dynamic date;

+ (NSString *)parseClassName {
    return @"HeartRateSample";
}

@end
