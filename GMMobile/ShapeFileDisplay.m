//
//  ShapeFileDisplay.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 1/20/16.
//  Copyright © 2016 GSSi. All rights reserved.
//

#import "ShapeFileDisplay.h"

@interface ShapeFileDisplay ()

@property (nonatomic) LPTRANDATA pTranLLtoView, pTranViewtoLL;

@end

@implementation ShapeFileDisplay

+ (ShapeFileDisplay *)createWithFile:(const char*)shapeFile
{
    char outFile[MAX_PATH];
    SHPHandle hSHP;
    DBFHandle hDBF;
    ShapeFileDisplay * sfd = NULL;
    BOOL first = TRUE;
    
    if (!shapeFile)
        return NULL;
    sprintf (outFile,"%s",shapeFile);
    char * pFS = strrchr (outFile,'/');
    if (pFS)
    {
        char * pFS2 = strrchr (shapeFile,'/');
        sprintf (pFS,"/latlon%s",pFS2);
    }
    else
        return NULL;
    
Top:
    hSHP = SHPOpen( outFile, "rb" );
    if( hSHP != NULL )
    {
        hDBF = DBFOpen ( outFile, "rb" );
        if (hDBF == NULL)
        {
            SHPClose (hSHP);
            return NULL;
        }
        sfd = [[ShapeFileDisplay alloc]init];
        sfd.hSHP = hSHP;
        sfd.hDBF = hDBF;
    }
    else if (first)
    {
        first = FALSE;
        char * args[5];
        char inprj[] = {"-i=proj=utm zone=15 units=m datum=NAD83 no_defs" };//+proj=utm +zone=15 +datum=NAD83 +units=m +no_defs
        char outprj[] = "-o=proj=latlong datum=WGS84";
        args[1] = shapeFile;
        args[2] = outFile;
        args[3] = inprj;
        args[4] = outprj;
        [NSFileManager.defaultManager createDirectoryAtPath:[ [NSString stringWithUTF8String:outFile] stringByDeletingLastPathComponent]
                                withIntermediateDirectories:YES
                                                 attributes:nil
                                                      error:nil];
        if (TransformSHP (5,args))
            goto Top;
   }
   return sfd;
}
- (void)dealloc
{
    if (_hSHP)
        SHPClose(_hSHP);
    if (_hDBF)
        DBFClose(_hDBF);
}

-(void)  display:(CGContextRef)context
displayCharacteristics:(DisplayCharacteristics *)dc
       llCorners:(CORNERPOINTS *) latlonCornerPoints
        LLBounds:(MNMXCORD *)platlonBounds
      viewBounds:(MNMXCORD *)pvbounds
          themes:(Themes*)themes
     pointInArea:(PointInArea *)pia
{
    CGFloat size = 20;
    CGFloat sizeFactor = 5;
    if (_zoom > 18)
     sizeFactor *= (2.0 *(_zoom - 18.0));
     
     else if (_zoom < 18)
     sizeFactor /= (2.0 * (18.0 - _zoom));

    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    
    _pTranLLtoView = STRANCornersToBounds(latlonCornerPoints, pvbounds);
    
    for (int irec = 0; irec < _hSHP->nRecords; irec++)
    {
        SHPObject *psCShape = SHPReadObject (_hSHP, irec );
        
        switch (psCShape->nSHPType)
        {
            case SHPT_POINT:
            {
                DPOINT pt;
                pt.x = psCShape->padfX[0];
                pt.y = psCShape->padfY[0];
                pt = TranDPOINT(&pt, _pTranLLtoView);
                dc.color = [UIColor colorWithRed:1 green:0 blue:0 alpha:1];
                [self drawPoint:context
                        atPoint:&pt
                    usingSymbol:CircleSym
                     withColor:dc.color.CGColor
                      andSize:(size * sizeFactor)];
            }
                break;
            default:
            {
                [self drawLine:context
                       nPoints:psCShape->nVertices
                        nLoops:psCShape->nParts
                       partLen:psCShape->panPartStart
                             x:psCShape->padfX
                             y:psCShape->padfY
                     withColor:UIColor.blackColor.CGColor
                      andWidth:3];
            }
        }
        SHPDestroyObject ( psCShape );
    }
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
}


- (void)drawLine:(CGContextRef)context
         nPoints:(int)np
          nLoops:(int)nLoops
         partLen:(int *)pPartIndex
               x:(double *)pX
               y:(double *)pY
       withColor:(CGColorRef)color
        andWidth:(CGFloat)width
{
    CGContextSetLineWidth(context, width);
    
    LPDPOINT llpoints = malloc(np * sizeof(DPOINT) + 4);
    //symName = (LPSTR)sqlite3_column_text(statement,6);
    
    
    for (int i = 0; i < np; i++)
    {
        llpoints[i].x = pX[i];
        llpoints[i].y = pY[i];
        llpoints[i] = TranDPOINT(&llpoints[i], _pTranLLtoView);
    }
    if (nLoops > 1)
    {
        int ip = 0;
        //int ii;
        
        for (int loop=0; loop < nLoops; loop++)
        {
            CGContextMoveToPoint(context, llpoints[ip].x, llpoints[ip].y);
            ip = pPartIndex[loop];
            //ii = pPartLen[loop];
            int lp = np - pPartIndex[loop];
            if (loop < nLoops - 1)
                lp = pPartIndex[loop+1] - pPartIndex[loop];
            for (int i = 1; i < lp; i++)
            {
                CGContextAddLineToPoint(context, llpoints[ip].x, llpoints[ip].y);
                ip++;
            }
            
            //if (loop)
            //    ip++;
            
            if (!CGContextIsPathEmpty(context))
            {
                CGContextSetStrokeColorWithColor(context,color);
                CGContextDrawPath(context, kCGPathStroke);
            }
        }
        
        //ii = ip;
    }
    
    else
    {
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathMoveToPoint(path,0,llpoints[0].x, llpoints[0].y);
        
        for (int i = 1; i < np; i++)
            CGPathAddLineToPoint(path,0,llpoints[i].x, llpoints[i].y);
        
        if (!CGPathIsEmpty(path))
        {
            if (ConfigurationControl.sharedInstance.GMTilesVisible)
            {
                CGContextSetLineWidth(context, width*2);
                CGContextSetStrokeColorWithColor(context,UIColor.whiteColor.CGColor);
                CGContextAddPath(context, path);
                CGContextDrawPath(context, kCGPathStroke);
                CGContextSetLineWidth(context, width);
            }
            CGContextAddPath(context, path);
            CGContextSetStrokeColorWithColor(context,color);
            CGContextDrawPath(context, kCGPathStroke);
        }
        CGPathRelease(path);
    }

}
- (void)drawPoint:(CGContextRef)context
               atPoint:(DPOINT *)pPoint
           usingSymbol:(PointSymbols)sym
             withColor:(CGColorRef)color
               andSize:(CGFloat)size

{
    [SymbolDictionary drawPointWithSymbol:context
                                       at:pPoint
                              usingSymbol:sym
                                     Size:size
                                fillColor:color
                                lineColor:0
                                lineWidth:size/5];
    
}


@end
