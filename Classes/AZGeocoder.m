//
//  AZGeocoder.m
//  Local Time
//
//  Created by Andy Zeldis on 4/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AZGeocoder.h"
#import <CoreLocation/CoreLocation.h>


// reverse geocoding is via http://www.geonames.org/export/ws-overview.html
// could also try http://developer.yahoo.com/geo/
// TODO geoname caching

/*
 http://ws.geonames.org/findNearbyPlaceName?lat=47.3&lng=9
 
 <?xml version="1.0" encoding="UTF-8" standalone="no"?>
 <geonames>
 <geoname>
 <name>Atzmännig</name>
 <lat>47.287633</lat>
 <lng>8.988454</lng>
 <geonameId>6559633</geonameId>
 <countryCode>CH</countryCode>
 <countryName>Switzerland</countryName>
 <fcl>P</fcl>
 <fcode>PPL</fcode>
 <distance>1.6276</distance>
 </geoname>
 </geonames>
 
 */

@implementation AZGeocoder

@synthesize delegate = _delegate;

- (id)init;
{
	if(self = [super init]) {
		
	}
	return self;
}

- (void)findNameForLocation:(CLLocation *)location;
{
	// TODO implement
}

- (void)setLocation:(CLLocation *)loc;
{
	NSString *urlString = [NSString stringWithFormat:@"http://ws.geonames.org/findNearbyPlaceName?lat=%.1f&lng=%.1f&style=short", 
						   loc.coordinate.latitude, loc.coordinate.longitude];
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
	[self callWebService:request delegate:self];
}


#pragma mark AJAX

static NSMutableString *currentStringValue;

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
		
		[currentStringValue release];
		currentStringValue = nil;
	}
}


#pragma mark Web Service API


- (void)callWebService:(NSURLRequest *)request delegate:(id)delegate;
{
	_delegate = delegate;
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
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
{
	[_data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{
	[self webServiceResponse:_data];
}

- (void)dealloc {
    [super dealloc];
}

@end
