//  ConfigurationControl.h
//  GMMobile

#import <UIKit/UIKit.h>
#import "CCodeLibrary/DisplayCharacteristics.h"
#import "Theme.h"

#define MAX_LAYER_NAME 32
#define NUMHardCodedConfigs 8

#define MAPIT_CIRCULAR      1
#define MAPIT_AREA_BLOCK    2
#define MAPIT_AREA_BLOCKGRP 3
#define MAPIT_AREA_TRACT    4

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
    HCConfigFromSpreadsheet,
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

@property NSMutableArray *appList, *legendList;
@property HardCodedConfigs legendApp, currentApp;
@property BOOL GMTilesVisible, wantAllCrimes;
@property AdjustCrimeOptions  adjustCrimeOption;
@property NSString *adjustCrimeArea;
@property PropSheetValues currentPropSheetValue;
@property NSString * MapitPID;
@property int MapitBoundaryOpt;
@property int MapitBoundaryRefno;
@property NSString * MapitBoundaryType;
@property int MapitTargetParcelRefno;
@property LLPOINT MapitTargetCenterPoint;
@property CGFloat MapitCirularBoundaryRadiusInMiles;

+ (NSString *)getAdjustValueString:(AdjustCrimeOptions)opt;

- (BOOL)setApp:(HardCodedConfigs)appID;
- (NSArray *)getLayers;
- (NSMutableArray *)getDatasetsForApp:(HardCodedConfigs)appID;
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

@end