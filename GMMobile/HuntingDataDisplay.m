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
@property (nonatomic) CGColorRef WMAColor, WPAColor, NWRColor, FSAColor, WalkInColor, LAKESColor;
@property sqlite3nv *database;
@property INT64 totRecords,currentRec;
@end

@implementation HuntingDataDisplay

+(CGColorRef) WMAColor
{
    return [NVColor boldColors][0*6].CGColor;
}
+(CGColorRef) WPAColor
{
    return [NVColor boldColors][1*6].CGColor;
}
+(CGColorRef) NWRColor
{
    return [NVColor boldColors][2*6].CGColor;
}
+(CGColorRef) FSAColor
{
    return [NVColor boldColors][3*6].CGColor;
}
+(CGColorRef) WalkInColor
{
    return [NVColor boldColors][4*6].CGColor;
}
+(CGColorRef) LAKESColor
{
    return NVColor.blueColor.CGColor;

}
- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.WMAColor = [HuntingDataDisplay WMAColor];
        self.WPAColor = [HuntingDataDisplay WPAColor];
        self.NWRColor = [HuntingDataDisplay NWRColor];
        self.FSAColor = [HuntingDataDisplay FSAColor];
        self.WalkInColor = [HuntingDataDisplay WalkInColor];
        self.LAKESColor = [HuntingDataDisplay LAKESColor];
    }
    
    return self;
}


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
/*        if ([ConfigurationControl.sharedInstance layer:HCLayerOwnership
                                         visibleAtZoom:_zoom
                                               andPass:_passID])
        {
            nDisplayed = [self display:context
                              areaType:@"OWNERSHIP"
                                 color:0
                          pointInAreas:pia
                             llCorners:latlonCornerPoints
                              LLBounds:platlonBounds
                            viewBounds:pvbounds];
        }*/
        nDisplayed = [self display:context
                          areaType:@"WMA"
                             color:_WMAColor
                          pointInAreas:pia
                          llCorners:latlonCornerPoints
                          LLBounds:platlonBounds
                        viewBounds:pvbounds];
        nDisplayed = [self display:context
                          areaType:@"LAKES"
                             color:_LAKESColor
                          pointInAreas:pia
                          llCorners:latlonCornerPoints
                          LLBounds:platlonBounds
                        viewBounds:pvbounds];
        nDisplayed = [self display:context
                          areaType:@"WPA"
                             color:_WPAColor
                          pointInAreas:pia
                          llCorners:latlonCornerPoints
                          LLBounds:platlonBounds
                        viewBounds:pvbounds];
                 
        nDisplayed = [self display:context
                          areaType:@"NWR"
                             color:_NWRColor
                          pointInAreas:pia
                          llCorners:latlonCornerPoints
                          LLBounds:platlonBounds
                        viewBounds:pvbounds];
                 

        nDisplayed = [self display:context
                          areaType:@"FSA"
                             color:_FSAColor
                          pointInAreas:pia
                          llCorners:latlonCornerPoints
                          LLBounds:platlonBounds
                          viewBounds:pvbounds];

        nDisplayed = [self display:context
                          areaType:@"WALKINAREA"
                             color:_WalkInColor
                          pointInAreas:pia
                          llCorners:latlonCornerPoints
                          LLBounds:platlonBounds
                          viewBounds:pvbounds];

        if ([ConfigurationControl.sharedInstance layer:HCLayerNWI
                                         visibleAtZoom:_zoom
                                               andPass:_passID])
        {
            nDisplayed = [self displayUsingBinFile:context
                              areaType:@"NWI"
                                 color:0
                          pointInAreas:pia
                             llCorners:latlonCornerPoints
                              LLBounds:platlonBounds
                            viewBounds:pvbounds];
        }
        if ([ConfigurationControl.sharedInstance layer:HCLayerForest
                                         visibleAtZoom:_zoom
                                               andPass:_passID])
        {
            nDisplayed = [self displayUsingBinFile:context
                              areaType:@"FOREST"
                                 color:0
                          pointInAreas:pia
                             llCorners:latlonCornerPoints
                              LLBounds:platlonBounds
                            viewBounds:pvbounds];
        }
        if (ConfigurationControl.sharedInstance.mapType == kGMSTypeNone)
        {
            nDisplayed = [self displayRoads:context
                                  llCorners:latlonCornerPoints
                                   LLBounds:platlonBounds
                                 viewBounds:pvbounds
                     displayCharacteristics:dc
                                     themes:themes
                                pointInArea:pia];
            nDisplayed = [self displayTrails:context
                                  llCorners:latlonCornerPoints
                                   LLBounds:platlonBounds
                                 viewBounds:pvbounds
                     displayCharacteristics:dc
                                     themes:themes
                                pointInArea:pia];
        }
        nDisplayed = [self displayWaypoints:context
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
          color:(CGColorRef) color
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
        if ([table isEqual:@"LAKES"])
        {
            key = @"NAME";
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
                break;
            default:
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
       /* if (_zoom > 14)
        [self drawUseCode:context
                  nPoints:numPoints
                   nLoops:numLoops
                  partLen:polyPartLen
                   points:llpointsThinned
                withColor:UIColor.blackColor.CGColor
                 andWidth:3];
        */
        free (llpointsThinned);
    }
    
    SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), hd.database);
    [hd close:opened];
    
    CloseTRANS2P(&_pTranLLtoView);
    CloseTRANS2P(&_pTranViewtoLL);
    return nLoaded;
    
}

