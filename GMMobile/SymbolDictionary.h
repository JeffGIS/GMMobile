//
//  SymbolDictionary.h
//  GMMobile
//
//  Created by Bill Munson on 11/5/15.
//  Copyright © 2015 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCodeLibrary/CCodeLibrary.h"


@interface SymbolDictionary : NSObject

+ (void)drawPointWithSymbol:(CGContextRef)context
                         at:(LPDPOINT)pt
                usingSymbol:(PointSymbols)sym
                       Size:(CGFloat)size
                  fillColor:(CGColorRef)fcolor
                  lineColor:(CGColorRef)lcolor
                  lineWidth:(CGFloat)lwidth;

UIImage *imageFromSymbol(PointSymbols sym, CGFloat size, UIColor *symColor);

@end
