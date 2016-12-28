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
    CPFLandUse,
    CPFBlocks,
    CPFBlockGroups,
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

typedef NS_ENUM(NSInteger, CPBlockValues)
{
    CPBlockVNone,
    CPBlockVCount
};



@interface NVMetroSettings : NSObject

+ (NVMetroSettings *)sharedInstance;

@property CPFeatures currentFeature;
@property int currentFeatureValue;
@property BOOL OverUnder;
@property int themeClassType;
@property int numThemeClasses;
@property int roundTo;
@property int valueMultiplier;
@property NSMutableArray * themeClassMin;
@property NSMutableArray * themeClassMax;
@property NSMutableArray * themeClassCounts;



- (NSArray *) features;
- (NSString *) currentFeatureText;
- (NSString *) currentValueText;
- (NSString *) currentValueField;
- (void) setCurrentValue:(NSInteger)value;
- (NSArray *) valuesForFeature:(CPFeatures)feature;

@end
