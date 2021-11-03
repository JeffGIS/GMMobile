//
//  HuntingDataDisplay.m
//  NVMobile
//
//  Created by Jeff Smith on 11/23/17.
//  Copyright © 2017 GSSi. All rights reserved.
//

#import "HuntingDataDisplay.h"
#import "ShapeFileDisplay.h"

@interface HuntingDataDisplay ()

@property (nonatomic) LPTRANDATA pTranLLtoView, pTranViewtoLL;
@property sqlite3nv *database;
@property INT64 totRecords,currentRec;
@end

@implementation HuntingDataDisplay


-(void)  displayLayers:(CGContextRef)context
displayCharacteristics:(DisplayCharacteristics *)dc
             llCorners:(CORNERPOINTS *) latlonCornerPoints
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds
                themes:(Themes*)themes
           pointInArea:(PointInArea *)pia
{
    NSString *documentsDirectory = UserDefaults.defaults.sharedFilePath;
    NSString *outputDirectory = [NSString stringWithFormat:@"%@/Hunting", documentsDirectory];
    ShapeFileDisplay *sfd;
    NSString *fileName;
    NSString *shapeFile;
    int  nDisplayed;
    
    if (ConfigurationControl.sharedInstance.mapType == kGMSTypeHybrid)
        return;
    if ([ConfigurationControl.sharedInstance layer:HCLayerHunting
                                     visibleAtZoom:_zoom
                                           andPass:_passID])
    {
        /*
        fileName = @"Carlton_County.shp";
        fileName = @"Ownership.shp";
        dc.elementType = ParcelBoundary;
        dc.elementType = Ownership;
        shapeFile = [NSString stringWithFormat:@"%@/%@", outputDirectory,fileName];
        sfd = [ShapeFileDisplay createWithFile:shapeFile.UTF8String];
        if (sfd)
        {
            sfd.zoom = _zoom;
            sfd.processingID = _processingID;
            [sfd display:context
  displayCharacteristics:dc
               llCorners:latlonCornerPoints
                LLBounds:platlonBounds
              viewBounds:pvbounds
                  themes:themes
             pointInArea:pia];
        }
        */
        nDisplayed = [self display:context
                          areaType:@"WPA"
                          pointInAreas:pia
                          llCorners:latlonCornerPoints
                          LLBounds:platlonBounds
                        viewBounds:pvbounds];
                 

        nDisplayed = [self display:context
                          areaType:@"WMA"
                          pointInAreas:pia
                          llCorners:latlonCornerPoints
                          LLBounds:platlonBounds
                          viewBounds:pvbounds];

        nDisplayed = [self display:context
                          areaType:@"WALKINAREA"
                          pointInAreas:pia
                          llCorners:latlonCornerPoints
                          LLBounds:platlonBounds
                          viewBounds:pvbounds];

        nDisplayed = [self display:context
                          areaType:@"OWNERSHIP"
                          pointInAreas:pia
                          llCorners:latlonCornerPoints
                          LLBounds:platlonBounds
                          viewBounds:pvbounds];

        nDisplayed = [self displayRoads:context
                                  llCorners:latlonCornerPoints
                                   LLBounds:platlonBounds
                                 viewBounds:pvbounds
                     displayCharacteristics:dc
                                     themes:themes
                                pointInArea:pia];
    }

}
- (BOOL)continueProcessing
{
    if (!_processingID || _processingID == CRAPI.sharedInstance.keepProcessing)
        return YES;
    
    return NO;
}

