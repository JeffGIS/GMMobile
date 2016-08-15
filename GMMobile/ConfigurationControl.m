//  ConfigurationControl.m
//  GMMobile

#import "ConfigurationControl.h"
#import "CCodeLibrary/MapToolbar.h"
#import "AppDelegate.h"
#import "PlanimetricData.h"
#import "CCodeLibrary/FTPDataPull.h"

static char layerName[NUMHardCodedLayers][MAX_LAYER_NAME]={0};
//static BOOL layerVisible[NUMHardCodedLayers]={0};
//static BOOL layerPickable[NUMHardCodedLayers]={0};
static CGFloat layerDefaultZoom[NUMHardCodedLayers]={0};
static BOOL layerHasSymbols[NUMHardCodedLayers]={0};
static BOOL userAerials[NUMHardCodedConfigs]={0};
static BOOL configToobarSegs[NUMHardCodedConfigs][NUMMapToolbarProperty]={0};
static int  configLayers[NUMHardCodedConfigs][NUMHardCodedLayers]={0};
static CGFloat  configLayerZoom[NUMHardCodedConfigs][NUMHardCodedLayers]={0};

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

- (id)initWithName:(NSString *)name
             andID:(int)identifier
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
{
    NSMutableArray* symLists[NUMHardCodedConfigs][NUMHardCodedLayers];
}

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
        
        ap = [[ApplicationObject alloc] initWithNameAndID:@"Alley Wall Status"
                                               identifier:HCConfigAlleyWallStatus];
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
        
        ap = [[ApplicationObject alloc] initWithNameAndID:@"Minneapolis Crime Data"
                                               identifier:HCConfigCrimes];
        
        [self.appList addObject:ap];
        ap = [[ApplicationObject alloc] initWithNameAndID:@"Maple Grove App"
                                               identifier:HCConfigMapleGrove];
        
        [self.appList addObject:ap];
        self.currentApp = -1;
        
        strcpy(layerName[HCLayerAerials], "Aerial Photos");
        strcpy(layerName[HCLayerParcels], "Parcel Boundaries");
        strcpy(layerName[HCLayerSewers], "Sewer Data");
        strcpy(layerName[HCLayerPlanimetric], "Planimetric Data");
        strcpy(layerName[HCLayerAlleys], "Alleys");
        strcpy(layerName[HCLayerCurbRamps], "Curb Ramps");
        strcpy(layerName[HCLayerCrimes], "Crimes");
        strcpy(layerName[HCLayerMapleGroveWater], "Water");
        strcpy(layerName[HCLayerMapleGroveFiber], "Fiber");

        layerDefaultZoom[HCLayerAerials] = 12;
        layerDefaultZoom[HCLayerParcels] = 16;
        layerDefaultZoom[HCLayerSewers] = 17;
        layerDefaultZoom[HCLayerPlanimetric] = 18;
        layerDefaultZoom[HCLayerAlleys] = 14;
        layerDefaultZoom[HCLayerAlleys] = 13;
        layerDefaultZoom[HCLayerCrimes] = 8;
        layerDefaultZoom[HCLayerMapleGroveFiber] = 11;
        layerDefaultZoom[HCLayerMapleGroveWater] = 11;
        
        layerHasSymbols[HCLayerAerials] = NO;
        layerHasSymbols[HCLayerParcels] = NO;
        layerHasSymbols[HCLayerSewers] = YES;
        layerHasSymbols[HCLayerPlanimetric] = YES;
        layerHasSymbols[HCLayerAlleys] = YES;
        layerHasSymbols[HCLayerCrimes] = NO;
        layerHasSymbols[HCLayerMapleGroveWater] = NO;
        layerHasSymbols[HCLayerMapleGroveFiber] = NO;
        
        //setup toolbar properties
        configToobarSegs[HCConfigSewers][MapToolbarPropertyWantPlat] = YES;
        configToobarSegs[HCConfigSewers][MapToolbarPropertyWantDigitize] = NO;
        configToobarSegs[HCConfigSewers][MapToolbarPropertyWantMapType] = NO;
        configToobarSegs[HCConfigSewers][MapToolbarPropertyWantUserLocation] = YES;
        configToobarSegs[HCConfigSewers][MapToolbarPropertyWantExtents] = YES;
        configToobarSegs[HCConfigSewers][MapToolbarPropertyWantLegends] = NO;
        configToobarSegs[HCConfigSewers][MapToolbarPropertyWantGrayscale] = YES;
        configToobarSegs[HCConfigSewers][MapToolbarPropertyWantClearMarkers] = YES;
        configToobarSegs[HCConfigSewers][MapToolbarPropertyWantEmailPDF] = YES;
        configToobarSegs[HCConfigSewers][MapToolbarPropertyWantProgressBar] = YES;
        configToobarSegs[HCConfigSewers][MapToolbarPropertyWantHelpButton] = YES;
        configToobarSegs[HCConfigSewers][MapToolbarPropertyWantReturnButton] = NO;
        
        configToobarSegs[HCConfigAlleyWalls][MapToolbarPropertyWantPlat] = NO;
        configToobarSegs[HCConfigAlleyWalls][MapToolbarPropertyWantDigitize] = YES;
        configToobarSegs[HCConfigAlleyWalls][MapToolbarPropertyWantMapType] = NO;
        configToobarSegs[HCConfigAlleyWalls][MapToolbarPropertyWantUserLocation] = YES;
        configToobarSegs[HCConfigAlleyWalls][MapToolbarPropertyWantExtents] = YES;
        configToobarSegs[HCConfigAlleyWalls][MapToolbarPropertyWantLegends] = NO;
        configToobarSegs[HCConfigAlleyWalls][MapToolbarPropertyWantGrayscale] = YES;
        configToobarSegs[HCConfigAlleyWalls][MapToolbarPropertyWantClearMarkers] = YES;
        configToobarSegs[HCConfigAlleyWalls][MapToolbarPropertyWantEmailPDF] = YES;
        configToobarSegs[HCConfigAlleyWalls][MapToolbarPropertyWantProgressBar] = YES;
        configToobarSegs[HCConfigAlleyWalls][MapToolbarPropertyWantHelpButton] = YES;
        configToobarSegs[HCConfigAlleyWalls][MapToolbarPropertyWantReturnButton] = NO;
        
        configToobarSegs[HCConfigAlleyWallStatus][MapToolbarPropertyWantPlat] = NO;
        configToobarSegs[HCConfigAlleyWallStatus][MapToolbarPropertyWantDigitize] = YES;
        configToobarSegs[HCConfigAlleyWallStatus][MapToolbarPropertyWantMapType] = NO;
        configToobarSegs[HCConfigAlleyWallStatus][MapToolbarPropertyWantUserLocation] = YES;
        configToobarSegs[HCConfigAlleyWallStatus][MapToolbarPropertyWantExtents] = YES;
        configToobarSegs[HCConfigAlleyWallStatus][MapToolbarPropertyWantLegends] = NO;
        configToobarSegs[HCConfigAlleyWallStatus][MapToolbarPropertyWantGrayscale] = YES;
        configToobarSegs[HCConfigAlleyWallStatus][MapToolbarPropertyWantClearMarkers] = YES;
        configToobarSegs[HCConfigAlleyWallStatus][MapToolbarPropertyWantEmailPDF] = YES;
        configToobarSegs[HCConfigAlleyWallStatus][MapToolbarPropertyWantProgressBar] = YES;
        configToobarSegs[HCConfigAlleyWallStatus][MapToolbarPropertyWantHelpButton] = YES;
        configToobarSegs[HCConfigAlleyWallStatus][MapToolbarPropertyWantReturnButton] = NO;
        
        configToobarSegs[HCConfigCurbRamps][MapToolbarPropertyWantPlat] = NO;
        configToobarSegs[HCConfigCurbRamps][MapToolbarPropertyWantDigitize] = YES;
        configToobarSegs[HCConfigCurbRamps][MapToolbarPropertyWantMapType] = NO;
        configToobarSegs[HCConfigCurbRamps][MapToolbarPropertyWantUserLocation] = YES;
        configToobarSegs[HCConfigCurbRamps][MapToolbarPropertyWantExtents] = YES;
        configToobarSegs[HCConfigCurbRamps][MapToolbarPropertyWantLegends] = NO;
        configToobarSegs[HCConfigCurbRamps][MapToolbarPropertyWantGrayscale] = YES;
        configToobarSegs[HCConfigCurbRamps][MapToolbarPropertyWantClearMarkers] = YES;
        configToobarSegs[HCConfigCurbRamps][MapToolbarPropertyWantEmailPDF] = YES;
        configToobarSegs[HCConfigCurbRamps][MapToolbarPropertyWantProgressBar] = YES;
        configToobarSegs[HCConfigCurbRamps][MapToolbarPropertyWantHelpButton] = YES;
        configToobarSegs[HCConfigCurbRamps][MapToolbarPropertyWantReturnButton] = NO;
        
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantPlat] = NO;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantDigitize] = YES;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantMapType] = YES;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantUserLocation] = YES;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantExtents] = YES;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantLegends] = YES;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantGrayscale] = YES;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantClearMarkers] = YES;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantEmailPDF] = YES;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantProgressBar] = YES;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantHelpButton] = YES;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantReturnButton] = NO;
        
        configToobarSegs[HCConfigFromSpreadsheet][MapToolbarPropertyWantPlat] = NO;
        configToobarSegs[HCConfigFromSpreadsheet][MapToolbarPropertyWantDigitize] = NO;
        configToobarSegs[HCConfigFromSpreadsheet][MapToolbarPropertyWantMapType] = NO;
        configToobarSegs[HCConfigFromSpreadsheet][MapToolbarPropertyWantUserLocation] = NO;
        configToobarSegs[HCConfigFromSpreadsheet][MapToolbarPropertyWantExtents] = YES;
        configToobarSegs[HCConfigFromSpreadsheet][MapToolbarPropertyWantLegends] = NO;
        configToobarSegs[HCConfigFromSpreadsheet][MapToolbarPropertyWantGrayscale] = YES;
        configToobarSegs[HCConfigFromSpreadsheet][MapToolbarPropertyWantClearMarkers] = NO;
        configToobarSegs[HCConfigFromSpreadsheet][MapToolbarPropertyWantEmailPDF] = YES;
        configToobarSegs[HCConfigFromSpreadsheet][MapToolbarPropertyWantProgressBar] = YES;
        configToobarSegs[HCConfigFromSpreadsheet][MapToolbarPropertyWantHelpButton] = YES;
        configToobarSegs[HCConfigFromSpreadsheet][MapToolbarPropertyWantReturnButton] = YES;
        
        configToobarSegs[HCConfigCrimes][MapToolbarPropertyWantPlat] = NO;
        configToobarSegs[HCConfigCrimes][MapToolbarPropertyWantDigitize] = NO;
        configToobarSegs[HCConfigCrimes][MapToolbarPropertyWantMapType] = NO;
        configToobarSegs[HCConfigCrimes][MapToolbarPropertyWantUserLocation] = YES;
        configToobarSegs[HCConfigCrimes][MapToolbarPropertyWantExtents] = YES;
        configToobarSegs[HCConfigCrimes][MapToolbarPropertyWantLegends] = NO;
        configToobarSegs[HCConfigCrimes][MapToolbarPropertyWantGrayscale] = YES;
        configToobarSegs[HCConfigCrimes][MapToolbarPropertyWantClearMarkers] = YES;
        configToobarSegs[HCConfigCrimes][MapToolbarPropertyWantEmailPDF] = YES;
        configToobarSegs[HCConfigCrimes][MapToolbarPropertyWantProgressBar] = YES;
        configToobarSegs[HCConfigCrimes][MapToolbarPropertyWantHelpButton] = YES;
        configToobarSegs[HCConfigCrimes][MapToolbarPropertyWantReturnButton] = NO;
        
        configToobarSegs[HCConfigMapleGrove][MapToolbarPropertyWantPlat] = YES;
        configToobarSegs[HCConfigMapleGrove][MapToolbarPropertyWantDigitize] = NO;
        configToobarSegs[HCConfigMapleGrove][MapToolbarPropertyWantMapType] = NO;
        configToobarSegs[HCConfigMapleGrove][MapToolbarPropertyWantUserLocation] = YES;
        configToobarSegs[HCConfigMapleGrove][MapToolbarPropertyWantExtents] = YES;
        configToobarSegs[HCConfigMapleGrove][MapToolbarPropertyWantLegends] = NO;
        configToobarSegs[HCConfigMapleGrove][MapToolbarPropertyWantGrayscale] = YES;
        configToobarSegs[HCConfigMapleGrove][MapToolbarPropertyWantClearMarkers] = YES;
        configToobarSegs[HCConfigMapleGrove][MapToolbarPropertyWantEmailPDF] = YES;
        configToobarSegs[HCConfigMapleGrove][MapToolbarPropertyWantProgressBar] = YES;
        configToobarSegs[HCConfigMapleGrove][MapToolbarPropertyWantHelpButton] = YES;
        configToobarSegs[HCConfigMapleGrove][MapToolbarPropertyWantReturnButton] = NO;
        
        //setup layers
        configLayers[HCConfigSewers][HCLayerAerials] = YES;
        configLayers[HCConfigSewers][HCLayerParcels] = YES;
        configLayers[HCConfigSewers][HCLayerSewers] = YES;
        configLayers[HCConfigSewers][HCLayerPlanimetric] = NO;
        configLayers[HCConfigSewers][HCLayerAlleys] = NO;
        configLayers[HCConfigSewers][HCLayerCurbRamps] = NO;
        
        configLayers[HCConfigAlleyWalls][HCLayerAerials] = YES;
        configLayers[HCConfigAlleyWalls][HCLayerParcels] = YES;
        configLayers[HCConfigAlleyWalls][HCLayerSewers] = NO;
        configLayers[HCConfigAlleyWalls][HCLayerPlanimetric] = YES;
        configLayers[HCConfigAlleyWalls][HCLayerAlleys] = YES;
        configLayers[HCConfigAlleyWalls][HCLayerCurbRamps] = NO;
       
        configLayers[HCConfigAlleyWallStatus][HCLayerAerials] = NO;
        configLayers[HCConfigAlleyWallStatus][HCLayerParcels] = NO;
        configLayers[HCConfigAlleyWallStatus][HCLayerSewers] = NO;
        configLayers[HCConfigAlleyWallStatus][HCLayerPlanimetric] = NO;
        configLayers[HCConfigAlleyWallStatus][HCLayerAlleys] = YES;
        configLayers[HCConfigAlleyWallStatus][HCLayerCurbRamps] = NO;
        
        configLayers[HCConfigCurbRamps][HCLayerAerials] = YES;
        configLayers[HCConfigCurbRamps][HCLayerParcels] = NO;
        configLayers[HCConfigCurbRamps][HCLayerSewers] = NO;
        configLayers[HCConfigCurbRamps][HCLayerPlanimetric] = NO;
        configLayers[HCConfigCurbRamps][HCLayerAlleys] = NO;
        configLayers[HCConfigCurbRamps][HCLayerCurbRamps] = YES;
        
        configLayers[HCConfigMetroProp][HCLayerAerials] = NO;
        configLayers[HCConfigMetroProp][HCLayerParcels] = YES;
        configLayers[HCConfigMetroProp][HCLayerSewers] = NO;
        configLayers[HCConfigMetroProp][HCLayerPlanimetric] = NO;
        configLayers[HCConfigMetroProp][HCLayerAlleys] = NO;
        configLayers[HCConfigMetroProp][HCLayerCurbRamps] = NO;
        
        configLayers[HCConfigFromSpreadsheet][HCLayerAerials] = NO;
        configLayers[HCConfigFromSpreadsheet][HCLayerParcels] = YES;
        configLayers[HCConfigFromSpreadsheet][HCLayerSewers] = NO;
        configLayers[HCConfigFromSpreadsheet][HCLayerPlanimetric] = NO;
        configLayers[HCConfigFromSpreadsheet][HCLayerAlleys] = NO;
        configLayers[HCConfigFromSpreadsheet][HCLayerCurbRamps] = NO;
        
        configLayers[HCConfigCrimes][HCLayerAerials] = YES;
        configLayers[HCConfigCrimes][HCLayerParcels] = YES;
        configLayers[HCConfigCrimes][HCLayerSewers] = NO;
        configLayers[HCConfigCrimes][HCLayerPlanimetric] = NO;
        configLayers[HCConfigCrimes][HCLayerAlleys] = NO;
        configLayers[HCConfigCrimes][HCLayerCurbRamps] = NO;
        configLayers[HCConfigCrimes][HCLayerCrimes] = YES;
        
        configLayers[HCConfigMapleGrove][HCLayerAerials] = YES;
        configLayers[HCConfigMapleGrove][HCLayerParcels] = YES;
        configLayers[HCConfigMapleGrove][HCLayerSewers] = YES;
        configLayers[HCConfigMapleGrove][HCLayerPlanimetric] = NO;
        configLayers[HCConfigMapleGrove][HCLayerAlleys] = NO;
        configLayers[HCConfigMapleGrove][HCLayerCurbRamps] = NO;
        configLayers[HCConfigMapleGrove][HCLayerCrimes] = NO;
        configLayers[HCConfigMapleGrove][HCLayerMapleGroveWater] = YES;
        configLayers[HCConfigMapleGrove][HCLayerMapleGroveFiber] = YES;
        
        for (int config = 0; config < NUMHardCodedConfigs; config++)
        {
            for (int layer = 0; layer < NUMHardCodedLayers; layer++)
                configLayerZoom[config][layer] = layerDefaultZoom[layer];
        }
        
        configLayerZoom[HCConfigAlleyWalls][HCLayerAerials] = 18;
        configLayerZoom[HCConfigAlleyWalls][HCLayerParcels] = 22;
        configLayerZoom[HCConfigAlleyWallStatus][HCLayerAlleys] = 10;
        configLayerZoom[HCConfigCurbRamps][HCLayerAerials] = 18;
        configLayerZoom[HCConfigCrimes][HCLayerAerials] = 17;
        configLayerZoom[HCConfigMapleGrove][HCLayerAerials] = 17;
        
        userAerials[HCConfigSewers] = YES;
        userAerials[HCConfigAlleyWalls] = YES;
        userAerials[HCConfigCrimes] = YES;
        configLayerZoom[HCConfigAlleyWalls][HCLayerParcels] = 22;
        configLayerZoom[HCConfigAlleyWallStatus][HCLayerAlleys] = 10;
        configLayerZoom[HCConfigCurbRamps][HCLayerAerials] = 18;
        configLayerZoom[HCConfigCrimes][HCLayerAerials] = 22;
        configLayerZoom[HCConfigCrimes][HCLayerParcels] = 22;
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
    
    if (_currentApp == appID)
        return FALSE;

    MapToolbar *tb = CRAPI.sharedInstance.mapToolbar;
    _currentApp = appID;
    CRAPI.sharedInstance.currentApp = _currentApp;
    
    for (int prop = 0; prop < NUMMapToolbarProperty; prop++)
    {
        [tb setConfigurationProperty:prop
                               value:configToobarSegs[_currentApp][prop]];
    }
    
    if (appID != HCConfigFromSpreadsheet)
    {
        [UserDefaults.defaults saveInteger:(appID + 1)
                                    forKey:@"CurrentConfig"];
    }
    
    CRAPI.sharedInstance.selectBoundaryFromMapType = nil;
    switch (_currentApp)
    {
        case HCConfigMetroProp:
            CRAPI.sharedInstance.selectBoundaryFromMapType = @"Cities And Townships";
        case HCConfigFromSpreadsheet:
            CRAPI.sharedInstance.parcelTextOption = 1;
            break;
        
        case HCConfigSewers:
        case HCConfigAlleyWalls:
        case HCConfigAlleyWallStatus:
        case HCConfigCrimes:
            CRAPI.sharedInstance.currentOverallBoundaryRefno = 51144;
            CRAPI.sharedInstance.parcelTextOption = 2;
            CRAPI.sharedInstance.currentOverallBoundaryName = @"Minneapolis";
            CRAPI.sharedInstance.currentOverallBoundaryType = @"City";
            break;
            
        case HCConfigMapleGrove:
            CRAPI.sharedInstance.currentOverallBoundaryRefno = 51157;
            CRAPI.sharedInstance.parcelTextOption = 1;
            configLayerZoom[HCConfigMapleGrove][HCLayerSewers] = 12;
            break;
            
        default:
            CRAPI.sharedInstance.parcelTextOption = 0;
            break;
    }
    if (_currentApp == HCConfigAlleyWalls || _currentApp == HCConfigAlleyWallStatus || _currentApp == HCConfigCurbRamps)
    {
        NSString *places = [CRAPI.sharedInstance getPlacesStringFromFile];
        
        [CRAPI.sharedInstance savePlacesString:places];
        [CRAPI.sharedInstance processPlaces];
        [CRAPI.sharedInstance setGeoIDForCurrentApp];
    }
    return rtn;
}

