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

- (BOOL)continue
{
    if (self.processingID == CRAPI.sharedInstance.keepProcessing)
        return YES;
    
    return NO;
}
- (id)init
{
    self = [super init];
    
    if (self)
    {
        _documentsDirectory = UserDefaults.defaults.sharedFilePath;
    }
    
    return self;
}

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
/*    if (first)
        hSHP = NULL;
    else*/
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
        sfd.filePath = [NSString stringWithUTF8String:shapeFile];
        sfd.fileName = [sfd.filePath lastPathComponent];
    }
    else if (first)
    {
        first = FALSE;
        char * args[5];
        //char inprj_utm[] = {"-i=proj=utm zone=15 units=m datum=NAD83 no_defs" };//+proj=utm +zone=15 +datum=NAD83 +units=m +no_defs
        char inprj_utm[] = {"+proj=utm +zone=15 +datum=NAD83 +units=m +no_defs"};
        char inprj_hc[] = {"+proj=lcc +lat_1=45.13333333 +lat_2=44.88333333 +lat_0=44.79111111 +lon_0=-93.38333333 +x_0=152400.3048006096 +y_0=30480.06096012192 +a=6378418.941 +b=6357033.31 +units=us-ft +no_defs"};
        char outprj[] = "+proj=latlong +datum=WGS84";
        args[1] = (char *)shapeFile;
        args[2] = outFile;
        args[3] = inprj_utm;
        if (strstr (shapeFile,"Fiber"))
            args[3] = inprj_hc;
        
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
    _dc = dc.copy;
    _dc.size = 1;
    _dc.width = 1;
    _sizeFactor = 100;

    if (_zoom > 18)
        _sizeFactor *= (2.0 *(_zoom - 18.0));
    else if (_zoom < 18)
        _sizeFactor /= (2.0 * (18.0 - _zoom));
    _widthFactor = _sizeFactor / 15;
    
    dc.string1 = _fileName;
    
    if ([_fileName containsString:@"Meter"])
    {
        dc.pointSymbol = Star2Sym;
        dc.color = [UIColor colorWithRed:0 green:0 blue:1 alpha:1];
        _sizeFactor *=1.5;
    }
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    
    _pTranLLtoView = STRANCornersToBounds(latlonCornerPoints, pvbounds);
    [self processShape:context highlightList:nil LLBounds:platlonBounds themes:themes];
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
}

