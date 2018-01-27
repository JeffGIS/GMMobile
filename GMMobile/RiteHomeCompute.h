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

@interface DATA_FROM_PARCELS : NSObject
@property  int  nMatchingProperties;
@property  int  stability5yr,
                stability15yr,
                rankTotEMV,
                pctHomestead,
                homeOwnPct,
                medianBuiltYear,
                aveBuiltYear,
                medianAgePop,
                pctChildren,
                pctSenior;
@end

@interface RiteHomeCompute:NSObject

@property PropertyData *propData;
@property PropertyList *propList;

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

@end