- (int) display:(CGContextRef)context
       areaType:(NSString*)areaType
   pointInAreas:(PointInAreas*)pias
      llCorners:(CORNERPOINTS *) latlonCornerPoints
       LLBounds:(MNMXCORD *)platlonBounds
     viewBounds:(MNMXCORD *)pvbounds
{
    int nLoaded = 0;
    NSString *query = @"";
    sqlite3_stmt *statement = NULL;
    DPOINT BasePt;
    int numPoints;
    LPSTR pkeyval;
    NSString * keyval;
    int numLoops;
    NSString * key = areaType;
    NSString * table = key;
    HuntingData *hd = HuntingData.new;
    int colorOpt = 0;
#define OWNER_COLORS    1
#define FWS_COLORS      2
    
    BOOL opened = [hd open];
    
    CloseTRANS2P(&_pTranLLtoView);
    CloseTRANS2P(&_pTranViewtoLL);
    
    _pTranLLtoView = STRANCornersToBoundsP(latlonCornerPoints, pvbounds);
    
    if ([areaType isEqualToString:@"WPA"] ||
        [areaType isEqualToString:@"NWR"] ||
        [areaType isEqualToString:@"FSA"])
    {
        table = @"FWS";
        query = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,NAME FROM %@,%@_index WHERE TYPE='%@' AND %@.id=%@_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",table,table,areaType,table,table,
                 platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
    }
    else
    {
        if ([table isEqual:@"OWNERSHIP"])
        {
            key = @"OWNER";
            colorOpt = OWNER_COLORS;
        }
        query = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,%@ FROM %@,%@_index WHERE %@.id=%@_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",key,table,table,table,table,
                 platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
        
    }
    //querys = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,USECODE,id FROM LANDUSE"];
NextPass:
    SQLOK(__FILE__,__LINE__,SQLitePrepare(hd.database, query.UTF8String, -1, &statement, 0), hd.database);
    
    while ([self continueProcessing] && sqlite3_step(statement) == SQLITE_ROW)
    {
        BasePt.x = sqlite3_column_double(statement,0);
        BasePt.y = sqlite3_column_double(statement,1);
        numPoints = sqlite3_column_int(statement,2);
        numLoops = sqlite3_column_int(statement,3);
        int *polyPartLen = (int *)sqlite3_column_blob(statement,4);
        //int nBlobBytes = sqlite3_column_bytes(statement,4);
        LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement,5);
        //nBlobBytes = sqlite3_column_bytes(statement,5);
        pkeyval = (LPSTR)sqlite3_column_text(statement,6);
        keyval = [NSString stringWithUTF8String:pkeyval];
        if (pias)
        {
            double count = [pias countForArea:keyval
                                   whichCount:0];
            if (count < 0)
                continue;
        }
        LPDPOINT llpoints = malloc(abs(numPoints) * sizeof(DPOINT) + 4);
        if (numPoints < 0)
        {
            numPoints = -numPoints;
            LPSPOINT offsetPoints16 = (LPSPOINT)offsetPoints;
            
            for (int i = 0; i < numPoints; i++)
            {
                llpoints[i].x = (BasePt.x + offsetPoints16[i].x / COORDINATE_FACTOR);
                llpoints[i].y = (BasePt.y + offsetPoints16[i].y / COORDINATE_FACTOR);
                llpoints[i] = TranDPOINTP(&llpoints[i], _pTranLLtoView);
            }
        }
        
        else for (int i = 0; i < numPoints; i++)
        {
            llpoints[i].x = (BasePt.x + offsetPoints[i].x / COORDINATE_FACTOR);
            llpoints[i].y = (BasePt.y + offsetPoints[i].y / COORDINATE_FACTOR);
            llpoints[i] = TranDPOINTP(&llpoints[i], _pTranLLtoView);
        }
        CGColorRef color;
        
        if (pias)
            color = [pias colorForArea:keyval];
        
        else switch (colorOpt)
        {
            case OWNER_COLORS:
            {
                if ([keyval isEqual:@"State"])
                    color = NVColor.tealColor.CGColor;
                else if ([keyval isEqual:@"County"])
                    color = NVColor.darkGreenColor.CGColor;
                else if ([keyval isEqual:@"Federal"])
                    color = NVColor.lightGreenColor.CGColor;
                else if ([keyval isEqual:@"Tribal"])
                    color = NVColor.orangeColor.CGColor;
                else
                    color = NVColor.greenColor.CGColor;
            }
                break;
            case FWS_COLORS:
                color = NVColor.blackColor.CGColor;
                break;
            default:
                color = [NVColor randomColorFromArray:NVColor.pastelColors
                                            forString:keyval].CGColor;
                break;
        }
        nLoaded++;
        LPDPOINT llpointsThinned = ThinPoints (llpoints,&numPoints);
        free (llpoints);
        [self fillUseCode:context
                  nPoints:numPoints
                   points:llpointsThinned
                withColor:color
                lineColor:nil
                lineWidth:0];
        if (_zoom > 14)
        [self drawUseCode:context
                  nPoints:numPoints
                   nLoops:numLoops
                  partLen:polyPartLen
                   points:llpointsThinned
                withColor:UIColor.blackColor.CGColor
                 andWidth:3];
        
        free (llpointsThinned);
    }
    
    SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), hd.database);
    [hd close:opened];
    
    CloseTRANS2P(&_pTranLLtoView);
    CloseTRANS2P(&_pTranViewtoLL);
    return nLoaded;
    
}

