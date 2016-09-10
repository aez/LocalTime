//
//  MainViewController.m
//  Local Time
//
//  Created by Andy Zeldis on 6/8/08.
//  Copyright Andy Zeldis 2008. All rights reserved.
//

#import "MainViewController.h"
#import "NSDate+LocalTime.h"
#import <CoreLocation/CoreLocation.h>


#include <time.h>
#include "sunriseset.h"

// TODO screens for acquiring location, error

// TODO figure out how to deal with timely awake from sleep

@implementation MainViewController

- (void)viewDidLoad;
{
    [super viewDidLoad];
    
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	double savedLatitude = [defaults doubleForKey:@"latitude"];
	double savedLongitude = [defaults doubleForKey:@"longitude"];
	if(savedLatitude && savedLongitude) {
		lastLocation = [[CLLocation alloc] initWithLatitude:savedLatitude longitude:savedLongitude];
	}
	
	lastPlaceName = [defaults stringForKey:@"lastPlaceName"];
	
    NSLog(@"Location services enabled? %d", [CLLocationManager locationServicesEnabled]);
    if(![CLLocationManager locationServicesEnabled]) {
        UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled" message:@"You currently have all location services for this device disabled. If you proceed, you will be showing past informations. To enable, Settings->Location->location services->on" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:@"Continue",nil];
        [servicesDisabledAlert show];
        [servicesDisabledAlert setDelegate:self];
    }
	locationManager = [[CLLocationManager alloc] init];
	locationManager.delegate = self;
    locationManager.activityType = CLActivityTypeOther;
    locationManager.distanceFilter = 1000;
    locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    [locationManager requestWhenInUseAuthorization];
    [locationManager startUpdatingLocation];
    [locationManager startMonitoringSignificantLocationChanges];
	
	[self.view addSubview:infoView];
	infoView.frame = CGRectMake(0, self.view.frame.size.height - 50, infoView.frame.size.width, infoView.frame.size.height);
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	
	// TODO update geocoded location, but not as often as updating time
	geocoder = [[AZGeocoder alloc] init];
	geocoder.delegate = self;
	[geocoder findNameForLocation:lastLocation];

    ticker = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(tick:) userInfo:nil repeats:YES];
    [self updateDisplay];
}