- (void)processShape:(CGContextRef)context
       highlightList:(NSMutableArray*)hlist
            LLBounds:(MNMXCORD *)platlonBounds
              themes:(Themes*)themes
{
    double mind = DBL_MAX;
    DPOINT midpt, minpt;
    NSInteger minRef = 0;
    NSString * minPlatID = @"";
    
    midpt = DBoundsMid(platlonBounds);
    for (int irec = 0; irec < _hSHP->nRecords; irec++)
    {
        if (![self continue])
            break;
        SHPObject *psCShape = SHPReadObject (_hSHP, irec );
        MNMXCORD SHPBounds;
        SHPBounds.xmn = psCShape->dfXMin;
        SHPBounds.xmx = psCShape->dfXMax;
        SHPBounds.ymn = psCShape->dfYMin;
        SHPBounds.ymx = psCShape->dfYMax;
        _dc.refno = irec;
        if (BoundsInBounds (&SHPBounds,platlonBounds,1))
        {
            
            switch (psCShape->nSHPType)
            {
                case SHPT_POINT:
                case SHPT_POINTZ:
                case SHPT_POINTM:
                {
                    DPOINT pt;
                    pt.x = psCShape->padfX[0];
                    pt.y = psCShape->padfY[0];
                    pt = TranDPOINT(&pt, _pTranLLtoView);
                    int iField, fieldWidth, nDecimals;
                    char fieldName[32];
                    switch (_dc.elementType)
                    {
                        case Hydrant:
                        {
                            iField = DBFGetFieldIndex(_hDBF, "Model");
                            if (iField >= 0)
                            {
                                DBFGetFieldInfo(_hDBF,iField,
                                                fieldName, &fieldWidth, &nDecimals );
                                const char * cModel = DBFReadStringAttribute( _hDBF,irec,iField );
                                if (!strcasecmp (cModel,"Single Pumper"))
                                    _dc.pointSymbol = TriangleSym;
                                else if (!strcasecmp (cModel,"Double Pumper"))
                                    _dc.pointSymbol = SquareSym;
                                else _dc.pointSymbol = Star1Sym;
                            }
                            iField = DBFGetFieldIndex(_hDBF, "Nozzle");
                            if (iField >= 0)
                            {
                                DBFGetFieldInfo(_hDBF,iField,
                                                fieldName, &fieldWidth, &nDecimals );
                                const char * cNozzle = DBFReadStringAttribute( _hDBF,irec,iField );
                                _dc.string2 = [NSString stringWithUTF8String:cNozzle];
                            }
                        }
                            break;
                        case FiberPoints:
                        {
                            _dc.pointSymbol = Star1Sym;
                            iField = DBFGetFieldIndex(_hDBF, "TYPE_OF_ST");
                            if (iField >= 0)
                            {
                                DBFGetFieldInfo(_hDBF,iField,
                                                fieldName, &fieldWidth, &nDecimals );
                                const char * cType = DBFReadStringAttribute( _hDBF,irec,iField );
                                _dc.string2 = [NSString stringWithUTF8String:cType];
                            }
                        }
                            break;
                            
                        default:
                            break;
                    }
                    if ([themes setDisplayCharacteristics:_dc
                                                displayID:_processingID] != DO_NOT_DISPLAY_ITEM)
                    {
                        if (hlist)
                        {
                            
                        }
                        else
                            [self drawPoint:context
                                    atPoint:&pt
                                usingSymbol:_dc.pointSymbol
                                  withColor:_dc.color.CGColor
                                    andSize:(_dc.size * _sizeFactor)];
                    }
                }
                    break;
                    
                default:
                {
                    int fieldWidth, nDecimals, iField;
                    char fieldName[32];
                    
                    switch (_dc.elementType)
                    {
                        case StormMain:
                        {
                            _dc.width = 3;
                            iField = DBFGetFieldIndex(_hDBF, "DIAMETER");
                            if (iField >= 0)
                            {
                                DBFGetFieldInfo(_hDBF,iField,
                                                fieldName, &fieldWidth, &nDecimals );
                                _dc.width = max (DBFReadDoubleAttribute( _hDBF,irec,iField )/4,2);
                            }
                            iField = DBFGetFieldIndex(_hDBF, "Material");
                            if (iField >= 0)
                            {
                                DBFGetFieldInfo(_hDBF,iField,
                                                fieldName, &fieldWidth, &nDecimals );
                                const char * cMaterial = DBFReadStringAttribute( _hDBF,irec,iField );
                                _dc.string2 = [NSString stringWithUTF8String:cMaterial];
                            }
                        }
                            break;
                        case SanitaryMain:
                        {
                            _dc.width = 3;
                            iField = DBFGetFieldIndex(_hDBF, "DIAMETER");
                            if (iField >= 0)
                            {
                                DBFGetFieldInfo(_hDBF,iField,
                                                fieldName, &fieldWidth, &nDecimals );
                                _dc.width = max (DBFReadDoubleAttribute( _hDBF,irec,iField )/4,2);
                            }
                            iField = DBFGetFieldIndex(_hDBF, "Material");
                            if (iField >= 0)
                            {
                                DBFGetFieldInfo(_hDBF,iField,
                                                fieldName, &fieldWidth, &nDecimals );
                                const char * cMaterial = DBFReadStringAttribute( _hDBF,irec,iField );
                                _dc.string2 = [NSString stringWithUTF8String:cMaterial];
                            }
                        }
                            break;
                        case SanitaryManhole:
                        {
                            _dc.width = 3;
                            iField = DBFGetFieldIndex(_hDBF, "DIAMETER");
                            if (iField >= 0)
                            {
                                DBFGetFieldInfo(_hDBF,iField,
                                                fieldName, &fieldWidth, &nDecimals );
                                _dc.width = max (DBFReadDoubleAttribute( _hDBF,irec,iField )/4,2);
                            }
                            iField = DBFGetFieldIndex(_hDBF, "Material");
                            if (iField >= 0)
                            {
                                DBFGetFieldInfo(_hDBF,iField,
                                                fieldName, &fieldWidth, &nDecimals );
                                const char * cMaterial = DBFReadStringAttribute( _hDBF,irec,iField );
                                _dc.string2 = [NSString stringWithUTF8String:cMaterial];
                            }
                        }
                            break;
                        case WaterMain:
                        {
                            iField = DBFGetFieldIndex(_hDBF, "DIAMETER");
                            if (iField >= 0)
                            {
                                DBFGetFieldInfo(_hDBF,iField,
                                                fieldName, &fieldWidth, &nDecimals );
                                _dc.width = DBFReadDoubleAttribute( _hDBF,irec,iField )/2;
                            }
                            iField = DBFGetFieldIndex(_hDBF, "Material");
                            if (iField >= 0)
                            {
                                DBFGetFieldInfo(_hDBF,iField,
                                                fieldName, &fieldWidth, &nDecimals );
                                const char * cMaterial = DBFReadStringAttribute( _hDBF,irec,iField );
                                _dc.string2 = [NSString stringWithUTF8String:cMaterial];
                            }
                        }
                            break;
                        case FiberLines:
                        {
                            iField = DBFGetFieldIndex(_hDBF, "Strands");
                            if (iField >= 0)
                            {
                                DBFGetFieldInfo(_hDBF,iField,
                                                fieldName, &fieldWidth, &nDecimals );
                                double segments = DBFReadDoubleAttribute( _hDBF,irec,iField );
                                int iSegments = segments;
                                _dc.UCR = iSegments;
                                _dc.width = iSegments/8;
                            }
                            
                        }
                            break;
                        case PDFBounds:
                        {
                            iField = DBFGetFieldIndex(_hDBF, "UDI");
                            
                            if (iField >= 0)
                            {
                                DBFGetFieldInfo(_hDBF,iField, fieldName, &fieldWidth, &nDecimals );
                                const char *cUDI = DBFReadStringAttribute(_hDBF,irec,iField);
                                _dc.string2 = [NSString stringWithUTF8String:cUDI];
                                
                                if (_dc.refno == CRAPI.sharedInstance.showPlats)
                                    _dc.color = UIColor.grayColor;
                                
                                else
                                {
                                    _dc.color = [NVColor randomColorFromArray:NVColor.pastelColors
                                                               forString:_dc.string2];
                                }
                            }
                        }
                            break;
                        
                        default:
                            break;
                    }
                    
                    if ([themes setDisplayCharacteristics:_dc
                                                displayID:_processingID] != DO_NOT_DISPLAY_ITEM)
                    {
                        if (_dc.elementType == PDFBounds)
                        {
                            LPDPOINT llpoints = malloc(psCShape->nVertices * sizeof(DPOINT) + 4);
                            
                            
                            for (int i = 0; i < psCShape->nVertices; i++)
                            {
                                llpoints[i].x = psCShape->padfX[i];
                                llpoints[i].y = psCShape->padfY[i];
                                llpoints[i] = TranDPOINT(&llpoints[i], _pTranLLtoView);
                            }
                            if (hlist)
                            {
                                if (POINT_IN_AREAD(midpt, psCShape->nVertices, llpoints, 1, 0, 0, 0))
                                {
                                    for (int i = 0; i < psCShape->nVertices; i++)
                                    {
                                        if (findClosestPoint (&llpoints[i],&minpt,&mind,&midpt))
                                        {
                                            minRef = _dc.refno;
                                            minPlatID = _dc.string2;
                                            PickedItem *pi = [PickedItem new];
                                            pi.refno = _dc.refno;
                                            pi.identifier = minPlatID;
                                            pi.itemType = _dc.elementType;
                                            pi.pickedPoint = llpoints[i];
                                            pi.distance = mind;
                                            [hlist addObject:pi];
                                        }
                                    }
                                }
                                
                            }
                            else
                                [self fillArea:context nPoints:psCShape->nVertices
                                        points:llpoints
                                     withColor:_dc.color.CGColor];
                            
                        }
                        else
                        {
                            if (hlist)
                            {
                                
                            }
                            else
                            {
                                _dc.width = max (1,_dc.width);
                                [self drawLine:context
                                       nPoints:psCShape->nVertices
                                        nLoops:psCShape->nParts
                                       partLen:psCShape->panPartStart
                                             x:psCShape->padfX
                                             y:psCShape->padfY
                                     withColor:_dc.color.CGColor
                                      andWidth:_dc.width*_widthFactor];
                            }
                        }
                    }
                }
            }
        }
        SHPDestroyObject ( psCShape );
    }

}
- (void)fillArea:(CGContextRef)context
           nPoints:(int)np
            points:(LPDPOINT)pPoints
         withColor:(CGColorRef)color
{
    CGContextSetLineWidth(context, 3);
    
    
    CGContextMoveToPoint(context, pPoints[0].x, pPoints[0].y);
    
    for (int i = 1; i < np; i++)
        CGContextAddLineToPoint(context, pPoints[i].x, pPoints[i].y);
    
    CGContextAddLineToPoint(context, pPoints[0].x, pPoints[0].y);
    
    if (!CGContextIsPathEmpty(context))
    {
        //CGContextSetStrokeColorWithColor(context,color);
        CGContextSetFillColorWithColor(context,color);
        CGContextDrawPath(context, kCGPathFill);
    }
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
    CGContextSetLineJoin(context,kCGLineJoinRound);
    CGContextSetLineCap(context,kCGLineCapRound);
    LPDPOINT llpoints = malloc(np * sizeof(DPOINT) + 4);
    
    
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
            ip = pPartIndex[loop];
            CGContextMoveToPoint(context, llpoints[ip].x, llpoints[ip].y);
            ip++;
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
                                lineWidth:size/8];
    
}

- (NSMutableArray*)pickPDFPlat:(LLPOINT *)pt

{
    NSMutableArray * highlightList = [[NSMutableArray alloc]init];
    int minRef = 0;
    dbounds bnds;
    //CGFloat d;
    CGFloat pickap = 0.005;
    DPOINT p1, minpt;
    //DPOINT p2;
    NSString *minPlatID = [[NSString alloc] init];
    
    p1.x = pt->lon;
    p1.y = pt->lat;
    minpt = p1;
    bnds.xmn = (p1.x - pickap);
    bnds.xmx = (p1.x + pickap);
    bnds.ymn = (p1.y - pickap);
    bnds.ymx = (p1.y + pickap);
    _dc = [DisplayCharacteristics new];
    _dc.elementType = PDFBounds;
    
    [self processShape:nil highlightList:highlightList LLBounds:&bnds themes:nil];
    
    pt->lon = minpt.x;
    pt->lat = minpt.y;
    
    NSString *platFile = [NSString stringWithFormat:@"%@/SanPlats/%@.jpg",
                          _documentsDirectory, minPlatID];
    
    if (minRef)
        CRAPI.sharedInstance.currentPlatImagePath = platFile;
    return highlightList;
}



@end
