//  ConfigurationControl.m
//  GMMobile

#import "ConfigurationControl.h"
#import "NVMetroSettings.h"
#import "CCodeLibrary/MapToolbar.h"
#import "AppDelegate.h"
#import "PlanimetricData.h"
#import "CCodeLibrary/FTPDataPull.h"

#define MAX_SYMBOLS_IN_LAYER    16
static char layerName[NUMHardCodedLayers][MAX_LAYER_NAME]={0};
//static BOOL layerVisible[NUMHardCodedLayers]={0};
//static BOOL layerPickable[NUMHardCodedLayers]={0};
static CGFloat layerDefaultZoom[NUMHardCodedLayers]={0};
static BOOL layerHasSymbols[NUMHardCodedLayers]={0};
static BOOL userAerials[NUMHardCodedConfigs]={0};
static BOOL configToobarSegs[NUMHardCodedConfigs][NUMMapToolbarProperty]={0};
static int  configLayers[NUMHardCodedConfigs][NUMHardCodedLayers]={0};
static CGFloat configLayerZoom[NUMHardCodedConfigs][NUMHardCodedLayers][MAX_SYMBOLS_IN_LAYER]={0};

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
        _symbol = 0;
    }
    
    return self;
}

- (id)initWithName:(NSString *)name
             ID:(int)identifier
         andSymbol:(int)symbol
{
    self = [super init];
    
    if (self)
    {
        _layerName = name;
        _layerID = identifier;
        _symbol = symbol;
    }
    
    return self;
}

@end

@interface ConfigurationControl ()

@property BOOL firstCall;

@end

