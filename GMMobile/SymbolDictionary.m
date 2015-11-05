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

static DPOINT Cross[]={-2,1,-5,4,-4,5,-1,2,1,2,4,5,5,4,2,1,2,-1,5,-4,4,-5,1,-2,-1,-2,-4,-5,-5,-4,-2,-1,-2,1};
static DPOINT Plus[]={-2,2,-2,5,2,5,2,2,5,2,5,-2,2,-2,2,-5,-2,-5,-2,-2,-5,-2,-5,2,-2,2};
static DPOINT Diamond[]={-5,0,0,5,5,0,0,-5,-5,0};
static DPOINT Triangle[]={-5,-5,0,5,5,-5,-5,-5};
static DPOINT Star1[]={-5,0,-1.5,1.5,0,5,1.5,1.5,5,0,1.5,-1.5,0,-5,-1.5,-1.5,-5,0};
static DPOINT Star2[]={0,5,1.1,1.3,5,1.3,1.9,-1.1,3,-5,0,-2.6,-3,-5,-2,-1.1,-5,1.3,-1.1,1.3,0,5};
static DPOINT Square[]={-5,5,5,5,5,-5,-5,-5,-5,5};
+ (void)drawPointWithSymbol:(CGContextRef)context
                         at:(LPDPOINT)pt
                usingSymbol:(PointSymbols)sym
                       Size:(CGFloat)size
                  fillColor:(CGColorRef)fcolor
                  lineColor:(CGColorRef)lcolor
                  lineWidth:(CGFloat)lwidth
{
    CGContextSetFillColorWithColor(context,fcolor);
    CGContextSetLineWidth(context, lwidth);
    CGContextSetStrokeColorWithColor(context,lcolor);
    
    if (sym == CircleSym)
    {
        CGRect pointRect = CGRectMake((pt->x - size / 2.0),
                                      (pt->y - size / 2.0), size, size);

        CGContextStrokeEllipseInRect(context, pointRect);
    }
    else
    {
        LPDPOINT pPoints;
        int nPt;
         switch (sym)
        {
            case CrossSym:
                pPoints = Cross;
                nPt = sizeof (Cross)/sizeof(DPOINT);
                break;
            case PlusSym:
                pPoints = Plus;
                nPt = sizeof (Plus)/sizeof(DPOINT);
                break;
            case DiamondSym:
                pPoints = Diamond;
                nPt = sizeof (Diamond)/sizeof(DPOINT);
                break;
            case TriangleSym:
                pPoints = Triangle;
                nPt = sizeof (Triangle)/sizeof(DPOINT);
                break;
            case SquareSym:
                pPoints = Square;
                nPt = sizeof (Square)/sizeof(DPOINT);
                break;
            case Star1Sym:
                pPoints = Star1;
                nPt = sizeof (Star1)/sizeof(DPOINT);
                break;
            case Star2Sym:
                pPoints = Star2;
                nPt = sizeof (Star2)/sizeof(DPOINT);
                break;
            case ArsonSym:
                pPoints = Cross;
                nPt = sizeof (Cross)/sizeof(DPOINT);
                break;
                
        }
        CGContextMoveToPoint(context, Adjust(pPoints[0].x,pt->x,size), Adjust(pPoints[0].y,pt->y,size));
        for (int i = 1; i < nPt; i++)
        {
            CGContextAddLineToPoint(context, Adjust(pPoints[i].x,pt->x,size),Adjust(pPoints[i].y,pt->y,size));
        }
        
        if (!CGContextIsPathEmpty(context))
        {
            CGContextFillPath(context);
            //CGContextDrawPath(context, kCGPathStroke);
        }
    }

}

@end
