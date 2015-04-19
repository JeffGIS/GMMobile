//  ConfigurationControl.h
//  GMMobile

#import <Foundation/Foundation.h>
#define MAX_LAYER_NAME 32
#define NUMHardCodedConfigs 4

typedef NS_ENUM(NSInteger, HardCodedConfigs)
{
    HCConfigAlleyWalls,
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
@property int appID;

- (id)initWithNameAndID:(NSString *)name
             identifier:(int)identifier;

@end

@interface LayerObject : NSObject

@property NSString *layerName;
@property int layerID;

- (id)initWithNameAndID:(NSString *)name
             identifier:(int)identifier;

@end

@interface ConfigurationControl : NSObject

+ (ConfigurationControl *)sharedInstance;

@property NSMutableArray *appList;
@property NSMutableArray *layerList;
@property int currentApp;

- (BOOL)setApp:(HardCodedConfigs)appID;
- (NSArray *)getLayers;
- (NSArray *)getLayerSymbols;
- (NSString *)getLayerName:(int)layerID;

- (BOOL)getLayerVisibility:(int)layerID;
- (BOOL)getLayerPickability:(int)layerID;

- (BOOL)layer:(int)layerID
visibleAtZoom:(float)zoom;

@end