@implementation ConfigurationControl
{
    NSMutableArray *symLists[NUMHardCodedConfigs][NUMHardCodedLayers];
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _firstCall = YES;
        _appList = NSMutableArray.array;
        ApplicationObject *ap = nil;
        
        if ([CRAPI.sharedInstance.bundleID isEqualToString:@"com.gssi.newvisionaccess"])
        {
            ap = [[ApplicationObject alloc] initWithNameAndID:@"Maple Grove"
                                                   identifier:HCConfigMapleGrove];
            [_appList addObject:ap];
            
            ap = [[ApplicationObject alloc] initWithNameAndID:@"Minneapolis"
                                                   identifier:HCConfigSewers];
            [_appList addObject:ap];
        }
        
        else
        {
            ap = [[ApplicationObject alloc] initWithNameAndID:@"Alley Wall Inventory"
                                                   identifier:HCConfigAlleyWalls];
            [_appList addObject:ap];
            
            ap = [[ApplicationObject alloc] initWithNameAndID:@"Alley Wall Status"
                                                   identifier:HCConfigAlleyWallStatus];
            [_appList addObject:ap];
            
            ap = [[ApplicationObject alloc] initWithNameAndID:@"Curb Ramp Inventory"
                                                   identifier:HCConfigCurbRamps];
            [_appList addObject:ap];
            
            ap = [[ApplicationObject alloc] initWithNameAndID:@"Sidewalk Inventory"
                                                   identifier:HCConfigSidewalk];
            [_appList addObject:ap];
            
            ap = [[ApplicationObject alloc] initWithNameAndID:@"Sewers"
                                                   identifier:HCConfigSewers];
            [_appList addObject:ap];
            
            ap = [[ApplicationObject alloc] initWithNameAndID:@"Metro Property Analysis"
                                                   identifier:HCConfigMetroProp];
            [_appList addObject:ap];
            
            ap = [[ApplicationObject alloc] initWithNameAndID:@"Minneapolis Crime Data"
                                                   identifier:HCConfigCrimes];
            
            [_appList addObject:ap];
            
            ap = [[ApplicationObject alloc] initWithNameAndID:@"Maple Grove App"
                                                   identifier:HCConfigMapleGrove];
            [_appList addObject:ap];
            
            ap = [[ApplicationObject alloc] initWithNameAndID:@"Minnesota Game App"
                                                   identifier:HCConfigMinnesotaGame];
            [_appList addObject:ap];

            ap = [[ApplicationObject alloc] initWithNameAndID:@"Minnesota Hunting App"
                                                   identifier:HCConfigHunting];
            [_appList addObject:ap];
        }
        
        _currentApp = -1;
        
        strcpy(layerName[HCLayerAerials], "Aerial Photos");
        strcpy(layerName[HCLayerParcels], "Parcel Boundaries");
        strcpy(layerName[HCLayerSewers], "Sewer Data");
        strcpy(layerName[HCLayerPlanimetric], "Planimetric Data");
        strcpy(layerName[HCLayerAlleys], "Alleys");
        strcpy(layerName[HCLayerCurbRamps], "Curb Ramps");
        strcpy(layerName[HCLayerCrimes], "Crimes");
        strcpy(layerName[HCLayerMapleGroveWater], "Water");
        strcpy(layerName[HCLayerMapleGroveFiber], "Fiber");
        strcpy(layerName[HCLayerSidewalkPoints], "Sidewalk Points");
        strcpy(layerName[HCLayerHunting], "Hunting Data");

        layerDefaultZoom[HCLayerAerials] = 12;
        layerDefaultZoom[HCLayerParcels] = 16;
        layerDefaultZoom[HCLayerSewers] = 17;
        layerDefaultZoom[HCLayerPlanimetric] = 18;
        layerDefaultZoom[HCLayerAlleys] = 14;
        layerDefaultZoom[HCLayerCurbRamps] = 13;
        layerDefaultZoom[HCLayerCrimes] = 8;
        layerDefaultZoom[HCLayerMapleGroveFiber] = 11;
        layerDefaultZoom[HCLayerMapleGroveWater] = 11;
        layerDefaultZoom[HCLayerSidewalkPoints] = 14;
        layerDefaultZoom[HCLayerHunting] = 11;

        layerHasSymbols[HCLayerAerials] = NO;
        layerHasSymbols[HCLayerParcels] = NO;
        layerHasSymbols[HCLayerSewers] = YES;
        layerHasSymbols[HCLayerPlanimetric] = YES;
        layerHasSymbols[HCLayerAlleys] = YES;
        layerHasSymbols[HCLayerCrimes] = NO;
        layerHasSymbols[HCLayerMapleGroveWater] = NO;
        layerHasSymbols[HCLayerMapleGroveFiber] = NO;
        layerHasSymbols[HCLayerSidewalkPoints] = YES;
        layerHasSymbols[HCLayerHunting] = NO;

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
        
        configToobarSegs[HCConfigSidewalk][MapToolbarPropertyWantPlat] = NO;
        configToobarSegs[HCConfigSidewalk][MapToolbarPropertyWantDigitize] = YES;
        configToobarSegs[HCConfigSidewalk][MapToolbarPropertyWantMapType] = YES;
        configToobarSegs[HCConfigSidewalk][MapToolbarPropertyWantUserLocation] = YES;
        configToobarSegs[HCConfigSidewalk][MapToolbarPropertyWantExtents] = YES;
        configToobarSegs[HCConfigSidewalk][MapToolbarPropertyWantLegends] = NO;
        configToobarSegs[HCConfigSidewalk][MapToolbarPropertyWantGrayscale] = NO;
        configToobarSegs[HCConfigSidewalk][MapToolbarPropertyWantClearMarkers] = YES;
        configToobarSegs[HCConfigSidewalk][MapToolbarPropertyWantEmailPDF] = YES;
        configToobarSegs[HCConfigSidewalk][MapToolbarPropertyWantProgressBar] = YES;
        configToobarSegs[HCConfigSidewalk][MapToolbarPropertyWantHelpButton] = YES;
        configToobarSegs[HCConfigSidewalk][MapToolbarPropertyWantReturnButton] = NO;
        
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantPlat] = NO;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantDigitize] = NO;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantMapType] = YES;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantUserLocation] = YES;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantExtents] = YES;
        configToobarSegs[HCConfigMetroProp][MapToolbarPropertyWantLegends] = NO;
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
        
        configToobarSegs[HCConfigMapleGrove][MapToolbarPropertyWantPlat] = NO;
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
        
        configToobarSegs[HCConfigMapleGrovePDF][MapToolbarPropertyWantPlat] = YES;
        configToobarSegs[HCConfigMapleGrovePDF][MapToolbarPropertyWantDigitize] = NO;
        configToobarSegs[HCConfigMapleGrovePDF][MapToolbarPropertyWantMapType] = NO;
        configToobarSegs[HCConfigMapleGrovePDF][MapToolbarPropertyWantUserLocation] = YES;
        configToobarSegs[HCConfigMapleGrovePDF][MapToolbarPropertyWantExtents] = YES;
        configToobarSegs[HCConfigMapleGrovePDF][MapToolbarPropertyWantLegends] = NO;
        configToobarSegs[HCConfigMapleGrovePDF][MapToolbarPropertyWantGrayscale] = NO;
        configToobarSegs[HCConfigMapleGrovePDF][MapToolbarPropertyWantClearMarkers] = NO;
        configToobarSegs[HCConfigMapleGrovePDF][MapToolbarPropertyWantEmailPDF] = YES;
        configToobarSegs[HCConfigMapleGrovePDF][MapToolbarPropertyWantProgressBar] = NO;
        configToobarSegs[HCConfigMapleGrovePDF][MapToolbarPropertyWantHelpButton] = YES;
        configToobarSegs[HCConfigMapleGrovePDF][MapToolbarPropertyWantReturnButton] = NO;
        
        configToobarSegs[HCConfigMinnesotaGame][MapToolbarPropertyWantPlat] = NO;
        configToobarSegs[HCConfigMinnesotaGame][MapToolbarPropertyWantDigitize] = NO;
        configToobarSegs[HCConfigMinnesotaGame][MapToolbarPropertyWantMapType] = NO;
        configToobarSegs[HCConfigMinnesotaGame][MapToolbarPropertyWantUserLocation] = NO;
        configToobarSegs[HCConfigMinnesotaGame][MapToolbarPropertyWantExtents] = NO;
        configToobarSegs[HCConfigMinnesotaGame][MapToolbarPropertyWantLegends] = NO;
        configToobarSegs[HCConfigMinnesotaGame][MapToolbarPropertyWantGrayscale] = NO;
        configToobarSegs[HCConfigMinnesotaGame][MapToolbarPropertyWantClearMarkers] = NO;
        configToobarSegs[HCConfigMinnesotaGame][MapToolbarPropertyWantEmailPDF] = NO;
        configToobarSegs[HCConfigMinnesotaGame][MapToolbarPropertyWantProgressBar] = NO;
        configToobarSegs[HCConfigMinnesotaGame][MapToolbarPropertyWantHelpButton] = NO;
        configToobarSegs[HCConfigMinnesotaGame][MapToolbarPropertyWantReturnButton] = NO;
        
        configToobarSegs[HCConfigHunting][MapToolbarPropertyWantPlat] = NO;
        configToobarSegs[HCConfigHunting][MapToolbarPropertyWantDigitize] = NO;
        configToobarSegs[HCConfigHunting][MapToolbarPropertyWantMapType] = YES;
        configToobarSegs[HCConfigHunting][MapToolbarPropertyWantUserLocation] = YES;
        configToobarSegs[HCConfigHunting][MapToolbarPropertyWantExtents] = NO;
        configToobarSegs[HCConfigHunting][MapToolbarPropertyWantLegends] = NO;
        configToobarSegs[HCConfigHunting][MapToolbarPropertyWantGrayscale] = NO;
        configToobarSegs[HCConfigHunting][MapToolbarPropertyWantClearMarkers] = NO;
        configToobarSegs[HCConfigHunting][MapToolbarPropertyWantEmailPDF] = NO;
        configToobarSegs[HCConfigHunting][MapToolbarPropertyWantProgressBar] = NO;
        configToobarSegs[HCConfigHunting][MapToolbarPropertyWantHelpButton] = NO;
        configToobarSegs[HCConfigHunting][MapToolbarPropertyWantReturnButton] = NO;
        
        //setup layers
        configLayers[HCConfigSewers][HCLayerAerials] = YES;
        configLayers[HCConfigSewers][HCLayerParcels] = YES;
        configLayers[HCConfigSewers][HCLayerSewers] = YES;
        configLayers[HCConfigSewers][HCLayerPlanimetric] = NO;
        configLayers[HCConfigSewers][HCLayerAlleys] = NO;
        configLayers[HCConfigSewers][HCLayerCurbRamps] = NO;
        configLayers[HCConfigSewers][HCLayerSidewalkPoints] = NO;

        configLayers[HCConfigAlleyWalls][HCLayerAerials] = YES;
        configLayers[HCConfigAlleyWalls][HCLayerParcels] = YES;
        configLayers[HCConfigAlleyWalls][HCLayerSewers] = NO;
        configLayers[HCConfigAlleyWalls][HCLayerPlanimetric] = YES;
        configLayers[HCConfigAlleyWalls][HCLayerAlleys] = YES;
        configLayers[HCConfigAlleyWalls][HCLayerCurbRamps] = NO;
        configLayers[HCConfigAlleyWalls][HCLayerSidewalkPoints] = NO;
       
        configLayers[HCConfigAlleyWallStatus][HCLayerAerials] = NO;
        configLayers[HCConfigAlleyWallStatus][HCLayerParcels] = NO;
        configLayers[HCConfigAlleyWallStatus][HCLayerSewers] = NO;
        configLayers[HCConfigAlleyWallStatus][HCLayerPlanimetric] = NO;
        configLayers[HCConfigAlleyWallStatus][HCLayerAlleys] = YES;
        configLayers[HCConfigAlleyWallStatus][HCLayerCurbRamps] = NO;
        configLayers[HCConfigAlleyWallStatus][HCLayerSidewalkPoints] = NO;
        
        configLayers[HCConfigCurbRamps][HCLayerAerials] = YES;
        configLayers[HCConfigCurbRamps][HCLayerParcels] = NO;
        configLayers[HCConfigCurbRamps][HCLayerSewers] = NO;
        configLayers[HCConfigCurbRamps][HCLayerPlanimetric] = NO;
        configLayers[HCConfigCurbRamps][HCLayerAlleys] = NO;
        configLayers[HCConfigCurbRamps][HCLayerCurbRamps] = YES;
        configLayers[HCConfigCurbRamps][HCLayerSidewalkPoints] = NO;
        
        configLayers[HCConfigSidewalk][HCLayerAerials] = YES;
        configLayers[HCConfigSidewalk][HCLayerParcels] = NO;
        configLayers[HCConfigSidewalk][HCLayerSewers] = NO;
        configLayers[HCConfigSidewalk][HCLayerPlanimetric] = NO;
        configLayers[HCConfigSidewalk][HCLayerAlleys] = NO;
        configLayers[HCConfigSidewalk][HCLayerCurbRamps] = NO;
        configLayers[HCConfigSidewalk][HCLayerSidewalkPoints] = YES;
        
        configLayers[HCConfigMetroProp][HCLayerAerials] = NO;
        configLayers[HCConfigMetroProp][HCLayerParcels] = YES;
        configLayers[HCConfigMetroProp][HCLayerSewers] = NO;
        configLayers[HCConfigMetroProp][HCLayerPlanimetric] = NO;
        configLayers[HCConfigMetroProp][HCLayerAlleys] = NO;
        configLayers[HCConfigMetroProp][HCLayerCurbRamps] = NO;
        configLayers[HCConfigMetroProp][HCLayerSidewalkPoints] = NO;
        
        configLayers[HCConfigFromSpreadsheet][HCLayerAerials] = NO;
        configLayers[HCConfigFromSpreadsheet][HCLayerParcels] = YES;
        configLayers[HCConfigFromSpreadsheet][HCLayerSewers] = NO;
        configLayers[HCConfigFromSpreadsheet][HCLayerPlanimetric] = NO;
        configLayers[HCConfigFromSpreadsheet][HCLayerAlleys] = NO;
        configLayers[HCConfigFromSpreadsheet][HCLayerCurbRamps] = NO;
        configLayers[HCConfigFromSpreadsheet][HCLayerSidewalkPoints] = NO;
        
        configLayers[HCConfigCrimes][HCLayerAerials] = YES;
        configLayers[HCConfigCrimes][HCLayerParcels] = YES;
        configLayers[HCConfigCrimes][HCLayerSewers] = NO;
        configLayers[HCConfigCrimes][HCLayerPlanimetric] = NO;
        configLayers[HCConfigCrimes][HCLayerAlleys] = NO;
        configLayers[HCConfigCrimes][HCLayerCurbRamps] = NO;
        configLayers[HCConfigCrimes][HCLayerCrimes] = YES;
        configLayers[HCConfigCrimes][HCLayerSidewalkPoints] = NO;
        
        configLayers[HCConfigMapleGrove][HCLayerAerials] = YES;
        configLayers[HCConfigMapleGrove][HCLayerParcels] = YES;
        configLayers[HCConfigMapleGrove][HCLayerSewers] = YES;
        configLayers[HCConfigMapleGrove][HCLayerPlanimetric] = NO;
        configLayers[HCConfigMapleGrove][HCLayerAlleys] = NO;
        configLayers[HCConfigMapleGrove][HCLayerCurbRamps] = NO;
        configLayers[HCConfigMapleGrove][HCLayerCrimes] = NO;
        configLayers[HCConfigMapleGrove][HCLayerMapleGroveWater] = YES;
        configLayers[HCConfigMapleGrove][HCLayerMapleGroveFiber] = YES;
        configLayers[HCConfigMapleGrove][HCLayerSidewalkPoints] = NO;
        
        configLayers[HCConfigMinnesotaGame][HCLayerAerials] = YES;
        configLayers[HCConfigMinnesotaGame][HCLayerParcels] = YES;
        configLayers[HCConfigMinnesotaGame][HCLayerSewers] = NO;
        configLayers[HCConfigMinnesotaGame][HCLayerPlanimetric] = NO;
        configLayers[HCConfigMinnesotaGame][HCLayerAlleys] = NO;
        configLayers[HCConfigMinnesotaGame][HCLayerCurbRamps] = NO;
        configLayers[HCConfigMinnesotaGame][HCLayerCrimes] = NO;
        configLayers[HCConfigMinnesotaGame][HCLayerMapleGroveWater] = NO;
        configLayers[HCConfigMinnesotaGame][HCLayerMapleGroveFiber] = NO;
        configLayers[HCConfigMinnesotaGame][HCLayerSidewalkPoints] = NO;
        
        configLayers[HCConfigHunting][HCLayerAerials] = YES;
        configLayers[HCConfigHunting][HCLayerParcels] = YES;
        configLayers[HCConfigHunting][HCLayerSewers] = NO;
        configLayers[HCConfigHunting][HCLayerPlanimetric] = NO;
        configLayers[HCConfigHunting][HCLayerAlleys] = NO;
        configLayers[HCConfigHunting][HCLayerCurbRamps] = NO;
        configLayers[HCConfigHunting][HCLayerCrimes] = NO;
        configLayers[HCConfigHunting][HCLayerMapleGroveWater] = NO;
        configLayers[HCConfigHunting][HCLayerMapleGroveFiber] = NO;
        configLayers[HCConfigHunting][HCLayerSidewalkPoints] = NO;
        configLayers[HCConfigHunting][HCLayerHunting] = YES;

        for (int config = 0; config < NUMHardCodedConfigs; config++)
        {
            for (int layer = 0; layer < NUMHardCodedLayers; layer++)
                configLayerZoom[config][layer][0] = layerDefaultZoom[layer];
        }
        
        userAerials[HCConfigSewers] = YES;
        userAerials[HCConfigAlleyWalls] = YES;
        userAerials[HCConfigCrimes] = YES;
        configLayerZoom[HCConfigAlleyWalls][HCLayerParcels][0] = 22;
        configLayerZoom[HCConfigAlleyWallStatus][HCLayerAlleys][0] = 10;
        configLayerZoom[HCConfigCurbRamps][HCLayerAerials][0] = 18;
        configLayerZoom[HCConfigCrimes][HCLayerAerials][0] = 22;
        configLayerZoom[HCConfigMapleGrove][HCLayerAerials][0] = 17;
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
    static BOOL first = TRUE;
    
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
    
    if (appID != HCConfigFromSpreadsheet && appID != HCConfigMapleGrovePDF)
    {
        [UserDefaults.defaults saveInteger:(appID + 1)
                                    forKey:@"CurrentConfig"];
    }
    
    CRAPI.sharedInstance.selectBoundaryFromMapType = nil;
    CRAPI.sharedInstance.appChanged = YES;
    CRAPI.sharedInstance.currentOverallBoundaryTable = @"BOUNDARY";
    
    switch (_currentApp)
    {
        case HCConfigMetroProp:
            if (first)
            {
                //CRAPI.sharedInstance.selectBoundaryFromMapType = @"Seven County Metro Area";
                CRAPI.sharedInstance.currentOverallBoundaryName = @"7 County Metro Area";
                CRAPI.sharedInstance.currentOverallBoundaryType = @"Seven County Metro Area";
                //NVMetroSettings.sharedInstance.currentTextOption = [NVMetroSettings.sharedInstance textOptionsForAreas];
                CRAPI.sharedInstance.currentOverallBoundaryRefno = 1050000037;
            }
        case HCConfigFromSpreadsheet:
            if (first)
                CRAPI.sharedInstance.parcelTextOption = 1;
            first = FALSE;
            break;
        case HCConfigSidewalk:
            CRAPI.sharedInstance.currentOverallBoundaryRefno = 0;
            [UserDefaults.defaults saveInteger:CRAPI.sharedInstance.currentOverallBoundaryRefno forKey:@"CurrentOverallBoundaryRefno"];
            CRAPI.sharedInstance.currentOverallBoundaryName = @"";
            [UserDefaults.defaults saveString:CRAPI.sharedInstance.currentOverallBoundaryName forKey:@"CurrentOverallBoundaryName"];
            CRAPI.sharedInstance.currentOverallBoundaryType = @"";
            [UserDefaults.defaults saveString:CRAPI.sharedInstance.currentOverallBoundaryType forKey:@"CurrentOverallBoundaryType"];
            break;
        case HCConfigSewers:
        case HCConfigAlleyWalls:
        case HCConfigAlleyWallStatus:
        case HCConfigCrimes:{
            CRAPI.sharedInstance.currentOverallBoundaryRefno = (int)[UserDefaults.defaults integerForKey:@"CurrentOverallBoundaryRefno"];
            CRAPI.sharedInstance.parcelTextOption = 2;
            
            if (CRAPI.sharedInstance.currentOverallBoundaryRefno)
            {
                CRAPI.sharedInstance.currentOverallBoundaryName = [UserDefaults.defaults stringForKey:@"CurrentOverallBoundaryName"];
                CRAPI.sharedInstance.currentOverallBoundaryType = [UserDefaults.defaults stringForKey:@"CurrentOverallBoundaryType"];
            }
            
            else
            {
                CRAPI.sharedInstance.currentOverallBoundaryRefno = 51144;
                [UserDefaults.defaults saveInteger:CRAPI.sharedInstance.currentOverallBoundaryRefno forKey:@"CurrentOverallBoundaryRefno"];
                CRAPI.sharedInstance.currentOverallBoundaryName = @"Minneapolis";
                [UserDefaults.defaults saveString:CRAPI.sharedInstance.currentOverallBoundaryName forKey:@"CurrentOverallBoundaryName"];
                CRAPI.sharedInstance.currentOverallBoundaryType = @"City";
                [UserDefaults.defaults saveString:CRAPI.sharedInstance.currentOverallBoundaryType forKey:@"CurrentOverallBoundaryType"];
            }
            
            _wantAllCrimes = [UserDefaults.defaults boolForKey:@"WantAllCrimes"];
            _adjustCrimeOption = (AdjustCrimeOptions)[UserDefaults.defaults integerForKey:@"AdjustCrimeOption"];
            
            NSString *defaultAdjustCrimeArea = [UserDefaults.defaults stringForKey:@"AdjustCrimeArea"];
            
            if (defaultAdjustCrimeArea && defaultAdjustCrimeArea.length)
                _adjustCrimeArea = defaultAdjustCrimeArea;
            break;}
        case HCConfigMapleGrove:
            CRAPI.sharedInstance.currentOverallBoundaryRefno = 51157;
            CRAPI.sharedInstance.parcelTextOption = 1;
            configLayerZoom[HCConfigMapleGrove][HCLayerSewers][0] = 12;
            break;
        case HCConfigHunting:
        case HCConfigMinnesotaGame:
            CRAPI.sharedInstance.currentOverallBoundaryRefno = 17;
            CRAPI.sharedInstance.currentOverallBoundaryTable = @"STATE";

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

- (void)resetLegendPositions
{
    for (ThemeLegend *legend in _legendList)
    {
        legend.landscapeMapOrigin = CGPointZero;
        legend.portraitMapOrigin = CGPointZero;
        legend.isDraggedPortrait = NO;
        legend.isDraggedLandscape = NO;
    }
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
        [list addObject:[NSNumber numberWithInt:GetDatabaseSettingCensus]];
        [list addObject:[NSNumber numberWithInt:GetDatabaseSettingAreas]];
    }
    
    else
    {
        //NSNumber *dsid = [NSNumber numberWithInt:GetDatabaseSettingAreas]; areas now in bundle
        //[list addObject:dsid];
        
        for (int layer = 0; layer < NUMHardCodedLayers; layer++)
        {
            if (configLayers[appID][layer])
            {
                switch (layer)
                {
                    case HCLayerParcels:
                        //[list addObject:[NSNumber numberWithInt:GetDatabaseSettingParcels]];
                        if (appID == HCConfigAlleyWalls || appID == HCConfigAlleyWallStatus)
                            [list addObject:[NSNumber numberWithInt:GetDatabaseSettingNVMetro]];
                        break;
                    case HCLayerSewers:
                        [list addObject:[NSNumber numberWithInt:GetDatabaseSettingSewer]];
                        break;
                    case HCLayerPlanimetric:
                        //[list addObject:[NSNumber numberWithInt:GetDatabaseSettingPlan]];
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
                    case HCLayerHunting:
                        [list addObject:[NSNumber numberWithInt:GetDatabaseSettingHunting]];
                        break;
                }
            }
        }
        
        if (appID == HCConfigMetroProp)
            [list addObject:[NSNumber numberWithInt:GetDatabaseSettingCensus]];
        
        else if (appID == HCConfigCrimes)
            [list addObject:[NSNumber numberWithInt:GetDatabaseSettingCrimes]];
    }
    
    return list;
}

