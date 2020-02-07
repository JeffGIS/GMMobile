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
@property  int  stability_5yr, activity_5yr,
stability_15yr, activity_15yr,
rankTotEMV,
pctHomestead,
medianBuiltYear,
aveBuiltYear,
pctNew_10yr,
pctNew_25yr,
pctNoTax;
@end

@interface BLOCK_TOTALS : NSObject
@property  int  numBlocks;
@property  double  totPop,
totHouseholds,
aveHHSize,
totPopPerSqMile,
totlivedAlone,
totmarrKids,
totunMarrKids,
totfamNoKids,
totnonFamily,
tothhwithChildren,
tothhwithSeniors,
totowneroccupied,
totrenteroccupied,
totvacant,
totmedianAge,
totmedianAdultAge,
totmedianChildAge;
@property double
M_0_4,
M_5_9,
M_10_14,
M_15_19,
M_20_24,
M_25_29,
M_30_34,
M_35_39,
M_40_44,
M_45_49,
M_50_54,
M_55_59,
M_60_64,
M_65_69,
M_70_74,
M_75_79,
M_80_84,
M_OVER85,
F_0_4,
F_5_9,
F_10_14,
F_15_19,
F_20_24,
F_25_29,
F_30_34,
F_35_39,
F_40_44,
F_45_49,
F_50_54,
F_55_59,
F_60_64,
F_65_69,
F_70_74,
F_75_79,
F_80_84,
F_OVER85;

@end

@interface DATA_FROM_BLOCKS : NSObject
@property  double aveHHSize;
@property  int  totPop,
totHouseholds,
popPerSqMile,
livedAlone,
marrKids,
unMarrKids,
famNoKids,
nonFamily,
pctWithChildren,
pctWithSeniors,
pctOwneroccupied,
pctRenteroccupied,
pctVacant;
@property double
medianAge,
medianAdultAge,
medianAdultAgeMale,
medianAdultAgeFemale,
medianChildAge,
medianChildAgeMale,
medianChildAgeFemale;

@end

@interface DATA_FROM_LANDUSE : NSObject
@property  int
PCT_SingleFamilyResidential,
PCT_MultiFamilyResidential,
PCT_MixedUseResidential,
PCT_RetailCommercial,
PCT_Office,
PCT_Industrial,
PCT_Institutional,
PCT_HighwayRailway,
PCT_Airport,
PCT_ParkRecPreserve,
PCT_Agriculture,
PCT_Undeveloped,
PCT_Water;

@end

@interface RiteHomeCompute:NSObject

@property PropertyData *propData;
@property PropertyList *propList;
@property double totalAreaInSqMiles;

+(NSString *) parcelFieldList;
+(NSString *) blockFieldList;

- (bool)computeValuesFromParcelsInCensus:(DATA_FROM_PARCELS *)values
                            inCensusArea:(LPSTR)cenBlockIN
                                  totEMV:(int)totEMV
                                 useDesc:(LPSTR) usedescIN;

- (bool)computeValuesFromParcelsInCensus:(DATA_FROM_PARCELS *)values
                            inCensusArea:(LPSTR)cenBlockIN
                  orAssociatedCensusArea:(LPSTR)cenBlockAssociated
                                onStreet:(NSString *)street
                                  totEMV:(int)totEMV
                                 useDesc:(LPSTR) usedescIN;

- (bool)computeValuesFromParcelsInCircle:(DATA_FROM_PARCELS *)values
                             forProperty:(int)propNum
                                inCircle:(int)circleID
                                  totEMV:(int)totEMV
                                 useDesc:(LPSTR) usedescIN;

- (DATA_FROM_BLOCKS *)computeValuesFromBlocksInCircle:(int)circleID
                                          forProperty:(int)propNum;

- (bool)computeValuesFromLandUseInCircle:(DATA_FROM_LANDUSE *)values
                             forProperty:(int)propNum
                                inCircle:(int)circleID;

- (DATA_FROM_BLOCKS *)computeValuesFromCensus:(LPSTR)blockOrBlockGroup;

@end

