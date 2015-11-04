//
//  ThemeLegend.h
//  GMMobile
//
//  Created by JEFFREY E SMITH on 11/2/15.
//  Copyright © 2015 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ThemeClass.h"

@interface ThemeLegend : NSObject

@property int numClasses;
@property int numColumns;
@property float aspectRatio;    // width/height
@property float pctBorder;      // border width as percentage of largest dimension
@property float pctTitle;       // percentage of legend height allocated to title
@property float pctMargin;      // outer margin as percentage of largest dimension
@property float pctInnerMargin; // inner margin as percentage of largest dimension
@property float pctSymbol;      // percentage of class allocated to symbol

@property UIColor*borderColor;  // color of outer border
@property UIColor*titleBkColor; // color of title background
@property UIColor*titleTxColor; // color of title text
@property UIColor*classBkColor; // color of class background
@property UIColor*classTxColor; // color of class text

@property NSString* title;



@end