- (NSArray *)getLayers
{
    NSMutableArray *layers = NSMutableArray.new;
    
    for (int layer = 0; layer < NUMHardCodedLayers; layer++)
    {
        if (configLayers[_currentApp][layer])
        {
            LayerObject *lo = LayerObject.new;
            lo.layerID = layer;
            lo.layerName = [NSString stringWithUTF8String:layerName[layer]];
            lo.hasSymbols = layerHasSymbols[layer];
            lo.zoomLevel = configLayerZoom[_currentApp][layer][0];
            [layers addObject:lo];
        }
    }
    
    return layers;
}

- (void)setLayer:(HardCodedLayers)layerID
          andSymbol:(int)symbol
  visibileAtZoom:(NSInteger)zoom
{
    configLayerZoom[_currentApp][layerID][symbol] = zoom;
}

- (BOOL)layer:(HardCodedLayers)layerID
visibleAtZoom:(CGFloat)zoom
      andPass:(ItemProcessingPassTypes)passID
{
    if (configLayers[_currentApp][layerID] && zoom >= configLayerZoom[_currentApp][layerID][0])
        return YES;
    
    else
        return NO;
}

- (BOOL)layerInConfig:(HardCodedLayers)layerID
{
    if (configLayers[_currentApp][layerID])
        return YES;
    
    else
        return NO;
}

