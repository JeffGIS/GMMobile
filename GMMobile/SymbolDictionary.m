//
//  SymbolDictionary.m
//  GMMobile
//
//  Created by Bill Munson on 11/5/15.
//  Copyright © 2015 GSSi. All rights reserved.
//

#import "SymbolDictionary.h"

static double Adjust (double sym,double loc, double size)
{
    double adjusted = sym * 0.2 * size + loc;
    return adjusted;
}

@implementation SymbolDictionary

static DPOINT Cross[]={-2,2,-2,5,2,5,2,2,5,2,5,-2,2,-2,2,-5,-2,-5,-2,-2,-5,-2,-5,2,-2,2};

static DPOINT Plus[]={-2,2,-2,5,2,5,2,2,5,2,5,-2,2,-2,2,-5,-2,-5,-2,-2,-5,-2,-5,2,-2,2};


+ (void)drawPointWithSymbol:(CGContextRef)context
                         at:(LPDPOINT)pt
                       Size:(CGFloat)size
                  fillColor:(CGColorRef)fcolor
                  lineColor:(CGColorRef)lcolor
                  lineWidth:(CGFloat)lwidth
{
    CGContextSetFillColorWithColor(context,fcolor);
    CGContextSetLineWidth(context, lwidth);
    CGContextSetStrokeColorWithColor(context,lcolor);
    LPDPOINT pPoints = Cross;
    int nPt = sizeof (Cross)/sizeof(DPOINT);
    CGContextMoveToPoint(context, Adjust(pPoints[0].x,pt->x,size), Adjust(pPoints[0].y,pt->y,size));
    for (int i = 1; i < nPt; i++)
    {
        CGContextAddLineToPoint(context, Adjust(pPoints[i].x,pt->x,size),Adjust(pPoints[i].y,pt->y,size));
    }
    
    if (!CGContextIsPathEmpty(context))
    {
        CGContextFillPath(context);
        CGContextDrawPath(context, kCGPathStroke);
    }
}

@end
