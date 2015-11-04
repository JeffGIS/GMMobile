//
//  ThemeLegend.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 11/2/15.
//  Copyright © 2015 GSSi. All rights reserved.
//

#import "ThemeLegend.h"

@implementation ThemeLegend

-(id) copyWithZone: (NSZone *) zone
{
    ThemeLegend *another = [[ThemeLegend allocWithZone: zone] init];
    
    another.numClasses = _numClasses;
    another.numColumns = _numColumns;
    another.aspectRatio = _aspectRatio;
    another.pctBorder = _pctBorder;
    another.pctInnerMargin = _pctInnerMargin;
    another.pctSymbol = _pctSymbol;
    another.pctTitle = _pctTitle;
    another.borderColor = [[UIColor alloc]initWithCGColor:_borderColor.CGColor];
    another.titleBkColor = [[UIColor alloc]initWithCGColor:_titleBkColor.CGColor];
    another.titleTxColor = [[UIColor alloc]initWithCGColor:_titleTxColor.CGColor];
    another.classBkColor = [[UIColor alloc]initWithCGColor:_classBkColor.CGColor];
    another.classTxColor = [[UIColor alloc]initWithCGColor:_classTxColor.CGColor];
    another.title = [NSString stringWithString:_title];
    
    return another;
}
@end