- (BOOL)symbol:(int)symbol
       inLayer:(HardCodedLayers)layerID
 visibleAtZoom:(CGFloat)zoom
{
    if (configLayers[_currentApp][layerID] && zoom >= configLayerZoom[_currentApp][layerID][symbol])
        return YES;
    
    else
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
    int identifier = -1;
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
    NSMutableArray *array= NSMutableArray.new;
    LayerObject *lo = nil;

    switch (layerID)
    {
        case HCLayerPlanimetric:{
            PlanimetricData *pd = PlanimetricData.new;
            NSArray *syms = [pd getDistinctSymbols:@"PLAN_POINT"];
            
            for (NSString *symName in syms)
            {
                lo = [[LayerObject alloc] initWithName:symName andID:-1];
                [array addObject:lo];
            }
            
            syms = [pd getDistinctSymbols:@"PLAN_LINE"];
            
            for (NSString *symName in syms)
            {
                lo = [[LayerObject alloc] initWithName:symName andID:-1];
                [array addObject:lo];
            }
            
            syms = [pd getDistinctSymbols:@"PLAN_AREA"];
            
            for (NSString *symName in syms)
            {
                lo = [[LayerObject alloc] initWithName:symName andID:-1];
                [array addObject:lo];
            }
            break;}
        case HCLayerAlleys:
            lo = [[LayerObject alloc] initWithName:@"ALLEYWALLPOINT" andID:-1];
            [array addObject:lo];
            lo = [[LayerObject alloc] initWithName:@"ALLEYWALL" andID:-1];
            [array addObject:lo];
            lo = [[LayerObject alloc] initWithName:@"ALLEYCENTERLINE" andID:-1];
            [array addObject:lo];
            break;
        case HCLayerSidewalkPoints:
            lo = [[LayerObject alloc] initWithName:@"SIDEWALKPOINT" andID:-1];
            [array addObject:lo];
            break;
        case HCLayerCurbRamps:
            lo = [[LayerObject alloc] initWithName:@"CRINTPT" andID:-1];
            [array addObject:lo];
            break;
        case HCLayerSewers:
            lo = [[LayerObject alloc] initWithName:@"STORM" ID:layerID andSymbol:STORM_SYMBOLS];
            lo.zoomLevel = configLayerZoom[_currentApp][layerID][STORM_SYMBOLS];
            [array addObject:lo];
            lo = [[LayerObject alloc] initWithName:@"SANITARY" ID:layerID andSymbol:SANITARY_SYMBOLS];
            lo.zoomLevel = configLayerZoom[_currentApp][layerID][SANITARY_SYMBOLS];
            [array addObject:lo];
            break;
        default:break;
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
        case ACO_Population:
            rtn = @"POPTOTAL";
            break;
        case ACO_HousingUnits:
            rtn = @"HUTOTAL";
            break;
        default:break;
    }
    
    return rtn;
}

- (void)clearCompareModeForLegendsOtherThanLegend:(ThemeLegend *)legend
{
    for (ThemeLegend *tl in _legendList)
    {
        if (tl != legend)
        {
            tl.selectionMode = SEL_MODE_SELECT;
            
            for (ThemeLegendCell *tlc in tl.cells)
            {
                if (tlc.status == TLC_STATUS_COMPARE)
                    tlc.status = TLC_STATUS_ON;
            }
        }
    }
}

@end
