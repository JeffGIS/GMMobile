//  NVMetroSettings.h
//  NVMobile

@import Foundation;
@import GoogleMaps;

CORNERPOINTS CornerPointsFromRegion (GMSVisibleRegion region);

typedef NS_ENUM(NSInteger, CPFeatures)
{
    CPFNone,
    CPFParcels,
    CPFParcels_RES,
    CPFParcels_COM,
    CPFParcels_IND,
    CPFParcels_AG,
    CPFLandUse,
    CPFBlocks,
    CPFBlockGroups,
    CPFBlockGroups_ACS,
    CPFTracts,
    CPFVoterDistricts,
    CPFSchoolDistricts,
    CPFeaturesCount
};

typedef NS_ENUM(NSInteger, CPParcelValues)
{
    CPParcelVNone,
    CPParcelVTotTax,
    CPParcelVTotEMV,
    CPParcelVBuildEMV,
    CPParcelVLandEMV,
    CPParcelVLastSalePrice,
    CPParcelVHomestead,
    CPParcelVBuildDate,
    CPParcelVCount
};

typedef NS_ENUM(NSInteger, CPLandUseValues)
{
    CPLandUseVNone,
    CPLandUseVCodes,
    CPLandUseVCount
};

typedef NS_ENUM(NSInteger, CPAdjustmentValues)
{
    CPAdjustRawCounts,
    CPAdjustCountPerSQMile,
    CPAdjustCountPerAcre,
    CPAdjustCountPerHousingUnit,
    CPAdjustCountPerHousehold,
    CPAdjustPctOfTotalPop,
    CPAdjustPctOfTotalHousingUnits,
    CPAdjustPctOfTotalHouseholds,
    CPAdjustThousandsOfDollars,
    CPAdjustCount
};

typedef NS_ENUM(NSInteger, TXTAdjustment)
{
    TXTAdjustNone,
    TXTAdjustOwnerNames,
    TXTAdjustDollars,
    TXTAdjustThousandDollars,
    TXTAdjustDollarsPerAcre,
    TXTAdjustAcres,
    TXTAdjustDate,
    TXTAdjustCount,
    TXTAdjustCountNoZero,
    TXTAdjustCountPerHundred,
    TXTAdjustCountPerThousand
};

typedef NS_ENUM(NSInteger, AreaOutlineTypes)
{
    AreaOutlineNone,
    AreaOutlineLight,
    AreaOutlineDark,
};

typedef NS_ENUM(NSInteger, PropertyListDisplayTypes)
{
    PLD_PINMap,
    PLD_Tags,
    PLD_Areas,
};


#define MAX_NVM_TEXT_FIELDS 16

@interface NVMetroTextOptions : NSObject
@property NSString* desc;
@property int numTextFields;
@property (nonatomic)NSString* fields;
@property NSArray *formats;
NSString * formatText (LPSTR text,NSNumber * format,double acres);

@end

@interface NVMetroSettings : NSObject

+ (NVMetroSettings *)sharedInstance;

@property (nonatomic)CPFeatures currentFeature;
@property CPFeatures currentFeatureSaved;
@property MNMXCORD savedVisibleBounds;
@property (nonatomic)NSMutableArray * currentValues;
@property (nonatomic)NSArray * currentFeatureValue;
@property CPAdjustmentValues currentAdjustmentValue;
@property (nonatomic)NVMetroTextOptions* currentTextOption;
@property (nonatomic)BOOL skipZero;
@property (nonatomic)BOOL overUnder;
@property int themeClassType;
@property AreaOutlineTypes areaOutlineType;
@property int numThemeClasses;
@property int roundTo;
@property int valueMultiplier;
@property double targetValue;
@property float themeTransparency;
@property NSMutableArray * themeClassMin;
@property NSMutableArray * themeClassMax;
@property NSMutableArray * themeClassCounts;
@property NSMutableArray * themeClassAve;
@property int propertyListDisplayType;

- (void) setCurrentTextOption:(NVMetroTextOptions*)option;
- (NSArray *) features;
- (NSArray *) adjustmentOptions;
- (NSString *) currentFeatureText;
- (NSString *) currentValueText;
- (NSString *) currentTextText;
- (NSString *) currentValueFields;
- (NSString *) currentAdjustmentText;
- (NSArray *) currentTextOptions;
- (void) setCurrentValue:(NSInteger)value;
- (NSArray *) valuesForFeature:(CPFeatures)feature;
- (void) currentTextSelection:(int)index;
- (BOOL) wantUseCode:(int)code;
- (void) updateCurrentValues:(NSArray*)values;
-(NVMetroTextOptions*) textOptionsForAreas;
-(int) factorForField:(NSString *)field
              inTable:(NSString *)table
          numDecimals:(int*)pnDecimals;
- (NSArray *) textValuesForFeature:(CPFeatures)feature;

@end
