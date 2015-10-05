//  Destinations.h
//  GMMobile

#import <Foundation/Foundation.h>
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

@class Destinations;

@protocol DestinationsDelegate <NSObject>

- (void)destinationsDidReturnRoute:(Route *)route;

@end

@interface Destinations : NSObject

@property (nonatomic, weak) id <DestinationsDelegate> delegate;

- (BOOL)addParcelToDestinations:(NSString *)PID;
- (NSArray *)getIndividualDestinations;
- (NSArray *)getGroupDestinations;
- (NSArray *)getDestinationsWithinGroup:(NSInteger)groupID;
- (void)addIndividualDestination:(Destination *)destination;
- (void)addGroupDestination:(Destination *)destination;

-(NSArray*)getIndividualDestinations;
-(NSArray*)getGroupDestinations;
-(NSArray*)getDestinationsWithinGroup:(NSInteger)groupID;
-(int)addIndividualDestination:(Destination*)destination;
-(int)addGroupDestination:(Destination*)destination;
-(int)addDestination:(Destination*)destination toGroup:(NSInteger)groupID;
-(void)removeDestination:(NSInteger)destinationID;

-(void)addRoutesForProperty:(NSInteger)propNum;

-(Route*)getRouteFrom:(LLPOINT)fromPoint
                   to:(LLPOINT)toPoint;
@end
