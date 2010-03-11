//
//  LocalTimeTest.m
//  Local Time
//
//  Created by Andy Zeldis on 10/14/09.
//  Copyright 2009 Andy Zeldis. All rights reserved.
//

#import "LocalTimeTest.h"

#import "NSDate+LocalTime.h"

@implementation LocalTimeTest

- (void)setUp;
{
	// NYC
	lat = 40.726499;
	lon = -74.00628;
	
	calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
}

- (void)tearDown;
{
	[calendar release];
}

- (void)testTimeFuzz;
{
	NSDate *now = [NSDate date];
	
	const NSTimeInterval step = 13;
	NSTimeInterval t = [now timeIntervalSinceReferenceDate];
	NSTimeInterval tPrev = t - step*0.5;
	NSTimeInterval end = t + (1*60*60*25);
	while(t < end) {
		now = [NSDate dateWithTimeIntervalSinceReferenceDate:t];
		
		NSDate *localNow = [now localTimeForLongitude:lon latitude:lat];
		
		NSDate *rise = [now sunriseAtLongitude:lat latitude:lon];
		NSDate *set = [now sunsetAtLongitude:lat latitude:lon];
		
		NSDate *localRise = [rise localTimeForLongitude:lon latitude:lat];
		NSDate *localSet = [set localTimeForLongitude:lon latitude:lat];
		
		STAssertTrue(t > tPrev, @"time is going backwards");
		STAssertTrue(t < (tPrev + step*2), @"time is going too fast");
		
		tPrev = t;
		t += step;
	}
}

- (void)testSunriseSunset;
{
	// TODO Saff squeeze - shouldn't sunrise and sunset be at 6?
	
	NSDate *now = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
	
	NSDate *rise = [now sunriseAtLongitude:lat latitude:lon];
	NSDate *set = [now sunsetAtLongitude:lat latitude:lon];
	
	NSDate *localRise = [rise localTimeForLongitude:lon latitude:lat];
	NSDate *localSet = [set localTimeForLongitude:lon latitude:lat];
	
	NSLog(@"rise: %@", rise);
	NSLog(@"set: %@", set);
	NSLog(@"local rise: %@", localRise);
	NSLog(@"local set: %@", localSet);
	
	unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *localRiseComponents = [calendar components:unitFlags fromDate:localRise];
	NSDateComponents *localSetComponents = [calendar components:unitFlags fromDate:localSet];
	
	STAssertEquals([localRiseComponents hour], 6, @"Sunrise is at 6 am - got %@", localRise);
	STAssertEquals([localRiseComponents minute], 0, @"Sunrise is at 6:00 sharp - got %@", localRise);
	STAssertEquals([localSetComponents hour], 18, @"Sunset is at 6 pm - got %@", localSet);
	STAssertEquals([localSetComponents minute], 0, @"Sunset is at 18:00 sharp - got %@", localSet);
}

@end