INT64 RoundToHundred (LPDOUBLE pDval)
{
    INT64 rtn;
    int mult;
    double dVal;
    static int iopt = 0;
    switch (iopt)
    {
        case 0:
            rtn = IDNINT (*pDval);
            *pDval = rtn;
            return rtn;
        case 1:
            mult = 10;
            break;
        case 2:
            mult = 100;
            break;
    }
    dVal = *pDval * mult;
    rtn = floorl(dVal);
    *pDval = ((double)rtn) / mult;
    return rtn;
}

LPDPOINT ThinPoints (LPDPOINT llPoints,LPINT pNumPoints)
{
    INT64 lastx,lasty,thisx, thisy;
    
    LPDPOINT llPointsThinned = malloc(*pNumPoints * sizeof(DPOINT) + 4);
    int numThinnedPoints = 0;
    lastx = RoundToHundred (&llPoints->x);
    lasty = RoundToHundred (&llPoints->y);
    llPointsThinned[numThinnedPoints++] = *llPoints++;
    for (int i = 1;i<*pNumPoints;i++,llPoints++)
    {
        thisx = RoundToHundred (&llPoints->x);
        thisy = RoundToHundred (&llPoints->y);
        if (thisx != lastx || thisy != lasty)
        {
            llPointsThinned[numThinnedPoints++] = *llPoints;
            lastx = thisx;
            lasty = thisy;
        }
    }
    *pNumPoints = numThinnedPoints;
    return llPointsThinned;
}

- (INT64)getQueryCount:(NSString*)query
{
    sqlite3_stmt *statement = NULL;
    INT64 count = 0;
    CRAPI.sharedInstance.mapToolbar.showIndicator = YES;

    SQLOK(__FILE__,__LINE__,SQLitePrepare(_database, query.UTF8String, -1, &statement, NULL), _database);
    
    while ([self continueProcessing] && sqlite3_step(statement) == SQLITE_ROW)
        count++;
    
    SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), _database);
    CRAPI.sharedInstance.mapToolbar.showIndicator = NO;

    return count;
}

