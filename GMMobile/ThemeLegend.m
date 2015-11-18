//
//  ThemeLegend.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 11/2/15.
//  Copyright © 2015 GSSi. All rights reserved.
//

#import "ThemeLegend.h"
#import "CCodeLibrary/UserDefaults.h"

@implementation ThemeLegend

-(id) copyWithZone: (NSZone *) zone
{
    ThemeLegend *another = [[ThemeLegend allocWithZone: zone] init];
    
    another.numCells = _numCells;
    another.numColumns = _numColumns;
    another.aspectRatio = _aspectRatio;
    another.drawOnMap  = self.drawOnMap;
    another.pctBorder = _pctBorder;
    another.pctInnerMargin = _pctInnerMargin;
    another.pctSymbol = _pctSymbol;
    another.pctTitle = _pctTitle;
    another.usePointSymbols= _usePointSymbols;
    another.useClassColors = _useClassColors;
    another.appendClassCount = _appendClassCount;
    another.borderColor = [[UIColor alloc]initWithCGColor:_borderColor.CGColor];
    another.titleBkColor = [[UIColor alloc]initWithCGColor:_titleBkColor.CGColor];
    another.titleTxColor = [[UIColor alloc]initWithCGColor:_titleTxColor.CGColor];
    another.labelBkColor = [[UIColor alloc]initWithCGColor:_labelBkColor.CGColor];
    another.labelTxColor = [[UIColor alloc]initWithCGColor:_labelTxColor.CGColor];
    another.symbolDefaultColor = [[UIColor alloc]initWithCGColor:_symbolDefaultColor.CGColor];
    another.title = [NSString stringWithString:_title];
    another.cells = [[NSMutableArray alloc]init];
    another.portraitMapOrigin = _portraitMapOrigin;
    another.landscapeMapOrigin = _landscapeMapOrigin;
    another.isDraggedLandscape = _isDraggedLandscape;
    another.isDraggedPortrait = _isDraggedPortrait;
    
    for (ThemeLegendCell *cl in _cells)
    {
        ThemeLegendCell *newCell = [cl copy];
        [another.cells addObject:newCell];
    }
    
    return another;
}

- (BOOL)drawOnMap
{
    return [UserDefaults.defaults boolForKey:[NSString stringWithFormat:@"ThemeLegend%@", _title]];
}

- (void)setDrawOnMap:(BOOL)drawOnMap
{
    [UserDefaults.defaults saveBool:drawOnMap
                             forKey:[NSString stringWithFormat:@"ThemeLegend%@", _title]];
}

@end