- (NSString *)getLayerName:(int)layerID
{
    NSString *name = [NSString stringWithUTF8String:layerName[layerID]];
    return name;
}

- (NSMutableArray *)getDatasetsForApp:(HardCodedConfigs)appID
{
    NSMutableArray *list = [[NSMutableArray alloc] init];

    if (appID == HCConfigMetroProp)
    {
        NSNumber *dsid = [NSNumber numberWithInt:GetDatabaseSettingNVMetro];
        [list addObject:dsid];
    }
    else
    {
        NSNumber *dsid = [NSNumber numberWithInt:GetDatabaseSettingAreas];
        [list addObject:dsid];
        
        for (int layer = 0; layer < NUMHardCodedLayers; layer++)
        {
            if (configLayers[appID][layer])
            {
                switch (layer)
                {
                    case HCLayerParcels:
                        [list addObject:[NSNumber numberWithInt:GetDatabaseSettingParcels]];
                        [list addObject:[NSNumber numberWithInt:GetDatabaseSettingProperty]];
                        break;
                        
                    case HCLayerSewers:
                        [list addObject:[NSNumber numberWithInt:GetDatabaseSettingSewer]];
                        break;
                        
                    case HCLayerPlanimetric:
                        [list addObject:[NSNumber numberWithInt:GetDatabaseSettingPlan]];
                        break;
                        
                    case HCLayerAlleys:
                        [list addObject:[NSNumber numberWithInt:GetDatabaseSettingAlleyWall]];
                        break;
                        
                    case HCLayerCurbRamps:
                        [list addObject:[NSNumber numberWithInt:GetDatabaseSettingCurbRamp]];
                        break;
                        
                    case HCLayerMapleGroveFiber:
                        [list addObject:[NSNumber numberWithInt:GetDatabaseSettingMapleGrove]];
                        break;
                }
            }
        }
        
        if (appID == HCConfigMetroProp)
            [list addObject:[NSNumber numberWithInt:GetDatabaseSettingCensus]];
    }
    return list;
}

