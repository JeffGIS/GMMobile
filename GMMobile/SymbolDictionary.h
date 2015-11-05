//
//  SymbolDictionary.h
//  GMMobile
//
//  Created by Bill Munson on 11/5/15.
//  Copyright © 2015 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCodeLibrary/CCodeLibrary.h"


typedef NS_ENUM(NSInteger, PointSymbols)
{
    CrossSym,
    PlusSym,
    DiamondSym,
    TriangleSym,
    SquareSym,
    Star1Sym,
    Star2Sym,
    CircleSym,
    ArsonSym,
};

@interface SymbolDictionary : NSObject

+ (void)drawPointWithSymbol:(CGContextRef)context
                         at:(LPDPOINT)pt
                       Size:(CGFloat)size
                  fillColor:(CGColorRef)fcolor
                  lineColor:(CGColorRef)lcolor
                  lineWidth:(CGFloat)lwidth;

@end
