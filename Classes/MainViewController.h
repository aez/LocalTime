//
//  MainViewController.h
//  Local Time
//
//  Created by Andy Zeldis on 6/8/08.
//  Copyright Andy Zeldis 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AZGeocoder.h"

@class CLLocation;

@interface MainViewController : UIViewController <AZGeocoderDelegate> {
    IBOutlet UILabel *infoLabel;
    IBOutlet UILabel *timeLabel;
    IBOutlet UILabel *officialTimeLabel;
    IBOutlet UILabel *sunriseLabel;
    IBOutlet UILabel *sunsetLabel;
	IBOutlet UILabel *dayScaleLabel;
	IBOutlet UIView *infoView;
	
	NSDateFormatter *_timeFormatter;
	NSDateFormatter *_dateFormatter;
    NSTimer *ticker;
	
	CLLocation *_location;
	AZGeocoder *geocoder;
}

//typedef CFStringRef (*ABActionGetPropertyCallback)(void);

@property(nonatomic, retain) CLLocation *location;

// internal

- (void)tick:(NSTimer *)timer;
- (void)updateDisplay;

- (void)showInfo;
- (void)hideInfo;
- (void)toggleInfo:(id)sender;

@end