-(int) displayRoads:(CGContextRef)context
             llCorners:(CORNERPOINTS *) latlonCornerPoints
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds
displayCharacteristics:(DisplayCharacteristics *)dc
                themes:(Themes*)themes
           pointInArea:(PointInArea *)pia
{
    int nDisplayed = 0;
    NSString *query = @"";
    //NSString *querys;
    sqlite3_stmt *statement = NULL;
    DPOINT BasePt;
    int numPoints, useCode;
    int numLoops;
    HuntingData *hd = HuntingData.new;
    
    BOOL opened = [hd open];
    _database = hd.database;
    CloseTRANS2P(&_pTranLLtoView);
    CloseTRANS2P(&_pTranViewtoLL);
    
    _pTranLLtoView = STRANCornersToBoundsP(latlonCornerPoints, pvbounds);
        
            query = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points, STREETNAME FROM ROADS_LINE,ROADS_LINE_index WHERE ROADS_LINE.id=ROADS_LINE_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                     platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
            _totRecords = [self getQueryCount:query];
            [CRAPI.sharedInstance updateProgress:-1
                                         current:0
                                           range:1
                                       numRanges:1];
    
    SQLOK(__FILE__,__LINE__,SQLitePrepare(self.database, query.UTF8String, -1, &statement, 0), hd.database);
    _currentRec = 0;
    while ([self continueProcessing] && sqlite3_step(statement) == SQLITE_ROW)
    {
        int i = 0;
        BasePt.x = sqlite3_column_double(statement,i++);
        BasePt.y = sqlite3_column_double(statement,i++);
        numPoints = sqlite3_column_int(statement,i++);
        numLoops = sqlite3_column_int(statement,i++);
        int *polyPartLen = (int *)sqlite3_column_blob(statement,i++);
        int nBlobBytes = sqlite3_column_bytes(statement,i);
        LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement,i++);
        LPDPOINT llpoints = malloc(abs(numPoints) * sizeof(DPOINT) + 4);
                LPSTR cLine = (LPSTR)sqlite3_column_text(statement,i++);
                int speed = 30;
                LPSTR pColon = strrchr (cLine,':');
                if (pColon)
                {
                    *pColon++ = 0;
                    speed = atoi (pColon);
                    speed = IDNINT (speed / 5.0) * 5;
                    speed = min (max (15,speed),70);
                }
                dc.iValue = speed;
                dc.width = 1;
         int np = 0;
        //if (abs(numPoints)<108000)
        {
        if (numPoints < 0)
        {
            numPoints = -numPoints;
            LPSPOINT offsetPoints16 = (LPSPOINT)offsetPoints;
            
            for (int i = 0; i < numPoints; i++)
            {
                llpoints[np].x = (BasePt.x + offsetPoints16[i].x / COORDINATE_FACTOR);
                llpoints[np].y = (BasePt.y + offsetPoints16[i].y / COORDINATE_FACTOR);
                llpoints[np] = TranDPOINTP(&llpoints[np], _pTranLLtoView);
               /* if (np)
                {
                    if (!sameDPoint(&llpoints[np-1], &llpoints[np],1))
                        np++;
                }
                else*/
                    np++;
            }
        }
        
        else for (int i = 0; i < numPoints; i++)
        {
            llpoints[np].x = (BasePt.x + offsetPoints[i].x / COORDINATE_FACTOR);
            llpoints[np].y = (BasePt.y + offsetPoints[i].y / COORDINATE_FACTOR);
            llpoints[np] = TranDPOINTP(&llpoints[np], _pTranLLtoView);
           /* if (np)
            {
                if (!sameDPoint(&llpoints[np-1], &llpoints[np],1))
                    np++;
            }
            else*/
                np++;
        }
        if ([themes setDisplayCharacteristics:dc
                                    displayID:_processingID
                                 compareClass:nil] != DO_NOT_DISPLAY_ITEM)
        {
            
            [self drawRoad:context
                      nPoints:np
                       nLoops:numLoops
                      partLen:polyPartLen
                       points:llpoints
                    withColor:dc.penColor.CGColor
                     andWidth:dc.width];
            nDisplayed++;
        }
        }
        free (llpoints);
        [CRAPI.sharedInstance updateProgress:(NSInteger)_totRecords
                                     current:(NSInteger)++_currentRec
                                       range:0
                                   numRanges:1];
        
    }
    
    SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), hd.database);
    CloseTRANS2P(&_pTranLLtoView);
    CloseTRANS2P(&_pTranViewtoLL);
    [hd close:opened];
    return nDisplayed;
}

