//
//  AZGeocoder.m
//  Local Time
//
//  Created by Andy Zeldis on 4/5/09.
//  Copyright 2009 Andy Zeldis. All rights reserved.
//

#import "AZGeocoder.h"
#import <CoreLocation/CoreLocation.h>


// reverse geocoding is via http://www.geonames.org/export/ws-overview.html
// could also try http://developer.yahoo.com/geo/
// TODO geoname caching

/*
 http://ws.geonames.org/findNearbyPlaceName?lat=40.660262&lng=-73.991718
 
 <?xml version="1.0" encoding="UTF-8" standalone="no"?>
 <geonames>
 <geoname>
 <name>Park Slope</name>
 <lat>40.6701033</lat>
 <lng>-73.9859723</lng>
 <geonameId>5130561</geonameId>
 <countryCode>US</countryCode>
 <countryName>United States</countryName>
 <fcl>P</fcl>
 <fcode>PPLX</fcode>
 <distance>1.2007</distance>
 </geoname>
 </geonames>
 
 */

@implementation AZGeocoder

@synthesize delegate=_delegate;
@synthesize placeName=_placeName;

- (id)init;
{
	if(self = [super init]) {
		
	}
	return self;
}

- (void)findNameForLocation:(CLLocation *)location;
{
	_location = location;
	NSString *urlString = [NSString stringWithFormat:@"http://ws.geonames.org/findNearbyPlaceName?lat=%.4f&lng=%.4f&style=short", 
						   location.coordinate.latitude, location.coordinate.longitude];
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
	[self callWebService:request delegate:self];
}


#pragma mark AJAX

- (void)webServiceResponse:(NSData *)data;
{
	NSString *s = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	NSLog(@"%@\n", s);
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
	[parser setDelegate:self];
	[parser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	
	NSLog(@"el: %@", elementName);
	if ( [elementName isEqualToString:@"name"]) {
		currentStringValue = [[NSMutableString alloc] init];
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    [currentStringValue appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	
	NSLog(@"/el: %@ (%@)", elementName, currentStringValue);
    if([elementName isEqualToString:@"name"]) {
		NSLog(@"got place %@", currentStringValue);
		
		[_placeName release];
		_placeName = [currentStringValue copy];
		
		[currentStringValue release];
		currentStringValue = nil;
	}
}


#pragma mark Web Service API


- (void)callWebService:(NSURLRequest *)request delegate:(id)delegate;
{
	NSURLConnection *conn = [NSURLConnection connectionWithRequest:request delegate:self];
	_data = [[NSMutableData data] retain];
	[conn start];
	NSLog(@"call %@", request);
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
{
	NSLog(@"response %@", response);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
{
	NSLog(@"failed %@", error);
	[self.delegate geocoder:self didFailWithError:error];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
{
	[_data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{
	[self webServiceResponse:_data];
	[self.delegate geocoder:self didFindName:_placeName forLocation:_location];
}

- (void)dealloc {
    [super dealloc];
}

@end