- (void)deviceOrientationDidChange:(NSNotification *)notification;
{
	const float landscapeScale = 1.5;
	const int landscapeOffset = 120;
	
	UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
	
	if(UIDeviceOrientationIsPortrait(orientation)) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
	} else if(UIDeviceOrientationIsLandscape(orientation)) {
		[self hideInfo];
		[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
	}
	
	CGAffineTransform t = CGAffineTransformIdentity;
	switch(orientation) {
		case UIDeviceOrientationPortrait:
			[[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:YES];
			break;
		case UIDeviceOrientationPortraitUpsideDown:
			[[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortraitUpsideDown animated:YES];
			t = CGAffineTransformMakeScale(-1, -1);
			break;
		case UIDeviceOrientationLandscapeLeft:
			t = CGAffineTransformMakeRotation(M_PI/2);
			t = CGAffineTransformScale(t, landscapeScale, landscapeScale);
			t = CGAffineTransformTranslate(t, 0, landscapeOffset);
			break;
		case UIDeviceOrientationLandscapeRight:
			t = CGAffineTransformMakeRotation(-M_PI/2);
			t = CGAffineTransformScale(t, landscapeScale, landscapeScale);
			t = CGAffineTransformTranslate(t, 0, landscapeOffset);
			break;
		default:
			// don't rotate, just stop now
			return;
	}
		
	[UIView beginAnimations:@"view_rotation" context:NULL];
	[UIView setAnimationDuration:(float)69/72];
	self.view.transform = t;
	[UIView commitAnimations];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
{
	// We're handling rotation manually
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations;
{
    NSLog(@"didUpdateLocations");
    
    [lastLocation release];
    lastLocation = [[locations lastObject] copy];
    [geocoder findNameForLocation:lastLocation];

    [self updateDisplay];
}


- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation;
{
    NSLog(@"got location %f %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
    // TODO check again after a while in case they're on the move
    [locationManager stopUpdatingLocation];
	
#ifdef DEBUG
	// XXX New York
	const double lon = -74.00628;
	const double lat = 40.726499;
	newLocation = [[[CLLocation alloc] initWithLatitude:lat longitude:lon] autorelease];
#endif
	
	[lastLocation release];
	lastLocation = [newLocation copy];
	
	[[NSUserDefaults standardUserDefaults] setDouble:lastLocation.coordinate.latitude forKey:@"latitude"];
	[[NSUserDefaults standardUserDefaults] setDouble:lastLocation.coordinate.longitude forKey:@"longitude"];
	
	[geocoder findNameForLocation:lastLocation];
	[self updateDisplay];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;
{
    NSLog(@"location failed: %@", error);
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Couldn't determine location" message:[error description] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//    [alert show];
}

- (void)geocoder:(AZGeocoder *)geocoder didFindName:(NSString *)name forLocation:(CLLocation *)location;
{
	[lastPlaceName release];
	lastPlaceName = [name copy];
	
	[[NSUserDefaults standardUserDefaults] setObject:lastPlaceName forKey:@"lastPlaceName"];
	
	[self updateDisplay];
}

- (void)geocoder:(AZGeocoder *)geocoder didFailWithError:(NSError *)error;
{
	// TODO implement
}

- (void)tick:(NSTimer *)timer;
{
	[self updateDisplay];
}

static const double SECONDS_PER_HOUR = (60.0*60.0);

- (void)updateDisplay;
{
    NSLog(@"updateDisplay...");
    
	if(lastLocation) {
		const double lon = lastLocation.coordinate.longitude;
		const double lat = lastLocation.coordinate.latitude;
		
		// TODO break this into testable units
		
		int year,month,day;
		double daylen, civlen, nautlen, astrlen;
		double rise, set, civ_start, civ_end, naut_start, naut_end,
		astr_start, astr_end;
		int    rs, civ, naut, astr;
		
		time_t t = time(NULL);
		struct tm *tm = localtime(&t);
		
		year = 1900 + tm->tm_year;
		month = 1 + tm->tm_mon;
		day = tm->tm_mday;
		
		double gmtoff = tm->tm_gmtoff / SECONDS_PER_HOUR;
		
		daylen  = day_length(year,month,day,lon,lat);
		civlen  = day_civil_twilight_length(year,month,day,lon,lat);
		nautlen = day_nautical_twilight_length(year,month,day,lon,lat);
		astrlen = day_astronomical_twilight_length(year,month,day,lon,lat);
		
		rs   = sun_rise_set         ( year, month, day, lon, lat, &rise, &set );
		civ  = civil_twilight       ( year, month, day, lon, lat, &civ_start, &civ_end );
		naut = nautical_twilight    ( year, month, day, lon, lat, &naut_start, &naut_end );
		astr = astronomical_twilight( year, month, day, lon, lat, &astr_start, &astr_end );
		
		rise += gmtoff;
		set += gmtoff;
		naut += gmtoff;
		astr += gmtoff;
		
		//double noon = (rise + set) / 2.0;
		//printf("noon: %f\n", noon);
		
		// TODO handle sun above/below horizon in UI
		switch( rs )
		{
			case 0:
				//printf( "Sun rises %5.2fh UT, sets %5.2fh UT\n", rise, set );
				//printf( "Sun rises %s, sets %s\n", h2s(rise), h2s(set) );
				break;
			case +1:
				//printf( "Sun above horizon\n" );
				break;
			case -1:
				//printf( "Sun below horizon\n" );
				break;
		}
		
		// FIXME don't crash on zero-length day
		double dayScale = 12.0 / daylen;
		double nightScale = daylen / 12.0;
		
		double hour = tm->tm_hour + (tm->tm_min / 60.0) + (tm->tm_sec / 3600.0);
		double solarHour;
		
		if(hour < rise) {
			// scaled time since sunset
			// TODO should be previous set
			solarHour = -6 + (hour + 24 - set) * nightScale;
		} else if(hour < set) {
			// 6:00 AM plus scaled time since sunrise
			solarHour = 6 + (hour - rise) * dayScale;
		} else {
			// 18:00 (6PM) plus scaled time since sunset
			solarHour = 18 + (hour - set) * nightScale;
		}
		
		// solarHour may be < 0 or > 24, tm struct takes care of it
		// TODO verify that this happens with strftime
		tm->tm_hour = (int)solarHour;
		tm->tm_min = (int)round(solarHour*60) % 60;
		
		char s[1024];
		strftime(s, 1024, "%l:%M %p", tm);
		timeLabel.text = [[NSString stringWithCString:s encoding:NSUTF8StringEncoding] lowercaseString];
		strftime(s, 1024, "%A, %b %e %G", tm);
		dateLabel.text = [NSString stringWithCString:s encoding:NSUTF8StringEncoding];
		
		locationLabel.text = lastPlaceName ? lastPlaceName : @"";

		tm->tm_hour = (int)rise;
		tm->tm_min = (int)round(rise*60) % 60;
		strftime(s, 1024, "%l:%M %p", tm);
		sunriseLabel.text = [NSString stringWithFormat:@"Sunrise %@", [[NSString stringWithCString:s encoding:NSUTF8StringEncoding] lowercaseString]];
		tm->tm_hour = (int)set;
		tm->tm_min = (int)round(set*60) % 60;
		strftime(s, 1024, "%l:%M %p", tm);
		sunsetLabel.text = [NSString stringWithFormat:@"Sunset %@", [[NSString stringWithCString:s encoding:NSUTF8StringEncoding] lowercaseString]];
		
		int dayLengthHours = (int)daylen;
		int dayLengthMinutes = (int)round(daylen*60) % 60;
		if(dayLengthMinutes == 0) {
			dayScaleLabel.text = [NSString stringWithFormat:@"%d hours in a day", dayLengthHours];
		} else {
			dayScaleLabel.text = [NSString stringWithFormat:@"%d hours %d minutes in a day", dayLengthHours, dayLengthMinutes];
		}
	} else {
		timeLabel.text = @"Loading…";
		dateLabel.text = @"";
		locationLabel.text = @"";
		sunriseLabel.text = @"";
		sunsetLabel.text = @"";
		dayScaleLabel.text = @"";
	}
}

- (void)toggleInfo:(id)sender;
{
	if(CGRectGetMaxY(infoView.frame) > self.view.frame.size.height) {
		[self showInfo];
	} else {
		[self hideInfo];
	}
}

- (void)showInfo;
{
	[UIView beginAnimations:@"show_info" context:NULL];
	[UIView setAnimationDuration:0.4];
	CGSize sz = self.view.frame.size;
	CGRect r = infoView.frame;
	r.origin.y = sz.height - r.size.height;
	infoView.frame = r;
	[UIView commitAnimations];
}

- (void)hideInfo;
{
	[UIView beginAnimations:@"show_info" context:NULL];
	[UIView setAnimationDuration:0.4];
	CGSize sz = self.view.frame.size;
	CGRect r = infoView.frame;
	r.origin.y = sz.height - 50;
	infoView.frame = r;
	[UIView commitAnimations];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (void)dealloc {
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
	
    [ticker invalidate];
	[locationManager release];
	
	[lastLocation release];
	[lastPlaceName release];
	
	[super dealloc];
}


@end



/*
 
 
 - (void)drawClockFace:(CGRect)rect inContext:(CGContextRef)ctx;
 {
 CGContextSaveGState(ctx);
 
 float r = self.bounds.size.width / 2;
 
 CGPoint tick1[] = { {r*0.85,0}, {r*0.98,0} };
 CGPoint tick2[] = { {r*0.85,0}, {r*0.88,0} };
 
 [[UIColor whiteColor] setStroke];
 CGContextSetLineWidth(ctx, r * 0.04);
 for(int i=0; i<12; ++i) {
 CGContextStrokeLineSegments(ctx, tick1, 2);
 CGContextRotateCTM(ctx, M_PI/(6*5));
 for(int j=0; j<4; ++j) {
 CGContextStrokeLineSegments(ctx, tick2, 2);
 CGContextRotateCTM(ctx, M_PI/(6*5));
 }
 }
 
 CGContextRestoreGState(ctx);
 }
 
 - (void)drawHands:(CGRect)rect inContext:(CGContextRef)ctx;
 {
 float r = self.bounds.size.width / 2;
 
 // location isn't necessarily in the current time zone - so then what?
 NSDate *date = [[NSDate date] localTimeForLongitude:_location.coordinate.longitude latitude:_location.coordinate.latitude];
 
 // TODO do this as part of tick(), not while rendering
 label.text = [[_dateFormatter stringFromDate:date] lowercaseString];
 
 NSTimeInterval seconds = [[NSCalendar currentCalendar] ordinalityOfUnit:NSSecondCalendarUnit inUnit:NSDayCalendarUnit forDate:date];
 
 CGContextRotateCTM(ctx, -M_PI_2);
 [[UIColor colorWithWhite:1 alpha:1] set];
 
 CGPoint points[] = { {0,0}, {r*0.33, 0} };
 
 CGContextSaveGState(ctx);
 CGContextRotateCTM(ctx, 2 * M_PI * seconds / (12.0*60*60));
 CGContextSetLineWidth(ctx, r * 0.055);
 CGContextStrokeLineSegments(ctx, points, 2);
 CGContextRestoreGState(ctx);
 
 CGContextSaveGState(ctx);
 CGContextRotateCTM(ctx, 2 * M_PI * seconds / (60.0*60));
 points[1].x = r*0.66;
 CGContextSetLineWidth(ctx, r*0.035);
 CGContextStrokeLineSegments(ctx, points, 2);
 CGContextRestoreGState(ctx);
 
 #if 0 // second hand
 [[UIColor redColor] set];
 CGContextSaveGState(ctx);
 CGContextRotateCTM(ctx, 2 * M_PI * seconds / 60.0);
 CGContextFillRect(ctx, CGRectMake(0, -1, r*0.85, 2));
 CGContextRestoreGState(ctx);
 #endif
 }
*/ 
