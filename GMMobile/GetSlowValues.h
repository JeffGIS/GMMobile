//
//  GetSlowValues.h
//  GMMobile
//
//  Created by JEFFREY E SMITH on 4/3/16.
//  Copyright © 2016 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCodeLibrary/CCodeLibrary.h"


@class GetSlowValues;

@protocol GetSlowValuesDelegate <NSObject>

- (void) getSlowValuesDidComplete:(int)propNum
                      totComputes:(int)totComputes
                      numComputes:(int)nComputes;
- (BOOL)executePropListCommand:(NSString*)cmd;
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
