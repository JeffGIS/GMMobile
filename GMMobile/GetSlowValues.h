//
//  GetSlowValues.h
//  GMMobile
//
//  Created by JEFFREY E SMITH on 4/3/16.
//  Copyright © 2016 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCodeLibrary/CCodeLibrary.h"
#import "PropertyList.h"


@interface SlowValues : NSObject
@property int nMatchingProperties;
@property int stability5yr_qtrMile;
@property int stability5yr_halfMile;
@property int stability15yr_halfMile;
@property int rankTotEMV;
@property int pctHomestead;
@property int homeOwnPct;
@property int medianBuiltYear;
@property int medianAgePop;
@property int pctChildren_qtrMile;
@property int pctChildren_halfMile;
@property int pctSenior_halfMile;
@end

@class GetSlowValues;

@protocol GetSlowValuesDelegate <NSObject>

- (void)getSlowValuesDidComplete:(int)propNum
                          values:(SlowValues *)vals;

@end

@interface GetSlowValues : NSObject
@property (nonatomic, weak) id <GetSlowValuesDelegate> delegate;
@property (nonatomic) GSSiPopoverView *popover;
//@property BoundaryData *bd;
@property int maxColors;
@property CGContextRef colorConversionContext;
@property void * colorConversionBmData;
@property PropertyList * propList;

- (void)computeSlowValues:(int)propNum
                     dbid:(int)dbid
             propertyList:(PropertyList *)plist
                  popover:(GSSiPopoverView*)popover
             aroundLatLon:(LLPOINT)latlon
                  useDesc:(LPSTR) usedescIN;
- (void) addIDtoColorByIDTable:(UINT)fileAndID
                         color:(UIColor*)color;

@end