- (void)drawRoad:(CGContextRef)context
             nPoints:(int)np
              nLoops:(int)nLoops
             partLen:(int *)pPartLen
              points:(LPDPOINT)pPoints
           withColor:(CGColorRef)color
           andWidth:(CGFloat)width
{
    CGContextSetLineWidth(context, width*3);
    
    if (nLoops > 1)
    {
        int ip = 0;
        //int ii;
        
        for (int loop = 0; loop < nLoops; loop++)
        {
            CGContextMoveToPoint(context, pPoints[ip].x, pPoints[ip].y);
            ip++;
            //ii = pPartLen[loop];
            
            for (int i = 1; i < pPartLen[loop]; i++)
            {
                CGContextAddLineToPoint(context, pPoints[ip].x, pPoints[ip].y);
                ip++;
            }
            
            if (loop)
                ip++;
            
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
        CGContextMoveToPoint(context, pPoints[0].x, pPoints[0].y);
        
        for (int i = 1; i < np; i++)
            CGContextAddLineToPoint(context, pPoints[i].x, pPoints[i].y);
        
        //CGContextAddLineToPoint(context, pPoints[0].x, pPoints[0].y);
        
        if (!CGContextIsPathEmpty(context))
        {
            CGContextSetStrokeColorWithColor(context,color);
            CGContextDrawPath(context, kCGPathStroke);
        }
    }
}
- (void)fillUseCode:(CGContextRef)context
           nPoints:(int)np
            points:(LPDPOINT)pPoints
         withColor:(CGColorRef)color
          lineColor:(CGColorRef)lineColor
          lineWidth:(float)lineWidth
{
    //CGContextSetLineWidth(context, 3);
    //CGContextFillEllipseInRect(context, pointRect);
    //CGContextStrokeEllipseInRect(context, pointRect);
    //CGContextFillPath(context);
    if (!color)
        return;
    CGContextMoveToPoint(context, pPoints[0].x, pPoints[0].y);
    
    for (int i = 1; i < np; i++)
    {
//        double x=pPoints[i].x, y=pPoints[i].y;
        CGContextAddLineToPoint(context, pPoints[i].x, pPoints[i].y);
    }
//        CGContextAddLineToPoint(context, pPoints[i].x, pPoints[i].y);
    
    CGContextAddLineToPoint(context, pPoints[0].x, pPoints[0].y);
    CGContextClosePath(context);
    if (!CGContextIsPathEmpty(context))
    {
        CGContextSetFillColorWithColor(context,color);
        if (lineWidth)
        {
            CGContextSetLineWidth(context, lineWidth);
            CGContextSetStrokeColorWithColor(context,lineColor);
            CGContextDrawPath(context, kCGPathEOFillStroke);
        }
        else
        {
            CGContextDrawPath(context, kCGPathEOFill);
        }
        
    }
}
- (void)drawUseCode:(CGContextRef)context
            nPoints:(int)np
             nLoops:(int)nLoops
            partLen:(int *)pPartLen
             points:(LPDPOINT)pPoints
          withColor:(CGColorRef)color
           andWidth:(CGFloat)width
{
    CGContextSetLineWidth(context, width);
    
    if (nLoops > 1)
    {
        int ip = 0;
        //int ii;
        
        for (int loop = 0; loop < nLoops; loop++)
        {
            CGContextMoveToPoint(context, pPoints[ip].x, pPoints[ip].y);
            ip++;
            //ii = pPartLen[loop];
            
            for (int i = 1; i < pPartLen[loop]; i++)
            {
                CGContextAddLineToPoint(context, pPoints[ip].x, pPoints[ip].y);
                ip++;
            }
            
            if (loop)
                ip++;
            
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
        CGContextMoveToPoint(context, pPoints[0].x, pPoints[0].y);
        
        for (int i = 1; i < np; i++)
            CGContextAddLineToPoint(context, pPoints[i].x, pPoints[i].y);
        
        CGContextAddLineToPoint(context, pPoints[0].x, pPoints[0].y);
        
        if (!CGContextIsPathEmpty(context))
        {
            CGContextSetStrokeColorWithColor(context,color);
            CGContextDrawPath(context, kCGPathStroke);
        }
    }
}

@end
