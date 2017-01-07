//  PropertyData.h
//  GMMobile

#import "CCodeLibrary/SQLiteLib.h"
#import "CCodeLibrary/CCodeLibrary.h"
#import "Themes.h"
@import CoreGraphics;
#import <CoreText/CoreText.h>

typedef NS_ENUM(NSInteger, PropDataOption)
{
    PDSettingDefault,
    PDSettingRank,
    PDSettingComputed,
};

typedef struct {int nMatchingProperties;
                int stability5yr,
                    stability15yr,
                    rankTotEMV,
                    pctHomestead,
                    homeOwnPct,
                    medianBuiltYear,
                    medianAgePop,
                    pctChildren,
                    pctSenior;
                }DATA_FROM_TABLES;

@class PropertyData;

@protocol PropertyDataDelegate <NSObject>

- (void)matchingOwners:(NSMutableArray *)ownerArray;

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

@interface PropertyData : NSObject

@property (nonatomic, weak) id <PropertyDataDelegate> delegate;
@property sqlite3 *database;
@property (atomic) BOOL isOpen;
@property (nonatomic, copy) NSString *documentsDirectory;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *cenfileName;
@property (nonatomic, copy) NSString *multiValueFile;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSString *cenpath;
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

- (NSMutableArray *)getPIDsMatchingAddress:(int)houseNumber
                                streetName:(NSString *)matchChar;

- (LLPOINT)getPointForPID:(NSString *)PID;
- (MNMXCORD) getBoundsForPID:(NSString*)PID;

- (int)pickPID:(LLPOINT *)pt
  highlightList:(NSMutableArray *)hlist;
- (int)pickParcel:(LLPOINT *)pt
    highlightList:(NSMutableArray*)hlist;
-(NSMutableArray *) getParcelHistory:(NSString*)PID;

- (BOOL)getAddressForPID:(NSString *)PID
         houseNumAndUnit:(NSString **)houseAndUnit
              streetName:(NSString **)streetName
                    city:(NSString **)city
             censusBlock:(NSString **)cenblock
                 useDesc:(NSString **)usedesc
                  totEMV:(CGFloat *)totEMV;

- (void)computeValuesFromTables:(DATA_FROM_TABLES *)values
                   inCensusArea:(LPSTR)cenBlockIN
                         totEMV:(int)totEMV
                        useDesc:(LPSTR) usedescIN;

- (NSString *)getOwnerNameForPID:(NSString *)PID;
+ (NSString *)getCensusBlockForPID:(NSString *)PID;
- (NSString*)getNearestPID:(CLLocationCoordinate2D*)pt;

- (void)displayParcels:(CGContextRef)context
             llCorners:(CORNERPOINTS *) latlonCornerPoints
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds
                themes:(Themes*)themes;


-(void)displayParcelText:(CGContextRef)context
               llCorners:(CORNERPOINTS *) latlonCornerPoints
                LLBounds:(MNMXCORD *)platlonBounds
              viewBounds:(MNMXCORD *)pvbounds;

- (NSMutableArray *)getReport:(PropDataOption)option
                       forPID:(NSString *)pid;

- (BOOL)getOwnersMatchingString:(NSString *)string;
- (BOOL)getDistinctUseCodes:(NSString *)outFile;

- (LPDPOINT)getParcelPolygonPointsForPID:(NSString *)PID
                               numPoints:(int *)numPoints
                                numLoops:(int *)numLoops
                             polyPartLen:(int **)polyPartLen;
-(NSArray*)getLinkedParcels:(NSString*)pid;

@end
