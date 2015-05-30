//  ConfigurationControl.h
//  GMMobile

#import <UIKit/UIKit.h>

#define MAX_LAYER_NAME 32
#define NUMHardCodedConfigs 5

typedef NS_ENUM(NSInteger, HardCodedConfigs)
{
    HCConfigAlleyWalls,
    HCConfigAlleyWallStatus,
    HCConfigCurbRamps,
    HCConfigSewers,
    HCConfigMetroProp,
};

#define NUMHardCodedLayers 5

typedef NS_ENUM(NSInteger, HardCodedLayers)
{
    HCLayerAerials,
    HCLayerParcels,
    HCLayerSewers,
    HCLayerPlanimetric,
    HCLayerAlleys,
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
@property HardCodedConfigs currentApp;
@property BOOL GMTilesVisible;

- (BOOL)setApp:(HardCodedConfigs)appID;
- (NSArray *)getLayers;
- (NSArray *)getSymbolsForLayer:(HardCodedLayers)layerID;
- (NSArray *)getLayerSymbols;
- (HardCodedLayers)layerIDforIndex:(NSInteger)index;
- (NSString *)getLayerName:(int)layerID;

- (void)setLayer:(HardCodedLayers)layerID
  visibileAtZoom:(NSInteger)zoom;

- (BOOL)layer:(HardCodedLayers)layerID
visibleAtZoom:(float)zoom;

@end