- (NSArray *)getLayers
{
    NSMutableArray *layers = [[NSMutableArray alloc] init];
    
    for (int layer = 0; layer < NUMHardCodedLayers; layer++)
    {
        if (configLayers[_currentApp][layer])
        {
            LayerObject *lo = [[LayerObject alloc] init];
            lo.layerID = layer;
            lo.layerName = [NSString stringWithUTF8String:layerName[layer]];
            lo.hasSymbols = layerHasSymbols[layer];
            lo.zoomLevel = configLayerZoom[_currentApp][layer];
            [layers addObject:lo];
        }
    }
    
    return layers;
}

- (void)setLayer:(HardCodedLayers)layerID
  visibileAtZoom:(NSInteger)zoom
{
    configLayerZoom[_currentApp][layerID] = zoom;
}

- (BOOL)layer:(HardCodedLayers)layerID
visibleAtZoom:(CGFloat)zoom
      andPass:(ItemProcessingPassTypes)passID
{
    if (configLayers[_currentApp][layerID] &&
        zoom >= configLayerZoom[_currentApp][layerID])
    {
        return YES;
    }
    
    return NO;
}
- (BOOL)layerInConfig:(HardCodedLayers)layerID
{
    if (configLayers[_currentApp][layerID])
    {
        return YES;
    }
    
    return NO;
}

