//
//  ConfigurationControl.h
//  GMMobile
//
//  Created by JEFFREY E SMITH on 4/18/15.
//  Copyright (c) 2015 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>
#define MAX_LAYER_NAME  32
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
@property NSString * appName;
@property int appID;
- (id) initWithNameAndID:(NSString*)name id:(int)id;
@end

@interface LayerObject : NSObject
@property NSString * layerName;
@property int layerID;
- (id) initWithNameAndID:(NSString*)name id:(int)id;
@end

@interface ConfigurationControl : NSObject

+ (ConfigurationControl *)sharedInstance;

@property NSMutableArray * appList;
@property NSMutableArray * layerList;
@property int currentApp;

- (BOOL) setApp:(int)appID;
- (NSArray*) getLayers;
- (NSArray*) getLayerSymbols;
- (NSString*) getLayerName:(int)layerID;

- (BOOL) getLayerVisibility:(int)layerID;
- (BOOL) getLayerPickability:(int)layerID;

- (BOOL) layer:(int)layerID visibleAtZoom:(float)zoom;

@end