LPDPOINT ExpandPoints (FILE *fid,INT64 offset,int reclen,int compressType,int numPoints,IPOINT basePoint)
{
    LPDPOINT pOutPoints = malloc (numPoints * sizeof(DPOINT) + 4);
    int decompressedSize = 0;
    LPBYTE pCompressed = {0};
    LPBYTE pDeCompressed = {0};
    int lMem = 0;
    switch (compressType)
    {
        case 1:
        case 11:
            lMem = numPoints * sizeof (BPOINT);
            break;
        case 2:
        case 12:
            lMem = numPoints * sizeof (SPOINT);
            break;
        default:
            lMem = numPoints * sizeof (POINT);;
            break;
    }
    fseek(fid, offset, SEEK_SET);
    pDeCompressed = malloc (lMem+4);
    if (compressType > 9)
    {
        pCompressed = malloc(reclen+4);
        BigReadF(fid, pCompressed, reclen);
        decompressedSize = DecompressBinaryRecordUnsafe(pDeCompressed, pCompressed, reclen);
        free (pCompressed);
    }
    else
        BigReadF(fid, pDeCompressed, reclen);
    switch (compressType)
    {
        case 0:
        case 10:
        {
            LPPOINT pOffsets = (LPSPOINT)pDeCompressed;
            pOutPoints->x = basePoint.x;
            pOutPoints->y = basePoint.y;
            for (int i = 1;i<numPoints;i++)
            {
                pOutPoints[i].x = pOffsets[i].x;
                pOutPoints[i].y = pOffsets[i].y;
            }
        }
            break;
        case 1:
        case 11:
        {
            LPBPOINT pOffsets = (LPBPOINT)pDeCompressed;
            pOutPoints->x = basePoint.x;
            pOutPoints->y = basePoint.y;
            for (int i = 1;i<numPoints;i++)
            {
                pOutPoints[i].x = pOutPoints[i-1].x + pOffsets[i].x;
                pOutPoints[i].y = pOutPoints[i-1].y + pOffsets[i].y;
            }
        }
            break;
        case 2:
        case 12:
        {
            LPSPOINT pOffsets = (LPSPOINT)pDeCompressed;
            pOutPoints->x = basePoint.x;
            pOutPoints->y = basePoint.y;
            for (int i = 1;i<numPoints;i++)
            {
                pOutPoints[i].x = pOutPoints[i-1].x + pOffsets[i].x;
                pOutPoints[i].y = pOutPoints[i-1].y + pOffsets[i].y;
            }
        }
            break;
        default:
            lMem = 0;
            break;
    }
    free (pDeCompressed);
    return pOutPoints;
}
- (int) displayUsingBinFile:(CGContextRef)context
       areaType:(NSString*)areaType
          color:(CGColorRef) color
   pointInAreas:(PointInAreas*)pias
      llCorners:(CORNERPOINTS *) latlonCornerPoints
       LLBounds:(MNMXCORD *)platlonBounds
     viewBounds:(MNMXCORD *)pvbounds
{
    int nLoaded = 0;
    NSString *query = @"";
    sqlite3_stmt *statement = NULL;
    IPOINT BasePt;
    int numPoints;
    LPSTR pkeyval;
    NSString * keyval;
    int numLoops;
    NSString * key = areaType;
    NSString * table = key;
    HuntingData *hd = HuntingData.new;
    int colorOpt = 0;
    FILE *binFile;
#define OWNER_COLORS    1
#define FWS_COLORS      2
#define typeNWI 1
#define typeFOREST 2
    int type;
    
    BOOL opened = [hd open];
    
    CloseTRANS2P(&_pTranLLtoView);
    CloseTRANS2P(&_pTranViewtoLL);
    
    CORNERPOINTS factoredCornerPoints = *latlonCornerPoints;
    factoredCornerPoints.farLeft.x *= hd.NWIFactor;
    factoredCornerPoints.farLeft.y *= hd.NWIFactor;
    factoredCornerPoints.nearLeft.x *= hd.NWIFactor;
    factoredCornerPoints.nearLeft.y *= hd.NWIFactor;
    factoredCornerPoints.farRight.x *= hd.NWIFactor;
    factoredCornerPoints.farRight.y *= hd.NWIFactor;
    factoredCornerPoints.nearRight.x *= hd.NWIFactor;
    factoredCornerPoints.nearRight.y *= hd.NWIFactor;
    _pTranLLtoView = STRANCornersToBoundsP(&factoredCornerPoints, pvbounds);
    
    if ([areaType isEqualToString:@"NWI"] )
    {
        type = typeNWI;
        table = @"NWIDATA.NWI";
        binFile = hd.fidNWIBin;
        query = [NSString stringWithFormat:@"SELECT FIRSTX,FIRSTY,NumPoints,NumPoly,rectype,compressionType,hasCurves,offset,recordLen,RECNUM, spcc_desc FROM %@,%@_index WHERE %@.RECNUM=%@_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",table,table,table,table,
                 platlonBounds->xmn*hd.NWIFactor, platlonBounds->xmx*hd.NWIFactor, platlonBounds->ymn*hd.NWIFactor, platlonBounds->ymx*hd.NWIFactor];
    }
    if ([areaType isEqualToString:@"FOREST"] )
    {
        type = typeFOREST;
        table = @"FORESTDATA.FOREST";
        binFile = hd.fidForestBin;
        query = [NSString stringWithFormat:@"SELECT FIRSTX,FIRSTY,NumPoints,NumPoly,rectype,compressionType,hasCurves,offset,recordLen,RECNUM, MN_CTYPE,SURVEY_YR,STAND_AGE,MN_SIZE,MN_DENS,UTYPE,USIZE,UDENSE FROM %@,%@_index WHERE %@.RECNUM=%@_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",table,table,table,table,
                 platlonBounds->xmn*hd.ForestFactor, platlonBounds->xmx*hd.ForestFactor, platlonBounds->ymn*hd.ForestFactor, platlonBounds->ymx*hd.ForestFactor];
    }
NextPass:
    SQLOK(__FILE__,__LINE__,SQLitePrepare(hd.database, query.UTF8String, -1, &statement, 0), hd.database);
    while ([self continueProcessing] && sqlite3_step(statement) == SQLITE_ROW)
    {
        int i = 0;
        int forestCode = 0;
        BasePt.x = sqlite3_column_int(statement,i++);
        BasePt.y = sqlite3_column_int(statement,i++);
        numPoints = sqlite3_column_int(statement,i++);
        numLoops = sqlite3_column_int(statement,i++);
        numLoops = 1;
        int rectype = sqlite3_column_int(statement,i++);
        int compressionType = sqlite3_column_int(statement,i++);
        int hasCurves = sqlite3_column_int(statement,i++);
        INT64 offset = sqlite3_column_int64(statement,i++);
        int reclen = sqlite3_column_int(statement,i++);
        INT64 recnum = sqlite3_column_int64(statement,i++);
        switch (type)
        {
            case typeNWI:
            {
                LPSTR pspcc_Desc = (LPSTR)sqlite3_column_text(statement,i++);
                NSString *spcc_Desc = [NSString stringWithUTF8String:pspcc_Desc];
            }
                break;
            case typeFOREST:
            {
                int standType = (LPSTR)sqlite3_column_int(statement,i++);
                int surveyYear = (LPSTR)sqlite3_column_int(statement,i++);
                int standAge = (LPSTR)sqlite3_column_int(statement,i++);
                if (standType == 12)
                {
                    int TRUEAGE=(2022-surveyYear)+standAge;
                    if (TRUEAGE>6 && TRUEAGE<15)
                        forestCode = 3;
                    else if (TRUEAGE>4 && TRUEAGE<7)
                        forestCode = 2;
                    else if (TRUEAGE>14 && TRUEAGE<19)
                        forestCode = 2;
                    else
                        forestCode = 1;
                }
            }
                break;
        }
        if (pias)
        {
            double count = [pias countForArea:keyval
                                   whichCount:0];
            if (count < 0)
                continue;
        }
        LPDPOINT llpoints = ExpandPoints (binFile,offset,reclen,compressionType,numPoints,BasePt);
        LPINT polyPartLen = malloc (numLoops * sizeof(int) + 4);
        
        for (int i = 0; i < numPoints; i++)
        {
            llpoints[i] = TranDPOINTP(&llpoints[i], _pTranLLtoView);
        }
        
        if (type == typeFOREST)
        {
            switch (forestCode)
            {
                default:
                    color = NVColor.lightGrayColor.CGColor;
                    break;
                case 1:
                    color = NVColor.lightPinkColor.CGColor;
                    break;
                case 2:
                    color = NVColor.mistyRoseColor.CGColor;
                    break;
                case 3:
                    color = NVColor.redColor.CGColor;
            }
        }
        else if (pias)
            color = [pias colorForArea:keyval];
        
        else switch (hasCurves)
        {
            case 0:
                color = NVColor.redColor.CGColor;
                break;
            case 1:
                color = NVColor.blueColor.CGColor;
                break;
            default:
                color = NVColor.redColor.CGColor;
                break;
        }
        //if (!hasCurves)
        {
        nLoaded++;
        [self fillUseCode:context
                  nPoints:numPoints
                   points:llpoints
                withColor:color
                lineColor:nil
                lineWidth:0];
            /*
        if (_zoom > 14)
        [self drawUseCode:context
                  nPoints:numPoints
                   nLoops:numLoops
                  partLen:polyPartLen
                   points:llpoints
                withColor:UIColor.blackColor.CGColor
                 andWidth:3];
             */
        }
             
        free (llpoints);
        free (polyPartLen);
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
    //CRAPI.sharedInstance.mapToolbar.showIndicator = NO;

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
        
            query = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points, ROADS_LINE.ROUTEID, STREETNAME, FUNCLASS, MATERIAL FROM ROADS_LINE,ROADS_LINE_index,ROADSDATA WHERE ROADS_LINE.id=ROADS_LINE_index.id AND ROADSDATA.ROUTEID=ROADS_LINE.ROUTEID AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
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
        LPSTR routeid = (LPSTR)sqlite3_column_text(statement,i++);
        LPSTR streetName = (LPSTR)sqlite3_column_text(statement,i++);
        LPSTR funclass = (LPSTR)sqlite3_column_text(statement,i++);
        NSString * funClass = [NSString stringWithUTF8String:funclass];
        LPSTR material = (LPSTR)sqlite3_column_text(statement,i++);
        dc.width = 1.5 *(8-funClass.integerValue);
        char mat = *material;
        switch (mat)
        {
            case 'B':
                dc.penColor = [UIColor blackColor];
                dc.width += 1;
                break;

            case 'C':
                dc.penColor = [UIColor grayColor];
                dc.width += 1;
                break;

            case 'A'://Aggregate
            case 'D'://dirt
            case 'G'://gravel
            case 'O'://other
            case '\0':
                dc.penColor = [UIColor brownColor];
                break;

            default:
                dc.penColor = [UIColor brownColor];
                break;
        }
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
        //nLoops = 1;
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
-(int) displayTrails:(CGContextRef)context
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
        
            query = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points, HUNTER_WALKING_TRAILS_LINE.NAME FROM HUNTER_WALKING_TRAILS_LINE,HUNTER_WALKING_TRAILS_LINE_index WHERE HUNTER_WALKING_TRAILS_LINE.id=HUNTER_WALKING_TRAILS_LINE_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
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
        LPSTR routeid = (LPSTR)sqlite3_column_text(statement,i++);
        dc.width = 5.5;
        dc.penColor = [UIColor orangeColor];
        
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
-(int) displayWaypoints:(CGContextRef)context
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
    NSArray *userWaypointArray = [hd getWaypoints];
    CloseTRANS2P(&_pTranLLtoView);
    CloseTRANS2P(&_pTranViewtoLL);
    
    _pTranLLtoView = STRANCornersToBoundsP(latlonCornerPoints, pvbounds);
        
     
    _currentRec = 0;
    CGColorRef starColor = UIColor.orangeColor.CGColor;
    CGColorRef blackColor = UIColor.blackColor.CGColor;
    CGColorRef whiteColor = UIColor.whiteColor.CGColor;

    for (UserWaypoint* waypoint in userWaypointArray)
    {
        DPOINT pt = TranLLPOINT(waypoint.latlon, _pTranLLtoView);
        dc.width = 5.5;
        dc.penColor = [UIColor orangeColor];
        
        if ([themes setDisplayCharacteristics:dc
                                    displayID:_processingID
                                 compareClass:nil] != DO_NOT_DISPLAY_ITEM)
        {
            int size = 75*UIScreen.mainScreen.scale;
            [SymbolDictionary drawPointWithSymbol:context
                                               at:&pt
                                      usingSymbol:Star2Sym
                                             Size:size
                                        fillColor:starColor
                                        lineColor:whiteColor
                                        lineWidth:1*UIScreen.mainScreen.scale
                                          andText:waypoint.name];
            nDisplayed++;
        }
     }
    
    CloseTRANS2P(&_pTranLLtoView);
    CloseTRANS2P(&_pTranViewtoLL);
    return nDisplayed;
}



@end
