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

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//	[window addSubview:mainViewController.view];
    [window setRootViewController:mainViewController];
	[window makeKeyAndVisible];
    return YES;
}

- (void)dealloc {
	[window release];
	[super dealloc];
}

@end
