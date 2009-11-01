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
	[window addSubview:mainViewController.view];
	[window makeKeyAndVisible];
}

- (void)dealloc {
	[window release];
	[super dealloc];
}

@end
