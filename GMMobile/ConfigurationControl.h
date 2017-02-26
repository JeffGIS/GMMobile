//  ConfigurationControl.h
//  GMMobile

#import <UIKit/UIKit.h>
#import "CCodeLibrary/GSSiEnums.h"
#import "CCodeLibrary/DisplayCharacteristics.h"
#import "Theme.h"
#import "PropertyList.h"

#define MAX_LAYER_NAME 32

#define MAPIT_CIRCULAR      1
#define MAPIT_AREA_BLOCK    2
#define MAPIT_AREA_BLOCKGRP 3
#define MAPIT_AREA_TRACT    4

#define SANITARY_SYMBOLS    1
#define STORM_SYMBOLS       2

typedef NS_ENUM(NSInteger, AdjustCrimeOptions)
{
    None,
    Population,
    HousingUnits,
};

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
NUMHardCodedLayers};

@interface ApplicationObject : NSObject

@property NSString *appName;
@property HardCodedConfigs appID;

- (id)initWithNameAndID:(NSString *)name
             identifier:(int)identifier;

@end

@interface LayerObject : NSObject

@property NSString *layerName;
@property int layerID;
@property int symbol;
@property BOOL hasSymbols, stepperEnabled;
@property NSInteger segControlIndex, zoomLevel;
@property UIColor *cellButtonColor;

- (id)initWithName:(NSString *)name
             andID:(int)identifier;

- (id)initWithName:(NSString *)name
                ID:(int)identifier
         andSymbol:(int)symbol;

@end

@interface ConfigurationControl : NSObject

+ (ConfigurationControl *)sharedInstance;

@property NSMutableArray *appList, *legendList;
@property HardCodedConfigs legendApp;
@property HardCodedConfigs currentApp;
@property BOOL GMTilesVisible, wantAllCrimes;
@property AdjustCrimeOptions  adjustCrimeOption;
@property NSString *adjustCrimeArea;
@property PropFieldType currentPropSheetFieldType;
@property NSString * MapitPID;
@property int MapitBoundaryOpt;
@property int MapitBoundaryRefno;
@property NSString * MapitBoundaryType;
@property int MapitTargetParcelRefno;
@property LLPOINT MapitTargetCenterPoint;
@property CGFloat MapitCirularBoundaryRadiusInMiles;
@property MapitBaseLayer currentMapitBaseLayer;

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
       andSymbol:(int)symbol
  visibileAtZoom:(NSInteger)zoom;

- (BOOL)layer:(HardCodedLayers)layerID
visibleAtZoom:(CGFloat)zoom
      andPass:(ItemProcessingPassTypes)passID;

- (BOOL)symbol:(int)symbol
       inLayer:(HardCodedLayers)layerID
 visibleAtZoom:(CGFloat)zoom;

@end
