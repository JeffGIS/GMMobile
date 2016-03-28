//  ConfigurationControl.h
//  GMMobile

#import <UIKit/UIKit.h>
#import "CCodeLibrary/DisplayCharacteristics.h"
#import "Theme.h"

#define MAX_LAYER_NAME 32
#define NUMHardCodedConfigs 7

typedef NS_ENUM(NSInteger, AdjustCrimeOptions)
{
    None,
    Population,
    HousingUnits,
};

typedef NS_ENUM(NSInteger, HardCodedConfigs)
{
    HCConfigAlleyWalls,
    HCConfigAlleyWallStatus,
    HCConfigCurbRamps,
    HCConfigSewers,
    HCConfigMetroProp,
    HCConfigCrimes,
    HCConfigMapleGrove,
    HCConfigPropListMapit,
};

#define NUMHardCodedLayers 9

typedef NS_ENUM(NSInteger, HardCodedLayers)
{
    HCLayerAerials,
    HCLayerParcels,
    HCLayerSewers,
    HCLayerPlanimetric,
    HCLayerAlleys,
    HCLayerCurbRamps,
    HCLayerCrimes,
    HCLayerMapleGroveWater,
    HCLayerMapleGroveFiber,
};

typedef NS_ENUM(NSInteger, PropSheetValues)
{
    PSValNone,
    PSValPCTIndustrial,
    PSValPCTCommercial,
    PSValPCTResidential,
    PSValOpenSpace,
    PSValWater,
};


@interface ApplicationObject : NSObject

@property NSString *appName;
@property HardCodedConfigs appID;

- (id)initWithNameAndID:(NSString *)name
             identifier:(int)identifier;

@end

@interface LayerObject : NSObject

@property NSString *layerName;
@property int layerID;
@property BOOL hasSymbols, stepperEnabled;
@property NSInteger segControlIndex, zoomLevel;
@property UIColor *cellButtonColor;

- (id)initWithName:(NSString *)name
             andID:(int)identifier;

@end

@interface ConfigurationControl : NSObject

+ (ConfigurationControl *)sharedInstance;

@property NSMutableArray *appList;
@property NSMutableArray *legendList;
@property HardCodedConfigs legendApp;
@property HardCodedConfigs currentApp;
@property PropSheetValues currentPropSheetValue;
@property BOOL GMTilesVisible;
@property BOOL wantAllCrimes;
@property AdjustCrimeOptions  adjustCrimeOption;
@property NSString* adjustCrimeArea;
- (BOOL)setApp:(HardCodedConfigs)appID;
- (NSArray *)getLayers;
- (NSMutableArray *) getDatasetsForApp:(HardCodedConfigs)appID;
- (NSArray *)getSymbolsForLayer:(HardCodedLayers)layerID;
- (NSArray *)getLayerSymbols;
- (HardCodedLayers)layerIDforIndex:(NSInteger)index;
- (NSString *)getLayerName:(int)layerID;
- (BOOL)layerInConfig:(HardCodedLayers)layerID;
- (BOOL)haveUserAerials;
- (BOOL)useMapTypeControl;

- (void)setLayer:(HardCodedLayers)layerID
  visibileAtZoom:(NSInteger)zoom;

- (BOOL)layer:(HardCodedLayers)layerID
visibleAtZoom:(CGFloat)zoom
      andPass:(ItemProcessingPassTypes)passID;
+(NSString*) getAdjustValueString:(AdjustCrimeOptions)opt;



@end