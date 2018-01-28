//
//  RiteHomeCompute.h
//  NVMobile
//
//  Created by JEFFREY E SMITH on 1/25/18.
//  Copyright © 2018 GSSi. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "PropertyData.h"
#import "BoundaryData.h"
#import "CCodeLibrary/SQLiteLib.h"
#import "PropertyList.h"

typedef NS_ENUM(int, LandUseClassification)
{
    LUC_SingleFamilyResidential,
    LUC_MultiFamilyResidential,
    LUC_MixedUseResidential,
    LUC_RetailCommercial,
    LUC_Office,
    LUC_Industrial,
    LUC_Institutional,
    LUC_HighwayRailway,
    LUC_Airport,
    LUC_ParkRecPreserve,
    LUC_Agriculture,
    LUC_Undeveloped,
    LUC_Water,
    LUC_Count
};

@interface DATA_FROM_PARCELS : NSObject
@property  int  nMatchingProperties;
@property  int  stability_5yr,
stability_15yr,
rankTotEMV,
pctHomestead,
medianBuiltYear,
aveBuiltYear,
pctNew_10yr,
pctNew_25yr,
pctNoTax;
@end

@interface DATA_FROM_BLOCKS : NSObject
@property  int  nMatchingProperties;
@property  int  totPop,
totPopPerSqMile,
rankTotEMV,
pctHomestead,
medianBuiltYear,
aveBuiltYear,
pctNew_10yr,
pctNew_25yr,
pctNoTax;
@end

@interface DATA_FROM_LANDUSE : NSObject
@property  int  nMatchingProperties;
@property  int  totPop,
totPopPerSqMile,
rankTotEMV,
pctHomestead,
medianBuiltYear,
aveBuiltYear,
pctNew_10yr,
pctNew_25yr,
pctNoTax;
@end

@interface RiteHomeCompute:NSObject

@property PropertyData *propData;
@property PropertyList *propList;
@property double circleAreaInSqMiles;

+(NSString *) parcelFieldList;
- (bool)computeValuesFromParcelsInCensus:(DATA_FROM_PARCELS *)values
                            inCensusArea:(LPSTR)cenBlockIN
                                  totEMV:(int)totEMV
                                 useDesc:(LPSTR) usedescIN;

- (bool)computeValuesFromParcelsInCircle:(DATA_FROM_PARCELS *)values
                             forProperty:(int)propNum
                                inCircle:(int)circleID
                                  totEMV:(int)totEMV
                                 useDesc:(LPSTR) usedescIN;

- (bool)computeValuesFromBlocksInCircle:(DATA_FROM_BLOCKS *)values
                            forProperty:(int)propNum
                               inCircle:(int)circleID;

- (bool)computeValuesFromLandUseInCircle:(DATA_FROM_LANDUSE *)values
                            forProperty:(int)propNum
                               inCircle:(int)circleID;

@end