- (BOOL)symbol:(NSString *)sym
       inLayer:(HardCodedLayers)layerID
 visibleAtZoom:(CGFloat)zoom
{
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

- (HardCodedLayers)layerIDforIndex:(NSInteger)index
{
    int identifier =-1;
    int i;
    
    for (i = 0; i < NUMHardCodedLayers; i++)
    {
        if (configLayers[_currentApp][i])
            identifier++;
        
        if (identifier == index)
            break;
    }
    
    return i;
}

- (NSArray *)getSymbolsForLayer:(HardCodedLayers)layerID
{
    NSMutableArray *array=[[NSMutableArray alloc] init];

    switch (layerID)
    {
        case HCLayerPlanimetric:
        {
            
            PlanimetricData *pd = [[PlanimetricData alloc] init];
            
            NSArray *syms = [pd getDistinctSymbols:@"PLAN_POINT"];
            
            for (NSString *symName in syms)
            {
                LayerObject *lo = [[LayerObject alloc]initWithName:symName
                                                             andID:-1];
                [array addObject:lo];
            }
            syms = [pd getDistinctSymbols:@"PLAN_LINE"];
            
            for (NSString *symName in syms)
            {
                LayerObject *lo = [[LayerObject alloc]initWithName:symName
                                                             andID:-1];
                [array addObject:lo];
            }
            
            syms = [pd getDistinctSymbols:@"PLAN_AREA"];
            
            for (NSString *symName in syms)
            {
                LayerObject *lo = [[LayerObject alloc]initWithName:symName
                                                              andID:-1];
                
                [array addObject:lo];
            }
        }
            break;
            
        case HCLayerAlleys:
        {
            LayerObject * lo = [[LayerObject alloc]initWithName:@"ALLEYWALLPOINT"
                                                          andID:-1];
            
            [array addObject:lo];
            
            lo = [[LayerObject alloc]initWithName:@"ALLEYWALL"
                                            andID:-1];
            [array addObject:lo];
            
            lo = [[LayerObject alloc]initWithName:@"ALLEYCENTERLINE"
                                            andID:-1];
            [array addObject:lo];
            
        }
            break;
            
        case HCLayerCurbRamps:
        {
            LayerObject * lo = [[LayerObject alloc]initWithName:@"CRINTPT"
                                                          andID:-1];
            
            [array addObject:lo];
            
        }
            break;
        case HCLayerSewers:
        {
            LayerObject * lo = [[LayerObject alloc]initWithName:@"SEWER"
                                                          andID:-1];
            
            [array addObject:lo];
            
            lo = [[LayerObject alloc]initWithName:@"STORM"
                                            andID:-1];
            [array addObject:lo];
            
            lo = [[LayerObject alloc]initWithName:@"SANITARY"
                                            andID:-1];
            [array addObject:lo];
            
        }
            break;
            
            
        default:
            break;
    }
    
    [self sortSymbolsByName:array];
    return array;
}

- (void)sortSymbolsByName:(NSMutableArray *)symbols
{
    [symbols sortUsingComparator: ^(id obj1, id obj2)
     {
         LayerObject *lo1 = obj1;
         LayerObject *lo2 = obj2;
         
         return [lo1.layerName compare:lo2.layerName];
     }];
}
- (BOOL)haveUserAerials
{
    return userAerials[_currentApp];
}
- (BOOL)useMapTypeControl
{
    return configToobarSegs[_currentApp][MapToolbarPropertyWantMapType];
}

+ (NSString *)getAdjustValueString:(AdjustCrimeOptions)opt
{
    NSString *rtn = @"";
    
    switch (opt)
    {
        case Population:
            rtn = @"POPTOTAL";
            break;
        case HousingUnits:
            rtn = @"HUTOTAL";
            break;
            
        default:
            break;
    }
    
    return rtn;
}

@end