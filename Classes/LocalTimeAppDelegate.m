//
//  LocalTimeAppDelegate.m
//  Local Time
//
//  Created by Andy Zeldis on 6/8/08.
//  Copyright Andy Zeldis 2008. All rights reserved.
//

#import "LocalTimeAppDelegate.h"
#import "MainViewController.h"

@implementation LocalTimeAppDelegate

@synthesize window;
@synthesize mainViewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	locationManager = [[CLLocationManager alloc] init];
	locationManager.delegate = self;
	[locationManager startUpdatingLocation];
	
	//[window addSubview:[navController view]];
	[window addSubview:mainViewController.view];
	[window makeKeyAndVisible];
}

- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation;
{
    NSLog(@"got location %f %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
    // TODO check again after a while in case they're on the move
    [locationManager stopUpdatingLocation];
	
	mainViewController.location = newLocation;
	
	[[NSUserDefaults standardUserDefaults] setDouble:newLocation.coordinate.latitude forKey:@"latitude"];
	[[NSUserDefaults standardUserDefaults] setDouble:newLocation.coordinate.longitude forKey:@"longitude"];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;
{
    NSLog(@"location failed: %@", error);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Couldn't determine location" message:[error description] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (void)dealloc {
	[locationManager release];
	[window release];
	[super dealloc];
}

@end
