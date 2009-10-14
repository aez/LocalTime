/*
 *  scratch_main.c
 *  Local Time
 *
 *  Created by Andy Zeldis on 4/12/09.
 *  Copyright 2009 Andy Zeldis. All rights reserved.
 *
 */

#import <stdlib.h>
#import <stdio.h>
#import <time.h>
#import "sunriseset.h"
#import "NSDate+LocalTime.h"

/* A small test program */


static const double SECONDS_PER_HOUR = (60.0*60.0);

// New York
static const float lon = -74.00628;
static const float lat = 40.726499;

char *h2s(double h)
{
	char *s = (char *)malloc(6);
	sprintf(s, "%2d:%2d", (int)h,  (int)( (h*60 + 0.5) ) % 60 );
	return s;
}


int test_original()
{
	int year,month,day;
	double lon, lat;
	double daylen, civlen, nautlen, astrlen;
	double rise, set, civ_start, civ_end, naut_start, naut_end,
	astr_start, astr_end;
	int    rs, civ, naut, astr;
	
    //printf( "Longitude (+ is east) and latitude (+ is north) : " );
    //scanf( "%lf %lf", &lon, &lat );
	// New York
	lon = -74.00628;
	lat = 40.726499;
	
	time_t t = time(NULL);
	struct tm *tm;
	tm = gmtime(&t);
	localtime(&t);
	
	year = 1900 + tm->tm_year;
	month = 1 + tm->tm_mon;
	day = tm->tm_mday;
	
	tm = localtime(&t);
	printf("gmtoff: %ld\n", tm->tm_gmtoff);
	double gmtoff = tm->tm_gmtoff / SECONDS_PER_HOUR;
	
	
	/*
	 New York, New York
	 12:22pm DST
	 Sun 4/12/2009
	 Sunrise: 6:22am
	 Sunset: 7:31pm
	 */
	
	// sunriseset works in units of hours in universal time
    double riseHour, setHour;
    sun_rise_set(year, month, day, lon, lat, &riseHour, &setHour);
	
	daylen  = day_length(year,month,day,lon,lat);
	civlen  = day_civil_twilight_length(year,month,day,lon,lat);
	nautlen = day_nautical_twilight_length(year,month,day,lon,lat);
	astrlen = day_astronomical_twilight_length(year,month,day,lon,lat);
	
	printf( "Day length:                 %5.2f hours\n", daylen );
	printf( "With civil twilight         %5.2f hours\n", civlen );
	printf( "With nautical twilight      %5.2f hours\n", nautlen );
	printf( "With astronomical twilight  %5.2f hours\n", astrlen );
	printf( "Length of twilight: civil   %5.2f hours\n", (civlen-daylen)/2.0);
	printf( "                  nautical  %5.2f hours\n", (nautlen-daylen)/2.0);
	printf( "              astronomical  %5.2f hours\n", (astrlen-daylen)/2.0);
	
	rs   = sun_rise_set         ( year, month, day, lon, lat, &rise, &set );
	civ  = civil_twilight       ( year, month, day, lon, lat, &civ_start, &civ_end );
	naut = nautical_twilight    ( year, month, day, lon, lat, &naut_start, &naut_end );
	astr = astronomical_twilight( year, month, day, lon, lat, &astr_start, &astr_end );
	
	rise += gmtoff;
	set += gmtoff;
	naut += gmtoff;
	astr += gmtoff;
	
	printf( "Sun at south %5.2fh UT\n", (rise+set)/2.0 );
	
	switch( rs )
	{
		case 0:
			//printf( "Sun rises %5.2fh UT, sets %5.2fh UT\n", rise, set );
			printf( "Sun rises %s, sets %s\n", h2s(rise), h2s(set) );
			break;
		case +1:
			printf( "Sun above horizon\n" );
			break;
		case -1:
			printf( "Sun below horizon\n" );
			break;
	}
	
	switch( civ )
	{
		case 0:
			printf( "Civil twilight starts %5.2fh, ends %5.2fh UT\n", civ_start, civ_end );
			break;
		case +1:
			printf( "Never darker than civil twilight\n" );
			break;
		case -1:
			printf( "Never as bright as civil twilight\n" );
			break;
	}
	
	switch( naut )
	{
		case 0:
			printf( "Nautical twilight starts %5.2fh, ends %5.2fh UT\n", naut_start, naut_end );
			break;
		case +1:
			printf( "Never darker than nautical twilight\n" );
			break;
		case -1:
			printf( "Never as bright as nautical twilight\n" );
			break;
	}
	
	switch( astr )
	{
		case 0:
			printf( "Astronomical twilight starts %5.2fh, ends %5.2fh UT\n", astr_start, astr_end );
			break;
		case +1:
			printf( "Never darker than astronomical twilight\n" );
			break;
		case -1:
			printf( "Never as bright as astronomical twilight\n" );
			break;
	}
	
	
	return 0;
}

int test_fullday()
{
	NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
	[df setDateStyle:NSDateFormatterShortStyle];
	[df setTimeStyle:NSDateFormatterShortStyle];
	
	NSCalendar *cal = [NSCalendar currentCalendar];
	NSDate *now = [NSDate date];
	NSDateComponents *comps = [[[NSDateComponents alloc] init] autorelease];
	comps = [cal components:NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit | NSWeekCalendarUnit | NSWeekdayCalendarUnit | NSWeekdayOrdinalCalendarUnit fromDate:now];
	[comps setMinute:0];
	for(int i=0; i<=24; ++i) {
		[comps setHour:i];
		NSDate *date = [cal dateFromComponents:comps];
		printf("%20s \t %20s\n", 
			  [[df stringFromDate:date] UTF8String],  
			  [[df stringFromDate:[date localTimeForLongitude:lon latitude:lat]] UTF8String]);
	}
	return 0;
}

int test_sunriset()
{
	NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
	[df setDateStyle:NSDateFormatterShortStyle];
	[df setTimeStyle:NSDateFormatterShortStyle];
	
	NSDate *now = [NSDate date];
	now = [NSDate dateWithNaturalLanguageString:@"16 sep 2009 5:00 am"];
	
	NSDate *rise = [now sunriseAtLatitude:lat longitude:lon];
	NSDate *set = [now sunsetAtLatitude:lat longitude:lon];
	printf("rise: %20s \t %20s\n",
		   [[df stringFromDate:rise] UTF8String],  
		   [[df stringFromDate:[rise localTimeForLongitude:lon latitude:lat]] UTF8String]);
	printf("set:  %20s \t %20s\n",
		   [[df stringFromDate:set] UTF8String],  
		   [[df stringFromDate:[set localTimeForLongitude:lon latitude:lat]] UTF8String]);
	return 0;
}

int main(void)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	//test_original();
	printf("\n");
//	test_fullday();
	test_sunriset();
	[pool release];
	return 0;
}

