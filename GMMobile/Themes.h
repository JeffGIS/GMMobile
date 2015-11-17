//
//  Themes.h
//  GMMobile
//
//  Created by JEFFREY E SMITH on 11/17/15.
//  Copyright © 2015 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Theme.h"
#import "ConfigurationControl.h"

@interface Themes : NSObject
@property NSMutableArray *themeList;
@property int displayID;

- (void) setAppThemes;
- (ItemProcessingPassTypes) themesNeedDataPass:(int)displayID;
- (void) themesBeginDataPass:(int)displayID;
- (void) themesEndDataPass:(int)displayID;
- (void) themesBeginDisplayPass:(int)displayID;
- (void) themesEndDisplayPass:(int)displayID;
- (int) setDisplayCharacteristics:(DisplayCharacteristics *)dc
                        displayID:(int)displayID;


@end
