//
//  ConfigurationControl.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 4/18/15.
//  Copyright (c) 2015 GSSi. All rights reserved.
//

#import "ConfigurationControl.h"
#import "MapToolbar.h"
#import "AppDelegate.h"

static char layerName[sizeof(HardCodedLayers)][MAX_LAYER_NAME]={0};
static BOOL layerVisible[sizeof(HardCodedLayers)]={0};
static BOOL layerPickable[sizeof(HardCodedLayers)]={0};
static BOOL configToobarSegs[sizeof(HardCodedConfigs)][sizeof(MapToolbarProperty)]={0};

@implementation ApplicationObject
- (id) initWithNameAndID:(NSString*)name id:(int)id
{
    self = [super init];
    if (self)
    {
        self.appName = name;
        self.appID = id;
    }
    return self;
}
@end

@interface ConfigurationControl ()
@property BOOL firstCall;
@end

@implementation ConfigurationControl

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.firstCall = YES;
        self.apList = [[NSMutableArray alloc]init];
        ApplicationObject * ap = [[ApplicationObject alloc]initWithNameAndID:@"Alley Wall Inventory" id:HCConfigAlleyWalls];
        [self.apList addObject:ap];
        ap = [[ApplicationObject alloc]initWithNameAndID:@"Curb Ramp Inventory" id:HCConfigCurbRamps];
        [self.apList addObject:ap];
        ap = [[ApplicationObject alloc]initWithNameAndID:@"Sewers" id:HCConfigSewers];
        [self.apList addObject:ap];
        ap = [[ApplicationObject alloc]initWithNameAndID:@"Metro Property Analysis" id:HCConfigMetroProp];
        [self.apList addObject:ap];
        self.currentApp = -1;
        
        strcpy (layerName[HCLayerAerials],"Aerial Photos");
        strcpy (layerName[HCLayerParcels],"Parcel Boundaries");
        strcpy (layerName[HCLayerSewers],"Sewer Data");
        strcpy (layerName[HCLayerPlanimetric],"Planimetric Data");
        strcpy (layerName[HCLayerAlleys],"Alleys");
        
        configToobarSegs[HCConfigSewers][MapToolbarPropertyWantDefault]=YES;
        configToobarSegs[HCConfigSewers][MapToolbarPropertyWantPlat]=YES;
        configToobarSegs[HCConfigSewers][MapToolbarPropertyWantDigitize]=NO;
        configToobarSegs[HCConfigSewers][MapToolbarPropertyWantMapType]=NO;
        configToobarSegs[HCConfigSewers][MapToolbarPropertyWantUserLocation]=YES;
        configToobarSegs[HCConfigSewers][MapToolbarPropertyWantExtents]=YES;
        configToobarSegs[HCConfigSewers][MapToolbarPropertyWantLegends]=YES;
        configToobarSegs[HCConfigSewers][MapToolbarPropertyWantMarkerSwitch]=YES;
        
        configToobarSegs[HCConfigAlleyWalls][MapToolbarPropertyWantDefault]=YES;
        configToobarSegs[HCConfigAlleyWalls][MapToolbarPropertyWantPlat]=NO;
        configToobarSegs[HCConfigAlleyWalls][MapToolbarPropertyWantDigitize]=YES;
        configToobarSegs[HCConfigAlleyWalls][MapToolbarPropertyWantMapType]=NO;
        configToobarSegs[HCConfigAlleyWalls][MapToolbarPropertyWantUserLocation]=YES;
        configToobarSegs[HCConfigAlleyWalls][MapToolbarPropertyWantExtents]=YES;
        configToobarSegs[HCConfigAlleyWalls][MapToolbarPropertyWantLegends]=YES;
        configToobarSegs[HCConfigAlleyWalls][MapToolbarPropertyWantMarkerSwitch]=YES;
        
        configToobarSegs[HCConfigCurbRamps][MapToolbarPropertyWantDefault]=YES;
        configToobarSegs[HCConfigCurbRamps][MapToolbarPropertyWantPlat]=NO;
        configToobarSegs[HCConfigCurbRamps][MapToolbarPropertyWantDigitize]=NO;
        configToobarSegs[HCConfigCurbRamps][MapToolbarPropertyWantMapType]=NO;
        configToobarSegs[HCConfigCurbRamps][MapToolbarPropertyWantUserLocation]=YES;
        configToobarSegs[HCConfigCurbRamps][MapToolbarPropertyWantExtents]=YES;
        configToobarSegs[HCConfigCurbRamps][MapToolbarPropertyWantLegends]=YES;
        configToobarSegs[HCConfigCurbRamps][MapToolbarPropertyWantMarkerSwitch]=YES;
        
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantDefault]=YES;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantPlat]=NO;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantDigitize]=NO;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantMapType]=YES;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantUserLocation]=YES;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantExtents]=YES;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantLegends]=YES;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantMarkerSwitch]=YES;
        
    }
    
    return self;
}

+ (ConfigurationControl *)sharedInstance
{
    static ConfigurationControl *sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate,
                  ^{
                      sharedInstance = [[ConfigurationControl alloc] init];
                  });
    
    return sharedInstance;
}

- (BOOL) setApp:(int)appID
{
    BOOL rtn = TRUE;
    AppDelegate *sharedAppDelegate = UIApplication.sharedApplication.delegate;
    MapToolbar * tb = sharedAppDelegate.mapToolbar;
   
    _currentApp = appID;
    
    for (int prop = 0;prop<sizeof(MapToolbarProperty);prop++)
        [tb setConfigurationProperty:prop value:configToobarSegs[_currentApp][prop]];

    
    return rtn;
}

- (NSString*) getLayerName:(int)layerID
{
    NSString * name = [NSString stringWithUTF8String:layerName[layerID]];
    return name;
}
@end
