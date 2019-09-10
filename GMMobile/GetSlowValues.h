//
//  GetSlowValues.h
//  GMMobile
//
//  Created by JEFFREY E SMITH on 4/3/16.
//  Copyright © 2016 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCodeLibrary/CCodeLibrary.h"
#import "PropertyListFields.h"

#define OneMileInMeters 5280 * FTM
static double circleRadiusInMiles[4] = {1.0 / 8,1.0 / 4,1.0 / 2,1.0};
static double circleRadiusInMeters[4] = {OneMileInMeters / 8,OneMileInMeters / 4,OneMileInMeters / 2,OneMileInMeters};

@class GetSlowValues;

@protocol GetSlowValuesDelegate <NSObject>

- (void) getSlowValuesDidComplete:(int)propNum
                      totComputes:(float)totComputes
                      numComputes:(float)nComputes;
- (BOOL)executePropListCommand:(NSString*)cmd;
- (void) addIntegerToProplist:(int)value
                    withCode:(PropFieldType)code;
- (void) addDoubleToProplist:(double)value
                    withCode:(PropFieldType)code;

@end

@interface GetSlowValues : NSObject<GSSiPopoverViewDelegate>
@property (nonatomic, weak) id <GetSlowValuesDelegate> delegate;
@property (nonatomic) GSSiPopoverView *popover;
//@property BoundaryData *bd;
@property int maxColors;
@property CGContextRef colorConversionContext;
@property void * colorConversionBmData;

- (void)computeSlowValues:(int)propNum
                     dbid:(int)dbid
                 delegate:(id)delegate
                  popover:(GSSiPopoverView*)popover
             aroundLatLon:(LLPOINT)latlon
                  useDesc:(LPSTR) usedescIN;
- (void) addIDtoColorByIDTable:(UINT)fileAndID
                         color:(UIColor*)color;

@end
