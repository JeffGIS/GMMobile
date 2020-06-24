//  PropertyData.h
//  GMMobile

#import "CCodeLibrary/SQLiteLib.h"
#import "CCodeLibrary/CCodeLibrary.h"
#import "Themes.h"
@import CoreGraphics;
#import <CoreText/CoreText.h>

#define CURRENT_EXTRACT_DATE @"20191001"

int DaysSince2004(NSString *sdate);

typedef NS_ENUM(NSInteger, PropDataOption)
{
    PDSettingDefault,
    PDSettingRank,
    PDSettingComputed,
};

typedef NS_ENUM(NSInteger, LimitToOption)
{
    LimitToOptionNoLimit,
    LimitToOptionMapBounds,
    LimitToOptionCurrentCity,
    LimitToOptionCurrentCounty,
};

typedef NS_ENUM(NSInteger, ActionOption)
{
    ActionOptionAddToMap,
    ActionOptionClearAndAddToMap,
    ActionOptionAddToNewPropList,
    ActionOptionAddToCurrentPropList,
};

@class PropertyData;

@protocol PropertyDataDelegate <NSObject>

- (void)matchingOwners:(NSArray *)ownerArray;

@end

@interface PropertyRecord : NSObject

@property (nonatomic) NSString *pin;
@property (nonatomic) NSString *propOwner;
@property CLLocationCoordinate2D coordinate;

+ (instancetype)propertyRecordWithPin:(NSString *)pin
                            propOwner:(NSString *)propOwner
                           coordinate:(CLLocationCoordinate2D)coordinate;

@end

@interface PropertyDataExtract : NSObject
@property NSString* PIN;
@property NSString* homeStead;
@property NSString* taxExempt;
@property NSString* useCode;
@property NSString* useDesc;
@property double emvTotal;
@property double emvLand;
@property double emvBuilding;
@property double totalTax;
@property double specAssmt;
@property NSString* ownerName;
@property NSString* taxName;
@property NSString* saleDate;
@property double saleVal;
@property NSString* bldgNum;
@property NSString* streetName;
@property NSString* unit;
@property NSString* unitType;
@property NSString* city;
@end

@interface PropertyHistory : NSObject
@property int year;
@property int emvLand;
@property int emvBldg;
@property int emvTotal;
@property int taxCapacity;
@property int totalTax;
@property int specAsses;
@property int saledate;
@property int saleVal;
@property BOOL homestead;
@property BOOL exempt;
@end

@interface StreetPoint : NSObject
@property NSString * streetName;
@property int speed;
@property double dist;
@property double x,y;
@end

@interface SalesData : NSObject
@property NSString * date;
@property int daysSince2004;
@property int saleVal;
@property int totalEMV;
@property NSString * PIN;
@end

@interface PropertyData : NSObject

@property (nonatomic, weak) id <PropertyDataDelegate> delegate;
@property sqlite3nv *database;
@property (atomic) BOOL isOpen;
@property NSString* version;
@property (nonatomic, copy) NSString *documentsDirectory;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *cenfileName;
@property (nonatomic, copy) NSString *multiValueFile;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSString *cenpath;
@property (nonatomic, copy) NSString *yearAndQuarter;
@property int year;
@property LPTRANDATA pTranLLtoView;
@property LPTRANDATA pTranViewtoLL;
@property long long fileSize;
@property int processingID;
@property CGFloat zoom;
@property (nonatomic) int propertyDatasetVersion;
@property (nonatomic) int parcelDatasetVersion;
@property (nonatomic) int censusDatasetVersion;
@property (nonatomic) int planDatasetVersion;

- (BOOL)open;
- (void)close:(BOOL)opened;
- (void)clear;
- (BOOL)executeCmd:(char *)cmd;
- (void)startTransaction;
- (void)commitTransaction;
- (int)propertyDatasetVersion;
- (NSMutableArray *)getPIDsMatchingString:(NSString *)matchChar;

- (NSMutableArray *)getPIDsWithOwnerMatchingString:(NSString *)matchChar
                                           limitOf:(int)lim;

- (NSMutableArray *)getPIDsMatchingAddress:(NSString *)houseNumber
                                streetName:(NSString *)matchChar;

- (LLPOINT) getPointForPID:(NSString *)PID;
- (MNMXCORD) getBoundsForPID:(NSString*)PID;
- (LLPOINT) getPointOnStreetForPID:(NSString *)PID
                             speed:(int *)pSpeed;
+ (CLLocationCoordinate2D) pointOnStreetForPID:(NSString *)PID
                                         speed:(int *)pSpeed;

- (int)pickPID:(LLPOINT *)pt
 useVisibility:(BOOL)useVis
  highlightList:(NSMutableArray *)hlist;
- (int)pickParcel:(LLPOINT *)pt
    highlightList:(NSMutableArray*)hlist;
-(NSMutableArray *) getParcelHistory:(NSString*)PID;
- (NSString *) getPIDAddress:(NSString *)PID;

- (BOOL)getAddressForPID:(NSString *)PID
         houseNumAndUnit:(NSString **)houseAndUnit
              streetName:(NSString **)streetName
                    city:(NSString **)city
                     zip:(NSString **)zip
               ownerName:(NSString **)owner
            taxpayerName:(NSString **)taxpayer
             censusBlock:(NSString **)cenblock
   associatedCensusBlock:(NSString **)cenblockAssociated
                 useDesc:(NSString **)usedesc
                saleDate:(NSString **)saleDate
               saleValue:(double *)saleValue
               yearBuilt:(int *)yearBuilt
                  totEMV:(double *)totEMV
                 landEMV:(double *)landEMV
                 bldgEMV:(double *)bldgEMV
                  totTAX:(double *)totTax
                 specAss:(double *)specAss
                   acres:(double *)acres;

- (NSString *)getOwnerNameForPID:(NSString *)PID;
+ (NSString *)getCensusBlockForPID:(NSString *)PID;
+ (NSString *)getPIDforPolyID:(int)ID;
- (NSString *)getPIDforPolyid:(int)ID;


- (NSString*)getNearestPID:(CLLocationCoordinate2D*)pt;

- (void)displayParcels:(CGContextRef)context
             llCorners:(CORNERPOINTS *) latlonCornerPoints
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds
                themes:(Themes*)themes;

+(NSString*) adjustParcelText:(NSString*)text;

-(void)displayParcelText:(CGContextRef)context
               llCorners:(CORNERPOINTS *) latlonCornerPoints
                LLBounds:(MNMXCORD *)platlonBounds
              viewBounds:(MNMXCORD *)pvbounds;

- (NSMutableArray *)getReport:(PropDataOption)option
                       forPID:(NSString *)pid;

- (BOOL)getOwnersMatchingString:(NSString *)INstring
                        limitTo:(LimitToOption)limitTo;
- (BOOL)getDistinctUseCodes:(NSString *)outFile;

- (LPDPOINT)getParcelPolygonPointsForPID:(NSString *)PID
                               numPoints:(int *)numPoints
                                numLoops:(int *)numLoops
                             polyPartLen:(int **)polyPartLen;
- (NSArray*)getLinkedParcels:(NSString*)pid;

- (NSArray*)getSalesHistoryForPropMatching:(NSString *)PID
                                inAreaType:(NSString *)areaType;

@end
