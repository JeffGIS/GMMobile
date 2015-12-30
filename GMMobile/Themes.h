//  Themes.h
//  GMMobile

@import UIKit;
#import "Theme.h"
#import "ConfigurationControl.h"

@interface Themes : NSObject
@property NSMutableArray *themeList;
@property int displayID;

- (void) setAppThemes;
- (ItemProcessingPassTypes)themesNeedDataPass:(int)displayID;
- (void) themesBeginDataPass:(int)displayID;
- (void) themesEndDataPass:(int)displayID;
- (void) themesBeginDisplayPass:(int)displayID;
- (void) themesEndDisplayPass:(int)displayID;

- (int) setDisplayCharacteristics:(DisplayCharacteristics *)dc
                        displayID:(int)displayID;

- (void) getMinMaxUCR:(int)range
                  min:(int *)minUCR
                  max:(int *)maxUCR;

- (BOOL) getMinMaxTime:(int)range
                   min:(int *)minTime
                   max:(int *)maxTime;

- (int) getNumUCRRanges;
- (int) getNumTimeRanges;

@end