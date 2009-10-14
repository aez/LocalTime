//
//  MainViewController.m
//  Local Time
//
//  Created by Andy Zeldis on 6/8/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import "MainViewController.h"
#import "NSDate+LocalTime.h"
#import <CoreLocation/CoreLocation.h>


#import <time.h>
#import "sunriseset.h"

// TODO screens for acquiring location, error

// TODO figure out how to deal with timely awake from sleep

@implementation MainViewController

@synthesize location=_location;

- (void)viewDidLoad;
{
	_timeFormatter = [[NSDateFormatter alloc] init];
	_timeFormatter.dateStyle = NSDateFormatterNoStyle;
	_timeFormatter.timeStyle = NSDateFormatterShortStyle;
	
	_dateFormatter = [[NSDateFormatter alloc] init];
	_dateFormatter.dateStyle = NSDateFormatterShortStyle;
	_dateFormatter.timeStyle = NSDateFormatterNoStyle;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if([defaults doubleForKey:@"latitude"]) {
		CLLocation *savedLocation = [[[CLLocation alloc] initWithLatitude:[defaults doubleForKey:@"latitude"] longitude:[defaults doubleForKey:@"longitude"]] autorelease];
		// TODO do something with savedLocation
		_location = [savedLocation retain];
	}
	
	[self.view addSubview:infoView];
	infoView.frame = CGRectMake(0, self.view.frame.size.height - 50, infoView.frame.size.width, infoView.frame.size.height);

	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
	
    ticker = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(tick:) userInfo:nil repeats:YES];
	[self tick:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

- (void)deviceOrientationDidChange:(NSNotification *)notification;
{
	const float landscapeScale = 1.5;
	const int landscapeOffset = 120;
	
	UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
	
	if(UIDeviceOrientationIsPortrait(orientation)) {
		[[UIApplication sharedApplication] setStatusBarHidden:NO animated:YES];
	} else if(UIDeviceOrientationIsLandscape(orientation)) {
		[self hideInfo];
		[[UIApplication sharedApplication] setStatusBarHidden:YES animated:YES];
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

- (void)setLocation:(CLLocation *)location;
{
	[_location autorelease];
	_location = location;
	[_location retain];
	
	[self updateDisplay];
}

- (void)tick:(NSTimer *)timer;
{
	[self updateDisplay];
}

- (void)updateDisplay;
{
	if(_location) {
		float lon = _location.coordinate.longitude;
		float lat = _location.coordinate.latitude;
		
		NSCalendar *gmtCalendar = [NSCalendar currentCalendar];
		[gmtCalendar setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
		NSDateComponents *d = [gmtCalendar components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:[NSDate date]];
		
		double rise_hour, set_hour;
		sun_rise_set([d year], [d month], [d day], lon, lat, &rise_hour, &set_hour);
		double noon_hour = (rise_hour + set_hour) / 2;
		
		// TODO conversion from gmt time zone isn't working properly
		[d setHour: (NSInteger) rise_hour];
		[d setMinute: (NSInteger) (rise_hour*60) % 60];
		NSDate *gmtRiseDate = [gmtCalendar dateFromComponents:d];
		NSDate *riseDate = [NSDate dateWithTimeIntervalSinceReferenceDate:[gmtRiseDate timeIntervalSinceReferenceDate]];
		[d setHour: (NSInteger) set_hour];
		[d setMinute: (NSInteger) (set_hour*60) % 60];
		NSDate *setDate = [NSDate dateWithTimeIntervalSinceReferenceDate:[[gmtCalendar dateFromComponents:d] timeIntervalSinceReferenceDate]];
		[d setHour: (NSInteger) noon_hour];
		[d setMinute: (NSInteger) (noon_hour*60) % 60];
		NSDate *noonDate = [gmtCalendar dateFromComponents:d];
		
		NSLog(@"noon: %@", noonDate);
		
		float dayLength = [noonDate dayLengthForLongitude:lon latitude:lat];
		
		timeLabel.text = [[_timeFormatter stringFromDate:noonDate] lowercaseString];
		// TODO location name from Geocoder
		if(YES) {
			infoLabel.text = [_dateFormatter stringFromDate:noonDate];
		} else {
			infoLabel.text = [NSString stringWithFormat:@"%@ %@",
							  [_dateFormatter stringFromDate:noonDate],
							  @"Brooklyn, NY"];
		}
		officialTimeLabel.text = [NSString stringWithFormat:@"Official time %@", [_timeFormatter stringFromDate:[NSDate date]]];
		sunriseLabel.text = [NSString stringWithFormat:@"Sunrise %@", [_timeFormatter stringFromDate:noonDate]];
		sunsetLabel.text = [NSString stringWithFormat:@"Sunset %@", [_timeFormatter stringFromDate:setDate]];
		dayScaleLabel.text = [NSString stringWithFormat:@"%2d hours %2d minutes in a day", (int)dayLength, (int)(dayLength * 100) % 60];
	} else {
		timeLabel.text = @"Loading…";
		officialTimeLabel.text = @"";
		sunriseLabel.text = @"";
		sunsetLabel.text = @"";
		dayScaleLabel.text = @"";
	}
}

- (void)updateDisplay_withTimestretching;
{
	if(_location) {
		float lon = _location.coordinate.longitude;
		float lat = _location.coordinate.latitude;
		
		NSDate *date = [NSDate date];
		NSDate *localDate = [date localTimeForLongitude:lon latitude:lat];
		timeLabel.text = [[_timeFormatter stringFromDate:localDate] lowercaseString];
		
		// TODO location name from Geocoder
		NSMutableString *infoString = [NSMutableString stringWithString:[_dateFormatter stringFromDate:localDate]];
		if(YES) {
			[infoString appendString:@" "];
			[infoString appendString:@"Brooklyn, NY"];
		}
		infoLabel.text = infoString;
		
		NSDate *sunrise = [date sunriseAtLatitude:lat longitude:lon];
		NSDate *sunset = [date sunsetAtLatitude:lat longitude:lon];
		officialTimeLabel.text = [NSString stringWithFormat:@"Official time %@", [_timeFormatter stringFromDate:date]];
		sunriseLabel.text = [NSString stringWithFormat:@"Sunrise %@", [_timeFormatter stringFromDate:sunrise]];
		sunsetLabel.text = [NSString stringWithFormat:@"Sunset %@", [_timeFormatter stringFromDate:sunset]];
		float dayLength = [localDate dayLengthForLongitude:lon latitude:lat];
		dayScaleLabel.text = [NSString stringWithFormat:@"%2d hours %2d minutes in a day", (int)dayLength, (int)(dayLength * 100) % 60];
	} else {
		timeLabel.text = @"Loading…";
		officialTimeLabel.text = @"";
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
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}

- (void)dealloc {
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
	
    [ticker invalidate];
	[_location release];
	
	[_dateFormatter release];
	[_timeFormatter release];
	
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
