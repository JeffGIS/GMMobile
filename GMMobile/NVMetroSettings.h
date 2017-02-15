//
//  NVMetroSettings.h
//  NVMobile
//
//  Created by Jeff Smith on 12/23/16.
//  Copyright © 2016 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMaps/GoogleMaps.h>

CORNERPOINTS CornerPointsFromRegion (GMSVisibleRegion region);

typedef NS_ENUM(NSInteger, CPFeatures)
{
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
    CPAdjustPctOfTotalPop,
    CPAdjustPctOfTotalHousingUnits,
    CPAdjustCount
};

typedef NS_ENUM(NSInteger, TXTAdjustment)
{
    TXTAdjustNone,
    TXTAdjustOwnerNames,
    TXTAdjustDollars,
    TXTAdjustDollarsPerAcre,
    TXTAdjustAcres,
    TXTAdjustDate,
    TXTAdjustCount
};

typedef NS_ENUM(NSInteger, AreaOutlineTypes)
{
    AreaOutlineNone,
    AreaOutlineLight,
    AreaOutlineDark,
};


#define MAX_NVM_TEXT_FIELDS 16

@interface NVMetroTextOptions : NSObject
@property NSString* desc;
@property int numTextFields;
@property (nonatomic)NSString* fields;
@property NSArray *formats;

@end

@interface NVMetroSettings : NSObject

+ (NVMetroSettings *)sharedInstance;

@property (nonatomic)CPFeatures currentFeature;
@property CPFeatures currentFeatureSaved;
@property MNMXCORD savedVisibleBounds;
@property (nonatomic)NSMutableArray * currentValues;
@property (nonatomic)NSArray * currentFeatureValue;
@property CPAdjustmentValues currentAdjustmentValue;
@property NVMetroTextOptions* currentTextOption;
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



@end
