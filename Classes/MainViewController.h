//
//  MainViewController.h
//  Local Time
//
//  Created by Andy Zeldis on 6/8/08.
//  Copyright Andy Zeldis 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#import "AZGeocoder.h"

@class CLLocation;

@interface MainViewController : UIViewController <CLLocationManagerDelegate, AZGeocoderDelegate> {
    IBOutlet UILabel *timeLabel;
    IBOutlet UILabel *dateLabel;
	IBOutlet UILabel *locationLabel;
    IBOutlet UILabel *sunriseLabel;
    IBOutlet UILabel *sunsetLabel;
	IBOutlet UILabel *dayScaleLabel;
	IBOutlet UIView *infoView;
	
    NSTimer *ticker;
	
    CLLocationManager *locationManager;
	AZGeocoder *geocoder;
	
	CLLocation *lastLocation;
	NSString *lastPlaceName;
}

// internal

- (void)tick:(NSTimer *)timer;
- (void)updateDisplay;

- (void)toggleInfo:(id)sender;
- (void)showInfo;
- (void)hideInfo;

@end
