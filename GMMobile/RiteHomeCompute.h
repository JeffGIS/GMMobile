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

@end

@interface DATA_FROM_BLOCKS : NSObject
@property  int  nMatchingPropertiesx;
@property  int  totPop,
totHouseholds,
popPerSqMile,
livedAlone,
marrKids,
unMarrKids,
famNoKids,
nonFamily,
medianAge,
medianAdultAge,
medianChildAge,
pctWithChildren,
pctWithSeniors,
pctOwneroccupied,
pctRenteroccupied,
pctVacant;


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

