//
//  Local_Time_Tests.m
//  Local Time Tests
//
//  Created by Andrew Zeldis on 4/21/15.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "NSDate+LocalTime.h"

@interface Local_Time_Tests : XCTestCase {
    double lat;
    double lon;
    NSCalendar *calendar;
}

@end

@implementation Local_Time_Tests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

    // NYC
    lat = 40.726499;
    lon = -74.00628;
    
    calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}



- (void)testTimeFuzz;
{
    NSDate *now = [NSDate date];
    
    const NSTimeInterval step = 13;
    NSTimeInterval t = [now timeIntervalSinceReferenceDate];
    NSTimeInterval tPrev = t - step*0.5;
    NSTimeInterval end = t + (1*60*60*25);
    while(t < end) {
        now = [NSDate dateWithTimeIntervalSinceReferenceDate:t];
        
        NSDate *localNow = [now localTimeForLongitude:lon latitude:lat];
        
        NSDate *rise = [now sunriseAtLongitude:lat latitude:lon];
        NSDate *set = [now sunsetAtLongitude:lat latitude:lon];
        
        NSDate *localRise = [rise localTimeForLongitude:lon latitude:lat];
        NSDate *localSet = [set localTimeForLongitude:lon latitude:lat];
        
        XCTAssert(t > tPrev, @"time is going backwards");
        XCTAssert(t < (tPrev + step*2), @"time is going too fast");
        
        tPrev = t;
        t += step;
    }
}

- (void)testSunriseSunset;
{
    // TODO Saff squeeze - shouldn't sunrise and sunset be at 6?
    
    NSDate *now = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
    
    NSDate *rise = [now sunriseAtLongitude:lat latitude:lon];
    NSDate *set = [now sunsetAtLongitude:lat latitude:lon];
    
    NSDate *localRise = [rise localTimeForLongitude:lon latitude:lat];
    NSDate *localSet = [set localTimeForLongitude:lon latitude:lat];
    
    NSLog(@"rise: %@", rise);
    NSLog(@"set: %@", set);
    NSLog(@"local rise: %@", localRise);
    NSLog(@"local set: %@", localSet);
    
    unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *localRiseComponents = [calendar components:unitFlags fromDate:localRise];
    NSDateComponents *localSetComponents = [calendar components:unitFlags fromDate:localSet];
    
    XCTAssertEqual([localRiseComponents hour], 6, @"Sunrise is at 6 am - got %@", localRise);
    XCTAssertEqual([localRiseComponents minute], 0, @"Sunrise is at 6:00 sharp - got %@", localRise);
    XCTAssertEqual([localSetComponents hour], 18, @"Sunset is at 6 pm - got %@", localSet);
    XCTAssertEqual([localSetComponents minute], 0, @"Sunset is at 18:00 sharp - got %@", localSet);
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
