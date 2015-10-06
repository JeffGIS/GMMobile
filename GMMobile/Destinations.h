//  Destinations.h
//  GMMobile

#import <Foundation/Foundation.h>
#import "PropertyList.h"
#import "CCodeLibrary/CCodeLibrary.h"
#import <MapKit/MapKit.h>


@interface Destination : NSObject

@property NSInteger destinationID, timeDepart, timeReturn;
@property (nonatomic, copy) NSString *destinationName;
@property (nonatomic) LLPOINT latlon;
@property (nonatomic) CGFloat frequency;

@end

@interface Route : NSObject

@property (nonatomic) CGFloat distanceInMiles;
@property (nonatomic) CGFloat timeInMinutes;
@property (nonatomic) NSArray *routePolyline;

@end

@interface Destinations : NSObject

- (int)addParcelToDestinations:(NSString *)PID;
- (NSArray *)getIndividualDestinations;
- (NSArray *)getGroupDestinations;
- (NSArray *)getDestinationsWithinGroup:(NSInteger)groupID;
- (int)addIndividualDestination:(Destination *)destination;
- (int)addGroupDestination:(Destination *)destination;
- (void)removeDestination:(NSInteger)destinationID;
- (void)addRoutesForProperty:(NSInteger)propNum;

- (CGFloat)totalValueForProperty:(NSInteger)propNum
                          ofType:(PropFieldType)type;

- (int)addDestination:(Destination *)destination
              toGroup:(NSInteger)groupID;

@end