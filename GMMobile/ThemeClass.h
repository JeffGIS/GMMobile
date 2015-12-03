//
//  ThemeClass.h
//  GMMobile
//
//  Created by JEFFREY E SMITH on 11/2/15.
//  Copyright © 2015 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCodeLibrary/CCodelibrary.h"

@interface ThemeClass : NSObject

@property NSString* title;
@property double count;
@property int numItems;
@property int status;
@property float pctOfTotal;
@property float symbolWidth;
@property UIColor * color;
@property float size;
@property PointSymbols symbol;

+ (ThemeClass*) createWithTitle:(NSString*)title;

@end
