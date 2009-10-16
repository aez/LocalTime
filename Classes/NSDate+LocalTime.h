//
//  NSDate+LocalTime.h
//  Local Time
//
//  Created by Andy Zeldis on 6/8/08.
//  Copyright 2008 Andy Zeldis. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Solar)

- (NSDate *)sunriseAtLongitude:(float)latitude latitude:(float)longitude;
- (NSDate *)sunsetAtLongitude:(float)latitude latitude:(float)longitude;

@end

@interface NSDate (LocalTime)

- (float)dayScaleForLongitude:(float)lon latitude:(float)lat;
- (float)dayLengthForLongitude:(float)lon latitude:(float)lat;
- (NSDate *)localTimeForLongitude:(float)lon latitude:(float)lat;

@end
