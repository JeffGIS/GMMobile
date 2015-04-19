//  ConfigurationControl.m
//  GMMobile

#import "ConfigurationControl.h"
#import "MapToolbar.h"
#import "AppDelegate.h"

static char layerName[NUMHardCodedLayers][MAX_LAYER_NAME]={0};
static BOOL layerVisible[NUMHardCodedLayers]={0};
static BOOL layerPickable[NUMHardCodedLayers]={0};
static float layerDefaultZoom[NUMHardCodedLayers]={0};
static BOOL configToobarSegs[NUMHardCodedConfigs][NUMMapToolbarProperty]={0};
static int  configLayers[NUMHardCodedConfigs][NUMHardCodedLayers]={0};
static float  configLayerZoom[NUMHardCodedConfigs][NUMHardCodedLayers]={0};

@implementation ApplicationObject

- (id)initWithNameAndID:(NSString *)name
             identifier:(int)identifier
{
    self = [super init];
    
    if (self)
    {
        _appName = name;
        _appID = identifier;
    }
    
    return self;
}

@end

@implementation LayerObject

- (id)initWithNameAndID:(NSString *)name
             identifier:(int)identifier
{
    self = [super init];
    
    if (self)
    {
        _layerName = name;
        _layerID = identifier;
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
        self.appList = [[NSMutableArray alloc] init];
        
        ApplicationObject *ap = [[ApplicationObject alloc] initWithNameAndID:@"Alley Wall Inventory"
                                                                  identifier:HCConfigAlleyWalls];
        
        [self.appList addObject:ap];
        
        ap = [[ApplicationObject alloc] initWithNameAndID:@"Curb Ramp Inventory"
                                               identifier:HCConfigCurbRamps];
        
        [self.appList addObject:ap];
        
        ap = [[ApplicationObject alloc] initWithNameAndID:@"Sewers"
                                               identifier:HCConfigSewers];
        
        [self.appList addObject:ap];
        
        ap = [[ApplicationObject alloc] initWithNameAndID:@"Metro Property Analysis"
                                               identifier:HCConfigMetroProp];
        
        [self.appList addObject:ap];
        self.currentApp = -1;
        
        strcpy(layerName[HCLayerAerials], "Aerial Photos");
        strcpy(layerName[HCLayerParcels], "Parcel Boundaries");
        strcpy(layerName[HCLayerSewers], "Sewer Data");
        strcpy(layerName[HCLayerPlanimetric], "Planimetric Data");
        strcpy(layerName[HCLayerAlleys], "Alleys");

        layerDefaultZoom[HCLayerAerials] = 12;
        layerDefaultZoom[HCLayerParcels] = 16;
        layerDefaultZoom[HCLayerSewers] = 17;
        layerDefaultZoom[HCLayerPlanimetric] = 18;
        layerDefaultZoom[HCLayerAlleys] = 14;
        
        //setup toolbar properties
        configToobarSegs[HCConfigSewers][MapToolbarPropertyWantDefault] = YES;
        configToobarSegs[HCConfigSewers][MapToolbarPropertyWantPlat] = YES;
        configToobarSegs[HCConfigSewers][MapToolbarPropertyWantDigitize] = NO;
        configToobarSegs[HCConfigSewers][MapToolbarPropertyWantMapType] = NO;
        configToobarSegs[HCConfigSewers][MapToolbarPropertyWantUserLocation] = YES;
        configToobarSegs[HCConfigSewers][MapToolbarPropertyWantExtents] = YES;
        configToobarSegs[HCConfigSewers][MapToolbarPropertyWantLegends] = YES;
        configToobarSegs[HCConfigSewers][MapToolbarPropertyWantMarkerSwitch] = YES;
        
        configToobarSegs[HCConfigAlleyWalls][MapToolbarPropertyWantDefault] = YES;
        configToobarSegs[HCConfigAlleyWalls][MapToolbarPropertyWantPlat] = NO;
        configToobarSegs[HCConfigAlleyWalls][MapToolbarPropertyWantDigitize] = YES;
        configToobarSegs[HCConfigAlleyWalls][MapToolbarPropertyWantMapType] = NO;
        configToobarSegs[HCConfigAlleyWalls][MapToolbarPropertyWantUserLocation] = YES;
        configToobarSegs[HCConfigAlleyWalls][MapToolbarPropertyWantExtents] = YES;
        configToobarSegs[HCConfigAlleyWalls][MapToolbarPropertyWantLegends] = YES;
        configToobarSegs[HCConfigAlleyWalls][MapToolbarPropertyWantMarkerSwitch] = YES;
        
        configToobarSegs[HCConfigCurbRamps][MapToolbarPropertyWantDefault] = YES;
        configToobarSegs[HCConfigCurbRamps][MapToolbarPropertyWantPlat] = NO;
        configToobarSegs[HCConfigCurbRamps][MapToolbarPropertyWantDigitize] = NO;
        configToobarSegs[HCConfigCurbRamps][MapToolbarPropertyWantMapType] = NO;
        configToobarSegs[HCConfigCurbRamps][MapToolbarPropertyWantUserLocation] = YES;
        configToobarSegs[HCConfigCurbRamps][MapToolbarPropertyWantExtents] = YES;
        configToobarSegs[HCConfigCurbRamps][MapToolbarPropertyWantLegends] = YES;
        configToobarSegs[HCConfigCurbRamps][MapToolbarPropertyWantMarkerSwitch] = YES;
        
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantDefault] = YES;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantPlat] = NO;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantDigitize] = NO;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantMapType] = YES;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantUserLocation] = YES;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantExtents] = YES;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantLegends] = YES;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantMarkerSwitch] = YES;
        
        //setup layers
        configLayers[HCConfigSewers][HCLayerAerials] = YES;
        configLayers[HCConfigSewers][HCLayerParcels] = YES;
        configLayers[HCConfigSewers][HCLayerSewers] = YES;
        configLayers[HCConfigSewers][HCLayerPlanimetric] = NO;
        configLayers[HCConfigSewers][HCLayerAlleys] = NO;
        
        configLayers[HCConfigAlleyWalls][HCLayerAerials] = YES;
        configLayers[HCConfigAlleyWalls][HCLayerParcels] = YES;
        configLayers[HCConfigAlleyWalls][HCLayerSewers] = NO;
        configLayers[HCConfigAlleyWalls][HCLayerPlanimetric] = YES;
        configLayers[HCConfigAlleyWalls][HCLayerAlleys] = YES;
        
        configLayers[HCConfigCurbRamps][HCLayerAerials] = YES;
        configLayers[HCConfigCurbRamps][HCLayerParcels] = YES;
        configLayers[HCConfigCurbRamps][HCLayerSewers] = NO;
        configLayers[HCConfigCurbRamps][HCLayerPlanimetric] = NO;
        configLayers[HCConfigCurbRamps][HCLayerAlleys] = NO;
        
        configLayers[HCConfigMetroProp][HCLayerAerials] = NO;
        configLayers[HCConfigMetroProp][HCLayerParcels] = YES;
        configLayers[HCConfigMetroProp][HCLayerSewers] = NO;
        configLayers[HCConfigMetroProp][HCLayerPlanimetric] = NO;
        configLayers[HCConfigMetroProp][HCLayerAlleys] = NO;
        
        for (int config = 0; config < NUMHardCodedConfigs; config++)
        {
            for (int layer = 0; layer < NUMHardCodedLayers; layer++)
                configLayerZoom[config][layer] = layerDefaultZoom[layer];
        }
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

