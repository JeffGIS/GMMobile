//  BoundaryData.h
//  GMMobile

#import "CCodeLibrary/SQLiteLib.h"
#import "CCodeLibrary/CCodeLibrary.h"
#import "Themes.h"
#import "NVMetroSettings.h"

typedef NS_ENUM(NSInteger, TextFromOption)
{
    TFOSelectBoundary,
    TFOCrime,
    TFONVMetroDisplay,
};


@interface BoundaryAreaData : NSObject

@property NSString *name;
@property int refno;

@end

@interface BoundaryData : NSObject
@property int processingID;
@property sqlite3 *database;
@property (atomic) BOOL isOpen;
@property (nonatomic, copy) NSString *documentsDirectory;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *cenfileName;
@property (nonatomic, copy) NSString *propfileName;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSString *cenpath;
@property (nonatomic, copy) NSString *proppath;
@property NSInteger fileSize;
@property (nonatomic) int datasetVersion;
@property int zoom;
@property ItemProcessingPassTypes pass;

- (BOOL)open;
- (void)close:(BOOL)opened;
- (void)startTransaction;
- (void)commitTransaction;
- (BOOL)executeCmd:(char *)cmd;

- (NSMutableArray *)getBoundaryAreaTypes;
- (NSMutableArray *)getBoundaryAreaDataForType:(NSString *)type;
- (MNMXCORD) getBoundaryAreaBounds:(long long)refno
                            ofType:(NSString*)type;

-(void)displayBoundary:(int)refno
                ofType:(NSString*)areaType
                asMask:(CGFloat)mask
             inContext:(CGContextRef)context
             llCorners:(CORNERPOINTS *) latlonCornerPoints
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds;

-(void)displayCircularBoundaryAt:(LLPOINT)pt
                      withRadius:(double)radius
                       lineWidth:(CGFloat)lineWidth
                          asMask:(CGFloat)mask
                       inContext:(CGContextRef)context
                       llCorners:(CORNERPOINTS *) latlonCornerPoints
                        LLBounds:(MNMXCORD *)platlonBounds
                      viewBounds:(MNMXCORD *)pvbounds;

-(void) displayLandUse:(CGContextRef)context
             llCorners:(CORNERPOINTS *) latlonCornerPoints
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds
displayCharacteristics:(DisplayCharacteristics *)dc
                themes:(Themes*)themes
           pointInArea:(PointInArea *)pia;

-(void)displayCensusAreas:(CGContextRef)context
                     type:(NSString *)type
   displayCharacteristics:(DisplayCharacteristics*)dc
                llCorners:(CORNERPOINTS *) latlonCornerPoints
                 LLBounds:(MNMXCORD *)platlonBounds
               viewBounds:(MNMXCORD *)pvbounds
                   themes:(Themes*)themes
              pointInArea:(PointInArea *)pia;
- (LPDPOINT)getPolygonPointsForBoundary:(int)refno
                              numPoints:(int *)numPoints
                               numLoops:(int *)numLoops
                            polyPartLen:(int **)polyPartLen;
- (int)       load:(NSString*)areaType
    toPointInAreas:(PointInAreas*)pias
boundsPointInAreas:(PointInAreas*)pias
  usingPointInArea:(PointInArea*)pia
         llCorners:(CORNERPOINTS *) latlonCornerPoints
          LLBounds:(MNMXCORD *)platlonBounds
        viewBounds:(MNMXCORD *)pvbounds;

- (int) display:(CGContextRef)context
       areaType:(NSString*)areaType
   pointInAreas:(PointInAreas*)pias
      llCorners:(CORNERPOINTS *) latlonCornerPoints
       LLBounds:(MNMXCORD *)platlonBounds
     viewBounds:(MNMXCORD *)pvbounds;

- (int) displayText:(CGContextRef)context
               from:(TextFromOption)from
           areaType:(NSString*)areaType
        textOptions:(NVMetroTextOptions*)textOptions
       pointInAreas:(PointInAreas*)pias
          llCorners:(CORNERPOINTS *) latlonCornerPoints
           LLBounds:(MNMXCORD *)platlonBounds
         viewBounds:(MNMXCORD *)pvbounds;
- (MNMXCORD) selectBoundaryFromMapInit:(NSString*)type;
- (PickedItem *)pickBoundaryArea:(LLPOINT)point
                            type:(NSString*)areaType;
+ (int)getBoundaryAreaRefnoForType:(NSString *)type
                           andName:(NSString *)name;

- (void) setCityAndCounty;

@end
