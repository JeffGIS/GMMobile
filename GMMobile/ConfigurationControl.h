//  ConfigurationControl.h
//  GMMobile

#import <UIKit/UIKit.h>
#import "CCodeLibrary/DisplayCharacteristics.h"
#import "Theme.h"

#define MAX_LAYER_NAME 32
#define NUMHardCodedConfigs 6

typedef NS_ENUM(NSInteger, GetDatabaseSetting)
{
    GetDatabaseSettingDefault,
    GetDatabaseSettingProperty,
    GetDatabaseSettingTiles,
    GetDatabaseSettingParcels,
    GetDatabaseSettingAreas,
    GetDatabaseSettingSewer,
    GetDatabaseSettingPlan,
    GetDatabaseSettingCensus,
    GetDatabaseSettingAlleyWall,
    GetDatabaseSettingCurbRamp,
    GetDatabaseSettingCrimes,
};

typedef NS_ENUM(NSInteger, HardCodedConfigs)
{
    HCConfigAlleyWalls,
    HCConfigAlleyWallStatus,
    HCConfigCurbRamps,
    HCConfigSewers,
    HCConfigMetroProp,
    HCConfigCrimes,
};

#define NUMHardCodedLayers 7

typedef NS_ENUM(NSInteger, HardCodedLayers)
{
    HCLayerAerials,
    HCLayerParcels,
    HCLayerSewers,
    HCLayerPlanimetric,
    HCLayerAlleys,
    HCLayerCurbRamps,
    HCLayerCrimes,
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
@property HardCodedConfigs currentApp;
@property BOOL GMTilesVisible;

- (BOOL)setApp:(HardCodedConfigs)appID;
- (NSArray *)getLayers;
- (NSMutableArray *) getDatasetsForApp:(HardCodedConfigs)appID;
- (NSArray *)getSymbolsForLayer:(HardCodedLayers)layerID;
- (NSArray *)getLayerSymbols;
- (HardCodedLayers)layerIDforIndex:(NSInteger)index;
- (NSString *)getLayerName:(int)layerID;
- (BOOL)layerInConfig:(HardCodedLayers)layerID;

- (void)setLayer:(HardCodedLayers)layerID
  visibileAtZoom:(NSInteger)zoom;

- (BOOL)layer:(HardCodedLayers)layerID
visibleAtZoom:(CGFloat)zoom
      andPass:(ItemProcessingPassTypes)passID;


@end