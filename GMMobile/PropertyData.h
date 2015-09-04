//  PropertyData.h
//  GMMobile

#import <sqlite3.h>
#import "CCodeLibrary/CCodeLibrary.h"
#import <CoreText/CoreText.h>

typedef NS_ENUM(NSInteger, PropDataOption)
{
    PDSettingDefault,
    PDSettingRank,
    PDSettingComputed,
};

@interface BoundaryAreaData : NSObject

@property NSString *name;
@property int refno;

@end

@interface PropertyData : NSObject 

@property sqlite3 *database;
@property (atomic) BOOL isOpen;
@property (nonatomic, copy) NSString *documentsDirectory;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *path;
@property LPTRANDATA pTranLLtoView;
@property LPTRANDATA pTranViewtoLL;
@property long long fileSize;
@property int processingID;
@property CGFloat zoom;
@property (nonatomic) int propertyDatasetVersion;
@property (nonatomic) int parcelDatasetVersion;
@property (nonatomic) int censusDatasetVersion;
@property (nonatomic) int areasDatasetVersion;
@property (nonatomic) int planDatasetVersion;

- (BOOL)open;
- (void)close:(int)method;
- (void)clear;
- (BOOL)executeCmd:(char *)cmd;
- (void)startTransaction;
- (void)commitTransaction;

- (NSMutableArray *)getPIDsMatchingString:(NSString *)matchChar;

- (NSMutableArray *)getPIDsWithOwnerMatchingString:(NSString *)matchChar
                                           limitOf:(int)lim;

- (NSMutableArray *)getPIDsMatchingAddress:(int)houseNumber
                                streetName:(NSString *)matchChar;

- (LLPOINT)getPointForPID:(NSString *)PID;
- (MNMXCORD) getBoundsForPID:(NSString*)PID;

- (int)pickPID:(LLPOINT *)pt
  highlightList:(NSMutableArray *)hlist;
- (BOOL)getAddressForPID:(NSString *)PID houseNumAndUnit:(NSString **)houseAndUnit streetName:(NSString **)streetName;

- (NSString *)getOwnerNameForPID:(NSString *)PID;
- (NSString*)getNearestPID:(CLLocationCoordinate2D*)pt;

- (void)displayParcels:(CGContextRef)context
             llCorners:(CORNERPOINTS *) latlonCornerPoints
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds;

-(void)displayParcelText:(CGContextRef)context
               llCorners:(CORNERPOINTS *) latlonCornerPoints
                LLBounds:(MNMXCORD *)platlonBounds
              viewBounds:(MNMXCORD *)pvbounds;

- (NSMutableArray *)getReport:(PropDataOption)option
                       forPID:(NSString *)pid;

- (NSMutableArray *)getOwnersMatchingString:(NSString *)string;
- (BOOL)getDistinctUseCodes:(NSString *)outFile;
- (NSMutableArray *)getBoundaryAreaTypes;
- (NSMutableArray *)getBoundaryAreaDataForType:(NSString *)type;
- (MNMXCORD) getBoundaryAreaBounds:(int)refno;

- (LPDPOINT)getParcelPolygonPointsForPID:(NSString *)PID
                               numPoints:(int *)numPoints
                                numLoops:(int *)numLoops
                             polyPartLen:(int **)polyPartLen;

@end