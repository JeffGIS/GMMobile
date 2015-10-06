//  Destinations.h
//  GMMobile

#import <Foundation/Foundation.h>
#import "PropertyList.h"
#import "CCodeLibrary/CCodeLibrary.h"
#import <MapKit/MapKit.h>

@interface Destination : NSObject

@property NSInteger destinationID, groupID, timeDepart, timeReturn;
@property (nonatomic, copy) NSString *destinationName;
@property (nonatomic) LLPOINT latlon;
@property (nonatomic) CGFloat frequency;
@property (nonatomic) NSUInteger tranportType;

@end

@interface Route : NSObject

@property (nonatomic) CGFloat distanceInMiles;
@property (nonatomic) CGFloat timeInMinutes;
@property (nonatomic) NSArray *routePolyline;

@end

@interface Destinations : NSObject

-(NSInteger)addParcelToDestinations:(NSString *)PID;

-(NSArray*)getIndividualDestinations;
-(NSArray*)getGroupDestinations;
-(NSArray*)getDestinationsWithinGroup:(NSInteger)groupID;
-(NSInteger)addIndividualDestination:(Destination*)destination;
-(NSInteger)addGroupDestination:(Destination*)destination;
-(NSInteger)addDestination:(Destination*)destination toGroup:(NSInteger)groupID;
-(void)removeDestination:(NSInteger)destinationID;
-(void)updateDestinationName:(NSInteger)destinationID
                     newName:(NSString*)name;
-(void)addRoutesForProperty:(NSInteger)propNum;

- (CGFloat)totalValueForProperty:(NSInteger)propNum ofType:(PropFieldType)type;
@end
