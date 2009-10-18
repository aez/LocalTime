//
//  NSDate+LocalTime.m
//  Local Time
//
//  Created by Andy Zeldis on 6/8/08.
//  Copyright 2008 Andy Zeldis. All rights reserved.
//

#import "NSDate+LocalTime.h"

#import "sunriseset.h"

static const double SECONDS_PER_HOUR = (60.0*60.0);


@implementation NSDate (Solar)

// sun_rise_set(year,month,day,lon,lat,rise,set)

// TODO local_rise_set

// FIXME this class is not calculating things correctly

- (NSDate *)sunriseAtLongitude:(float)lat latitude:(float)lon;
{
	NSCalendar *gmtCalendar = [NSCalendar currentCalendar];
    [gmtCalendar setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    NSDateComponents *d = [gmtCalendar components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:self];

    double riseHour, setHour;
    sun_rise_set([d year], [d month], [d day], lon, lat, &riseHour, &setHour);

	// XXX is this working?
	[d setHour:riseHour];
	[d setMinute:fmod(riseHour*60, 60)];
	NSDate *gmtDate = [gmtCalendar dateFromComponents:d];
	return gmtDate;
}

- (NSDate *)sunsetAtLongitude:(float)lat latitude:(float)lon;
{
	NSCalendar *utcCalendar = [NSCalendar currentCalendar];
    [utcCalendar setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    NSDateComponents *d = [utcCalendar components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:self];
	
    double riseHour, setHour;
    sun_rise_set([d year], [d month], [d day], lon, lat, &riseHour, &setHour);
	
	[d setHour:setHour];
	[d setMinute:fmod(setHour*60, 60)];
	NSDate *gmtDate = [utcCalendar dateFromComponents:d];
	return gmtDate;
}

@end

// TODO NSCalendar +gmtCalendar


@implementation NSDate (LocalTime)

- (float)dayLengthForLongitude:(float)lon latitude:(float)lat;
{
    NSCalendar *gmtCalendar = [NSCalendar currentCalendar];
    [gmtCalendar setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    NSDateComponents *d = [gmtCalendar components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:self];
	return day_length([d year], [d month], [d day], lon, lat);
}

- (float)dayScaleForLongitude:(float)lon latitude:(float)lat;
{
    NSCalendar *gmtCalendar = [NSCalendar currentCalendar];
    [gmtCalendar setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
	
    NSDateComponents *d = [gmtCalendar components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:self];
	
	double dayLength = day_length([d year], [d month], [d day], lon, lat);
    // dayScale is > 1 in summer - this is "how many UTC seconds in one local second"
	float dayScale = 12.0 / dayLength;
	
	return dayScale;
}

- (NSDate *)localTimeForLongitude:(float)lon latitude:(float)lat;
{
    NSCalendar *gmtCalendar = [NSCalendar currentCalendar];
    [gmtCalendar setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];

    NSDateComponents *d = [gmtCalendar components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:self];

    // sunriseset works in units of hours in universal time
    double riseHour, setHour;
    sun_rise_set([d year], [d month], [d day], lon, lat, &riseHour, &setHour);
	
	double dayLength = day_length([d year], [d month], [d day], lon, lat);
    // dayScale is > 1 in summer - this is "how many UTC seconds in one local second"
	float dayScale = 12.0 / dayLength;
	float nightScale = 1.0 / dayScale;

    NSTimeInterval localRise = (riseHour * SECONDS_PER_HOUR) + [[NSTimeZone localTimeZone] secondsFromGMTForDate:self];
    NSTimeInterval localSet = (setHour * SECONDS_PER_HOUR) + [[NSTimeZone localTimeZone] secondsFromGMTForDate:self];
    //NSLog(@"rise: %2.2f set:%2.2f day length: %02.2fh stretch (day/night): %.3f/%.3f", localRise/SECONDS_PER_HOUR, localSet/SECONDS_PER_HOUR, dayLength, dayScale, nightScale);
	
    NSTimeInterval daySeconds = [[NSCalendar currentCalendar] ordinalityOfUnit:NSSecondCalendarUnit inUnit:NSDayCalendarUnit forDate:self];
    //daySeconds = 12 * SECONDS_PER_HOUR;
	double zeldisSeconds;
    if(daySeconds < localRise) {
		// scaled time since midnight
		zeldisSeconds = daySeconds * nightScale;
    } else if(daySeconds < localSet) {
		// 6:00 AM plus scaled time since sunrise
		zeldisSeconds = 6*SECONDS_PER_HOUR + (daySeconds - localRise) * dayScale;
    } else {
        // 18:00 (6PM) plus scaled time since sunset
		zeldisSeconds = 18*SECONDS_PER_HOUR + (daySeconds - localSet) * nightScale;
    }
    
	NSDateComponents *zeldisDateComponents = [d copy];
    
    [zeldisDateComponents setSecond:zeldisSeconds];
    NSDate *zeldisDate = [[NSCalendar currentCalendar] dateFromComponents:zeldisDateComponents];
    [zeldisDateComponents release];
    //NSLog(@"%f => %f", daySeconds/SECONDS_PER_HOUR, zeldisSeconds/SECONDS_PER_HOUR);
    //NSLog(@"%@ => %@", self, zeldisDate);
    return [NSDate dateWithTimeIntervalSinceReferenceDate:[zeldisDate timeIntervalSinceReferenceDate]];
}

@end
