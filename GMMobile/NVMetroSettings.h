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
    CPFBlocks,
    CPFBlockGroups,
    CPFTracts,
    CPFVoterDistricts,
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
@property BOOL OverUnder;


- (NSArray *) features;
- (NSString *) currentFeatureText;
- (NSString *) currentValueText;
- (void) setCurrentValue:(NSInteger)value;
- (NSArray *) valuesForFeature:(CPFeatures)feature;

@end