- (BOOL)setApp:(HardCodedConfigs)appID
{
    BOOL rtn = YES;
    AppDelegate *sharedAppDelegate = UIApplication.sharedApplication.delegate;
    MapToolbar *tb = sharedAppDelegate.mapToolbar;
   
    _currentApp = appID;
    
    for (int prop = 0; prop < NUMMapToolbarProperty; prop++)
    {
        [tb setConfigurationProperty:prop
                               value:configToobarSegs[_currentApp][prop]];
    }
    
    _layerList = [[NSMutableArray alloc]init];
    [UserDefaults.defaults saveInteger:appID
                                forKey:@"CurrentConfig"];
    return rtn;
}

- (void)setup
{
    if (_currentApp < 0)
        [self setApp:HCConfigMetroProp];
}
- (NSString *)getLayerName:(int)layerID
{
    NSString *name = [NSString stringWithUTF8String:layerName[layerID]];
    return name;
}

- (NSArray *)getLayers
{
    NSMutableArray *layers = [[NSMutableArray alloc] init];
    
    [self setup];
    return layers;
}

- (BOOL)layer:(int)layerID
visibleAtZoom:(float)zoom
{
    [self setup];
    
    if (configLayers[_currentApp][layerID] &&
        zoom >= configLayerZoom[_currentApp][layerID])
    {
        return YES;
    }
    
    return NO;
}

- (NSArray *)getLayerSymbols
{
    NSArray *layerSymbols = nil;
    return layerSymbols;
}

- (BOOL)getLayerVisibility:(int)layerID;
{
    return NO;
}

- (BOOL)getLayerPickability:(int)layerID;
{
    return NO;
}

@end