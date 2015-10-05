//
//  Destinations.h
//  GMMobile
//
//  Created by JEFFREY E SMITH on 10/4/15.
//  Copyright (c) 2015 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCodeLibrary/CCodeLibrary.h"

@interface Destination : NSObject
@property NSInteger destinationID;
@property NSString* destinationName;
@property LLPOINT latlon;
@property CGFloat frequency;
@property NSInteger timeDepart, timeReturn;
@end

@interface Route : NSObject
@property CGFloat distanceInMiles;
@property CGFloat timeInMinutes;
@property NSArray* routePolyline;
@end

@interface Destinations : NSObject

- (BOOL)addParcelToDestinations:(NSString *)PID;

-(NSArray*)getIndividualDestinations;
-(NSArray*)getGroupDestinations;
-(NSArray*)getDestinationsWithinGroup:(NSInteger)groupID;
-(void)addIndividualDestination:(Destination*)destination;
-(void)addGroupDestination:(Destination*)destination;
-(void)addDestination:(Destination*)destination toGroup:(NSInteger)groupID;
-(void)removeDestination:(NSInteger)destinationID;

-(Route*)getRouteFrom:(LLPOINT)fromPoint
                   to:(LLPOINT)toPoint;
@end
