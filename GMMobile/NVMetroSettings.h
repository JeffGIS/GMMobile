//
//  NVMetroSettings.h
//  NVMobile
//
//  Created by Jeff Smith on 12/23/16.
//  Copyright © 2016 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>

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



@interface NVMetroSettings : NSObject

+ (NVMetroSettings *)sharedInstance;

@property (nonatomic)CPFeatures currentFeature;
@property (nonatomic) int currentFeatureValue;
@property CPAdjustmentValues currentAdjustmentValue;
@property BOOL OverUnder;
@property int themeClassType;
@property int numThemeClasses;
@property int roundTo;
@property int valueMultiplier;
@property NSMutableArray * themeClassMin;
@property NSMutableArray * themeClassMax;
@property NSMutableArray * themeClassCounts;
@property NSMutableArray * themeClassAve;



- (NSArray *) features;
- (NSArray *) adjustmentOptions;
- (NSString *) currentFeatureText;
- (NSString *) currentValueText;
- (NSString *) currentValueField;
- (NSString *) currentAdjustmentText;
- (void) setCurrentValue:(NSInteger)value;
- (NSArray *) valuesForFeature:(CPFeatures)feature;
- (BOOL) wantUseCode:(int)code;


@end
