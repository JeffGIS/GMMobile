//  Destinations.h
//  GMMobile

#import <Foundation/Foundation.h>
#import "CCodeLibrary/CCodeLibrary.h"
#import "PropertyListFields.h"
#import <MapKit/MapKit.h>

@interface Destination : NSObject

@property NSInteger frequency, destinationID, groupID, timeDepart, timeReturn;
@property NSString *destinationName;
@property LLPOINT latlon;
@property NSUInteger tranportType;

@end

@interface Route : NSObject

@property CGFloat distanceInMiles;
@property CGFloat timeInMinutes;
@property NSArray *routePolyline;

@end

@interface RouteStep : NSObject

@property MKPolyline *polyline;
@property MKDirectionsTransportType transportType;

+ (RouteStep *)routeStepWithPolyline:(MKPolyline *)polyline
                       transportType:(MKDirectionsTransportType)transportType;

@end

@interface Destinations : NSObject

-(NSInteger)addParcelToDestinations:(NSString *)PID;

- (Destination *)getDestination:(NSInteger)destinationID;
- (NSArray *)getIndividualDestinations;
- (NSArray *)getGroupDestinations;
- (NSArray *)getDestinationsWithinGroup:(NSInteger)groupID;
- (NSInteger)addIndividualDestination:(Destination *)destination;
- (NSInteger)addGroupDestination:(Destination *)destination;
- (void)removeDestination:(NSInteger)destinationID;
- (void)addRoutesForProperty:(NSInteger)propNum
                  inPropList:(id)propList;

- (NSInteger)addDestination:(Destination *)destination
                    toGroup:(NSInteger)groupID;

- (void)updateDestinationName:(NSInteger)destinationID
                      newName:(NSString *)name;
- (void)updateDestination:(Destination*)dest;

- (CGFloat)totalValueForProperty:(NSInteger)propNum
                          ofType:(PropFieldType)type;

@end
