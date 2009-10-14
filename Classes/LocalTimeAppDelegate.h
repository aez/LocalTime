//
//  LocalTimeAppDelegate.h
//  Local Time
//
//  Created by Andy Zeldis on 6/8/08.
//  Copyright Andy Zeldis 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@class MainViewController;

@interface LocalTimeAppDelegate : NSObject <UIApplicationDelegate, CLLocationManagerDelegate> {
	IBOutlet UIWindow *window;
	IBOutlet MainViewController *mainViewController;

    CLLocationManager *locationManager;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) MainViewController *mainViewController;

@end

