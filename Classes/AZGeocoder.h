//
//  AZGeocoder.h
//  Local Time
//
//  Created by Andy Zeldis on 4/5/09.
//  Copyright 2009 Andy Zeldis. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLLocation;
@protocol AZGeocoderDelegate;

@interface AZGeocoder : NSObject {
@private
	id _delegate;
	CLLocation *_location;
	NSMutableData *_data;
	NSMutableString *currentStringValue;
	NSString *_placeName;
}

@property(nonatomic, assign) id<AZGeocoderDelegate> delegate;
@property(readonly) NSString *placeName;

- (void)findNameForLocation:(CLLocation *)location;
- (void)callWebService:(NSURLRequest *)request delegate:(id)delegate;

@end


@protocol AZGeocoderDelegate

- (void)geocoder:(AZGeocoder *)geocoder didFindName:(NSString *)name forLocation:(CLLocation *)location;
- (void)geocoder:(AZGeocoder *)geocoder didFailWithError:(NSError *)error;

@end
