//
//  HuntingDataDisplay.m
//  NVMobile
//
//  Created by Jeff Smith on 11/23/17.
//  Copyright © 2017 GSSi. All rights reserved.
//
static int ii=0;
#import "HuntingDataDisplay.h"
#import "ShapeFileDisplay.h"

@interface HuntingDataDisplay ()

@property (nonatomic) LPTRANDATA pTranLLtoView, pTranViewtoLL;
@property (nonatomic) CGColorRef WMAColor, WPAColor, NWRColor, FSAColor, WalkInColor, LAKESColor;
@property sqlite3nv *database;
@property INT64 totRecords,currentRec;
@property int topScore;
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
        self.topScore = 500;
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
    
    if (ConfigurationControl.sharedInstance.mapType != kGMSTypeHybrid &&
        ConfigurationControl.sharedInstance.mapType != kGMSTypeNormal)
    
    {        
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
            
            
            /*       nDisplayed = [self display:context
             areaType:@"FSA"
             color:_FSAColor
             pointInAreas:pia
             llCorners:latlonCornerPoints
             LLBounds:platlonBounds
             viewBounds:pvbounds];*/
            
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
            if ([ConfigurationControl.sharedInstance layer:HCLayerFEESURF
                                             visibleAtZoom:_zoom
                                                   andPass:_passID])
            {
                nDisplayed = [self displayUsingBinFile:context
                                              areaType:@"FEESURF"
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
            nDisplayed = [self displayEdgePoints:context
                                       llCorners:latlonCornerPoints
                                        LLBounds:platlonBounds
                                      viewBounds:pvbounds
                          displayCharacteristics:dc
                                          themes:themes
                                     pointInArea:pia];
        }
    }
    nDisplayed = [self displayWaypoints:context
                              llCorners:latlonCornerPoints
                               LLBounds:platlonBounds
                             viewBounds:pvbounds
                 displayCharacteristics:dc
                                 themes:themes
                            pointInArea:pia];

    
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
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    CGFloat fontSize = 32.0 * screenScale;
    int textZoom = 14;
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
            textZoom = 8;
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
        if (numLoops < 2)
            ii = 1;
        int *polyPartLenBlob = (int *)sqlite3_column_blob(statement,4);
        int *polyPartLenThinned=0;
        int nBlobBytes = sqlite3_column_bytes(statement,4);
        LPINT polyPartLen = malloc (nBlobBytes + 4);
        memmove (polyPartLen,polyPartLenBlob,nBlobBytes);
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
        int numPointsOrig = numPoints;
        BOOL doThinning = FALSE;
        if (_zoom < 1)
            doThinning = TRUE;
        if (doThinning)
        {
            LPDPOINT llpointsThinned = ThinPoints (llpoints,&numPoints,&numLoops,polyPartLen,&polyPartLenThinned,pvbounds);
            int totpntj = 0;
            int totpntk = 0;
            int numNewLoops = 0;
            if (numLoops > 1)
            {
                LPINT newPolyPartLenThinned = malloc (numLoops * sizeof(int)+4);
                for (int i=0;i<numLoops;i++)
                {
                    int j = polyPartLenThinned[i];
                    int k = polyPartLen[i];
                    if (j)
                        newPolyPartLenThinned[numNewLoops++] = j;
                    totpntj += j;
                    totpntk += k;
                }
                if (totpntj != numPoints)
                    ii = 1;
                if (totpntk != numPointsOrig)
                    ii = 1;
                free (polyPartLenThinned);
                polyPartLenThinned = newPolyPartLenThinned;
                numLoops = numNewLoops;
            }
            free (llpoints);
            free (polyPartLen);
            llpoints = llpointsThinned;
            polyPartLen = polyPartLenThinned;
        }
        
        if (numPoints > 2)
        {
            [self fillArea:context
                   nPoints:numPoints
                    points:llpoints
                 withColor:color
                 lineColor:nil
                 lineWidth:0];
            if (_zoom >= textZoom)
            {
                [self drawArea:context
                       nPoints:numPoints
                        nLoops:numLoops
                       partLen:polyPartLen
                        points:llpoints
                     withColor:UIColor.blackColor.CGColor
                      andWidth:1];
                if (keyval.length)
                {
                    UIColor *textColor = UIColor.blackColor;
                    CGFloat minFontSize = fontSize / 3;
                    [NVTextDrawing drawText:keyval
                                  inContext:context
                              withinPolygon:llpoints
                              withNumPoints:numPoints
                                andNumLoops:numLoops
                                    loopLen:polyPartLen
                               withinBounds:pvbounds
                                   fontSize:fontSize
                                minFontSize:minFontSize
                                  textColor:textColor
                                shadowColor:UIColor.yellowColor
                               processingID:_processingID];
                    
                }
            }
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
            LPPOINT pOffsets = (LPPOINT)pDeCompressed;
            pOutPoints->x = basePoint.x;
            pOutPoints->y = basePoint.y;
            for (int i = 1;i<numPoints;i++)
            {
                pOutPoints[i].x = pOutPoints[i-1].x + pOffsets[i].x;
                pOutPoints[i].y = pOutPoints[i-1].y + pOffsets[i].y;
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
    int textZoom = 14;
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
    int forestType, forestAge;
    FILE *binFile;
    NSString *savePointsFile = nil;
    FILE *savePointsFID = nil;
    CGColorRef blackColor = NVColor.blackColor.CGColor;
#define OWNER_COLORS    1
#define FWS_COLORS      2
#define typeNWI 1
#define typeFOREST 2
#define typeFEESURF 3
    
    int type;
    
    BOOL opened = [hd open];
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    CGFloat fontSize = 32.0 * screenScale;
    
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
    _pTranViewtoLL = STRANBoundsToCornersP(&factoredCornerPoints, pvbounds);

    if ([areaType isEqualToString:@"NWI"] )
    {
        type = typeNWI;
        table = @"NWIDATA.NWI";
        binFile = hd.fidNWIBin;
        query = [NSString stringWithFormat:@"SELECT RECNUM,OBJECTID,FIRSTX,FIRSTY,NumPoints,NumPoly,rectype,compressionType,hasCurves,offset,recordLen, spcc_desc FROM %@,%@_index WHERE %@.RECNUM=%@_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",table,table,table,table,
                 platlonBounds->xmn*hd.NWIFactor, platlonBounds->xmx*hd.NWIFactor, platlonBounds->ymn*hd.NWIFactor, platlonBounds->ymx*hd.NWIFactor];
    }
    else if ([areaType isEqualToString:@"FOREST"] )
    {
        type = typeFOREST;
        table = @"FORESTDATA.FOREST";
        binFile = hd.fidForestBin;
        query = [NSString stringWithFormat:@"SELECT RECNUM,RECNUM,FIRSTX,FIRSTY,NumPoints,NumPoly,rectype,compressionType,hasCurves,offset,recordLen, MN_CTYPE.MN_CTYPE,MN_CTYPE.VALUE,SURVEY_YR,STAND_AGE,MN_SIZE,MN_DENS,UTYPE,USIZE,UDENSE FROM %@,%@_index,FORESTDATA.MN_CTYPE WHERE %@.RECNUM=%@_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f AND FORESTDATA.MN_CTYPE.MN_CTYPE=FORESTDATA.FOREST.MN_CTYPE",table,table,table,table,
                 platlonBounds->xmn*hd.ForestFactor, platlonBounds->xmx*hd.ForestFactor, platlonBounds->ymn*hd.ForestFactor, platlonBounds->ymx*hd.ForestFactor];
        if (CRAPI.sharedInstance.evaluateEdges)
        {
            savePointsFile = [NSString stringWithFormat:@"%@savedPoints.bin", NSTemporaryDirectory()];
            savePointsFID = fopen (savePointsFile.UTF8String,"w+b");
        }
        
    }
    else if ([areaType isEqualToString:@"FEESURF"] )
    {
        type = typeFEESURF;
        table = @"FEESURFDATA.FEESURF";
        binFile = hd.fidFEESURFBin;
        query = [NSString stringWithFormat:@"SELECT RECNUM,RECNUM,FIRSTX,FIRSTY,NumPoints,NumPoly,rectype,compressionType,hasCurves,offset,recordLen,LANDTYPE, SU_ACRES,SU_PCTFORTY FROM %@,%@_index WHERE %@.RECNUM=%@_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",table,table,table,table,
                 platlonBounds->xmn*hd.ForestFactor, platlonBounds->xmx*hd.ForestFactor, platlonBounds->ymn*hd.ForestFactor, platlonBounds->ymx*hd.ForestFactor];
    }
NextPass:
    SQLOK(__FILE__,__LINE__,SQLitePrepare(hd.database, query.UTF8String, -1, &statement, 0), hd.database);
    while ([self continueProcessing] && sqlite3_step(statement) == SQLITE_ROW)
    {
        int i = 0;
        int forestCode = 0;
        NSString * text = @"";
        
        INT64 recnum = sqlite3_column_int64(statement,i++);
        INT64 objectid = sqlite3_column_int64(statement,i++);
        //if (objectid != 524665)
        //    continue;
        //if (objectid != 2372183)
        //    continue;
        BasePt.x = sqlite3_column_int(statement,i++);
        BasePt.y = sqlite3_column_int(statement,i++);
        numPoints = sqlite3_column_int(statement,i++);
        if (numPoints > 500000)
            continue;
        numLoops = sqlite3_column_int(statement,i++);
        //numLoops = 1;
        int rectype = sqlite3_column_int(statement,i++);
        int compressionType = sqlite3_column_int(statement,i++);
        int hasCurves = sqlite3_column_int(statement,i++);
        INT64 offset = sqlite3_column_int64(statement,i++);
        int reclen = sqlite3_column_int(statement,i++);
        if (recnum == 170552 && _zoom > 14)
            ii=1;
        switch (type)
        {
            case typeNWI:
            {
                LPSTR pspcc_Desc = (LPSTR)sqlite3_column_text(statement,i++);
                NSString *spcc_Desc = [NSString stringWithUTF8String:pspcc_Desc];
                text = spcc_Desc;
            }
                break;
            case typeFOREST:
            {
                int standType = (LPSTR)sqlite3_column_int(statement,i++);
                forestType = standType;
                LPSTR standDesc = (LPSTR)sqlite3_column_text(statement,i++);
                int surveyYear = (LPSTR)sqlite3_column_int(statement,i++);
                int standAge = (LPSTR)sqlite3_column_int(statement,i++);
                int TRUEAGE=(2022-surveyYear)+standAge;
                forestAge = TRUEAGE;
                if (standAge > 0)
                    text = [NSString stringWithFormat:@"%s\nAge:%i",standDesc,TRUEAGE];
                else
                {
                    text = [NSString stringWithFormat:@"%s",standDesc];
                    forestAge = 0;
                }
                if (standType == 12)
                {
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
            case typeFEESURF:
            {
                LPSTR landtype = (LPSTR)sqlite3_column_text(statement,i++);
                double acres = sqlite3_column_double(statement,i++);
                double pctforty = sqlite3_column_double(statement,i++);
                acres *= pctforty / 100;
                text = [NSString stringWithUTF8String:landtype];
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
        LPINT polyPartLenThinned = 0;
        MNMXCORD bounds1;
        LPMNMXCORD polyBounds = malloc (numLoops * sizeof(MNMXCORD) + 4);
        if (numLoops > 1)
        {
            BigReadF(binFile, polyPartLen, numLoops*sizeof(int));
            BigReadF(binFile, polyBounds, numLoops*sizeof(MNMXCORD));
            bounds1 = *polyBounds;
            for (int iPoly=0;iPoly<numLoops;iPoly++)
            {
                DPOINT minPoint, maxPoint;
                
                minPoint.x = polyBounds[iPoly].xmn * hd.NWIFactor;
                maxPoint.x = polyBounds[iPoly].xmx * hd.NWIFactor;
                minPoint.y = polyBounds[iPoly].ymn * hd.NWIFactor;
                maxPoint.y = polyBounds[iPoly].ymx * hd.NWIFactor;
                minPoint = TranDPOINTP(&minPoint, _pTranLLtoView);
                maxPoint = TranDPOINTP(&maxPoint, _pTranLLtoView);
                polyBounds[iPoly].xmn = minPoint.x;
                polyBounds[iPoly].xmx = maxPoint.x;
                polyBounds[iPoly].ymn = minPoint.y;
                polyBounds[iPoly].ymx = maxPoint.y;
            }
        }
        MNMXCORD bounds2;
        DBoundsInit (&bounds2);
        for (int i = 0; i < numPoints; i++)
        {
            llpoints[i] = TranDPOINTP(&llpoints[i], _pTranLLtoView);
            DPOINT pt = llpoints[i] ;
            DPOINT point = TranDPOINTP(&pt, _pTranViewtoLL);
            point.x /= hd.NWIFactor;
            point.y /= hd.NWIFactor;
            AddDPointToMinMax(&point, &bounds2);
            if (numLoops > 0 && i == polyPartLen[0])
            {
                double diff=bounds1.xmn - bounds2.xmn;
                diff = bounds1.xmx - bounds2.xmx;
                diff = bounds1.ymn - bounds2.ymn;
                diff = bounds1.ymx - bounds2.ymx;
                ii = 1;
            }
        }
        
        if (type == typeFOREST)
        {
            if (savePointsFID)
                forestCode = 0;
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
            BOOL doThinning = FALSE;
            if (_zoom < 1)
                doThinning = TRUE;
            if (doThinning || savePointsFID)
            {
                int numPointsOrig = numPoints;
                LPDPOINT llpointsThinned = ThinPoints (llpoints,&numPoints,&numLoops,polyPartLen,&polyPartLenThinned,pvbounds);
                if (savePointsFID)
                {
                    LPPOINT intPoints = malloc (numPoints * sizeof(POINT)+4);
                    int numInPoints = 0;
                    for (int i = 0; i< numPoints;i++)
                    {
                        intPoints[numInPoints].x = IDNINT(llpointsThinned[i].x);
                        intPoints[numInPoints].y = IDNINT(llpointsThinned[i].y);
                        if (POINTInBounds (&intPoints[numInPoints],pvbounds))
                            numInPoints++;
                    }
                    if (numInPoints)
                    {
                        BigWriteF(savePointsFID,&numInPoints,sizeof(int),-1);
                        BigWriteF(savePointsFID,&objectid,sizeof(INT64),-1);
                        BigWriteF(savePointsFID,&forestType,sizeof(int),-1);
                        BigWriteF(savePointsFID,&forestAge,sizeof(int),-1);
                        int nwritten = BigWriteF(savePointsFID, intPoints, numInPoints * sizeof(POINT),-1) + 4;
                    }
                    free (intPoints);
                }
                int totpntj = 0;
                int totpntk = 0;
                int numNewLoops = 0;
                if (numLoops > 1)
                {
                    LPINT newPolyPartLenThinned = malloc (numLoops * sizeof(int)+4);
                    for (int i=0;i<numLoops;i++)
                    {
                        int j = polyPartLenThinned[i];
                        int k = polyPartLen[i];
                        if (j)
                            newPolyPartLenThinned[numNewLoops++] = j;
                        totpntj += j;
                        totpntk += k;
                    }
                    if (totpntj != numPoints)
                        ii = 1;
                    if (totpntk != numPointsOrig)
                        ii = 1;
                    free (polyPartLenThinned);
                    polyPartLenThinned = newPolyPartLenThinned;
                    numLoops = numNewLoops;
                }
                free (llpoints);
                free (polyPartLen);
                llpoints = llpointsThinned;
                polyPartLen = polyPartLenThinned;
            }
            LPDPOINT llpointsThinned = RemoveOutOfBoundsPolys (llpoints,&numPoints,&numLoops,polyPartLen,polyBounds,&polyPartLenThinned,pvbounds);
            if (llpointsThinned)
            {
                free (llpoints);
                free (polyPartLen);
                llpoints = llpointsThinned;
                polyPartLen = polyPartLenThinned;

            }
            if (numPoints > 2)
            {
                [self fillArea:context
                       nPoints:numPoints
                        points:llpoints
                     withColor:color
                     lineColor:blackColor
                     lineWidth:0];
                
                if (_zoom >= textZoom)
                {
                    [self drawArea:context
                           nPoints:numPoints
                            nLoops:numLoops
                           partLen:polyPartLen
                            points:llpoints
                         withColor:UIColor.blackColor.CGColor
                          andWidth:1.5];
                    
                    if (text.length)
                    {
                        UIColor *textColor = UIColor.blackColor;
                        CGFloat minFontSize = fontSize / 3;
                        [NVTextDrawing drawText:text
                                      inContext:context
                                  withinPolygon:llpoints
                                  withNumPoints:numPoints
                                    andNumLoops:numLoops
                                        loopLen:polyPartLen
                                   withinBounds:pvbounds
                                       fontSize:fontSize
                                    minFontSize:minFontSize
                                      textColor:textColor
                                    shadowColor:nil
                                   processingID:_processingID];
                    }
                }
            }
            
        }
        
        free (llpoints);
        free (polyPartLen);
        free (polyBounds);
    }
    
    SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), hd.database);
    [hd close:opened];
    
    CloseTRANS2P(&_pTranLLtoView);
    CloseTRANS2P(&_pTranViewtoLL);
    if (savePointsFID)
    {
        int flen = fseek(savePointsFID, 0, SEEK_END);
        flen = ftell (savePointsFID);
        fseek(savePointsFID, 0, SEEK_SET);
        [self evaluateEdges:savePointsFID];
        fclose (savePointsFID);
        DeleteFile(savePointsFile);
    }
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

LPDPOINT ThinPoints (LPDPOINT llPoints,LPINT pNumPoints,LPINT pNumLoops,LPINT polyPartLen,LPINT *ppolyPartLenThinned,LPMNMXCORD pBounds)
{
    int lastx,lasty,thisx, thisy;
    int inLoop = 0;
    int pointIndexInLoop = -1;
    int numThinnedPoints = 0;
    static BOOL keepAll = FALSE;
    LPDPOINT llPointsThinned = malloc(*pNumPoints * sizeof(DPOINT) + 4);
    LPINT polyPartLenThinned = malloc(*pNumLoops*sizeof(int)+4);
    DPOINT firstPoint;
    if (*pNumLoops > 1)
    {
        polyPartLenThinned[0] = polyPartLen[0];
        pointIndexInLoop = 0;
    }
    firstPoint = *llPoints;
    lastx = RoundToHundred (&llPoints->x);
    lasty = RoundToHundred (&llPoints->y);
    llPointsThinned[numThinnedPoints++] = *llPoints++;
    for (int i = 1;i<*pNumPoints;i++,llPoints++)
    {
        BOOL skipPoint = FALSE;
        if (*pNumLoops > 1)
        {
            if (pointIndexInLoop == polyPartLen[inLoop])
            {
                inLoop++;
                pointIndexInLoop = 0;
                polyPartLenThinned[inLoop] = polyPartLen[inLoop];
                lastx = lasty = -1000000;
                //skipPoint = TRUE;
            }
            else
                pointIndexInLoop++;
        }
        if (!skipPoint)
        {
            thisx = RoundToHundred (&llPoints->x);
            thisy = RoundToHundred (&llPoints->y);
            if ((thisx != lastx) || (thisy != lasty) || keepAll)
            {
                llPointsThinned[numThinnedPoints++] = *llPoints;
            }
            else
            {
                if (*pNumLoops > 1)
                {
                    polyPartLenThinned[inLoop]--;
                }
            }
            lastx = thisx;
            lasty = thisy;
        }
    }
    *pNumPoints = numThinnedPoints;
    *ppolyPartLenThinned = polyPartLenThinned;
    return llPointsThinned;
}
LPDPOINT RemoveOutOfBoundsPolys  (LPDPOINT llPoints,LPINT pNumPoints,LPINT pNumLoops,LPINT polyPartLen,LPMNMXCORD polyBounds,LPINT *ppolyPartLenThinned,LPMNMXCORD pBounds)
{
    LPDPOINT thinnedPoints = 0;
    if (*pNumLoops < 2)
        return thinnedPoints;
    int iPoint = 0;
    int numNewLoops = 0;
    int numNewPoints = 0;
    int inc = 0;
    if (*pNumPoints > 600000)
        ii = 1;
    thinnedPoints = malloc (*pNumPoints * sizeof(DPOINT)+4);
    LPINT polyPartLenThinned = malloc (*pNumLoops * sizeof(int)+4);
    for (int iLoop = 0;iLoop< *pNumLoops;iLoop++)
    {
        MNMXCORD loopBounds = polyBounds[iLoop];
        //MNMXCORD loopBounds = PolyBounds(&llPoints[iPoint], polyPartLen[iLoop]);
        if (BoundsInBounds(&loopBounds,pBounds,1))
        {
            polyPartLenThinned[numNewLoops++] = polyPartLen[iLoop];
            memmove (&thinnedPoints[numNewPoints],&llPoints[iPoint],(polyPartLen[iLoop]+inc)*sizeof(DPOINT));
            numNewPoints += polyPartLen[iLoop] + inc;
        }
        inc = 1;
        iPoint += polyPartLen[iLoop];
        if (iLoop)
            iPoint++;
    }
    if (!numNewLoops)
    {
        free (thinnedPoints);
        thinnedPoints = 0;
        free (polyPartLenThinned);
    }
    else
    {
        *ppolyPartLenThinned = polyPartLenThinned;
    }
    *pNumPoints = numNewPoints;
    *pNumLoops = numNewLoops;
    return thinnedPoints;
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
            ii = pPartLen[loop];
            
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
        int nBlobBytes = sqlite3_column_bytes(statement,i);
        int *polyPartLen = (int *)sqlite3_column_blob(statement,i++);
        int nBlobBytes2 = sqlite3_column_bytes(statement,i);
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
            int nLoopTot = 0;
            if (numLoops > 1)
            {
                numLoops--;
                for (int i = 0;i < numLoops;i++)
                {
                    nLoopTot += polyPartLen[i];
                }
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


- (void)fillArea:(CGContextRef)context
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
- (void)drawArea:(CGContextRef)context
         nPoints:(int)np
          nLoops:(int)nLoops
         partLen:(int *)pPartLen
          points:(LPDPOINT)pPoints
       withColor:(CGColorRef)color
        andWidth:(CGFloat)width
{
    CGContextSetLineWidth(context, width*4);
    
    if (nLoops > 1)
    {
        int ip = 0;
        int ii;
        
        for (int loop = 0; loop < nLoops; loop++)
        {
            CGContextMoveToPoint(context, pPoints[ip].x, pPoints[ip].y);
            ip++;
            ii = pPartLen[loop];
            int iEndLoop = pPartLen[loop];
            for (int i = 1; i < iEndLoop; i++)
            {
                CGContextAddLineToPoint(context, pPoints[ip].x, pPoints[ip].y);
                ip++;
            }
            
            if (loop)
                ip++;
            
            if (!CGContextIsPathEmpty(context))
            {
                CGContextSetStrokeColorWithColor(context,color);
                //color = UIColor.greenColor.CGColor;
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
    CGColorRef blackColor = UIColor.blackColor.CGColor;
    CGColorRef whiteColor = UIColor.whiteColor.CGColor;
    
    for (UserWaypoint* waypoint in userWaypointArray)
    {
        CGColorRef fillColor = UIColor.orangeColor.CGColor;
        DPOINT pt = TranLLPOINT(waypoint.latlon, _pTranLLtoView);
        dc.width = 4;
        dc.penColor = [UIColor orangeColor];
        PointSymbols symbol = CircleSym;
        if ([waypoint.type isEqual:@"Vehicle"])
        {
            dc.penColor = [UIColor greenColor];
            fillColor = UIColor.greenColor.CGColor;
            dc.width = 8;
            symbol = Star2Sym;
        }
        if ([waypoint.type isEqual:@"CompassPoint"])
        {
            dc.penColor = [UIColor blueColor];
            fillColor = UIColor.blueColor.CGColor;
            dc.width = 5;
            symbol = TriangleSym;
        }
        if ([waypoint.type isEqual:@"FlushPoint"])
        {
            dc.penColor = [UIColor blueColor];
            fillColor = UIColor.yellowColor.CGColor;
            dc.width = 5;
            symbol = SquareSym;
        }
        if ([waypoint.type isEqual:@"RetrievePoint"])
        {
            dc.penColor = [UIColor blueColor];
            fillColor = UIColor.brownColor.CGColor;
            dc.width = 5;
            symbol = SquareSym;
        }
        if ([themes setDisplayCharacteristics:dc
                                    displayID:_processingID
                                 compareClass:nil] != DO_NOT_DISPLAY_ITEM)
        {
            int size = dc.width*UIScreen.mainScreen.scale*10;
            [SymbolDictionary drawPointWithSymbol:context
                                               at:&pt
                                      usingSymbol:symbol
                                             Size:size
                                        fillColor:fillColor
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
-(int) displayEdgePoints:(CGContextRef)context
              llCorners:(CORNERPOINTS *) latlonCornerPoints
               LLBounds:(MNMXCORD *)platlonBounds
             viewBounds:(MNMXCORD *)pvbounds
 displayCharacteristics:(DisplayCharacteristics *)dc
                 themes:(Themes*)themes
            pointInArea:(PointInArea *)pia
{
    if (!CRAPI.sharedInstance.evaluateEdges)
        return 0;
    int lineWidth = 25;
    int nDisplayed = 0;
    int numPoints=0;
    int maxScore;
    INT64 currentRef;
    int pointID, lastPointID;
    float score, lastScore;
    NSArray *userWaypointArray = [self getEdgePoints:&maxScore];
    CRAPI.sharedInstance.currentEvaluaterScore = maxScore;
    if (CRAPI.sharedInstance.maxEvaluaterScore)
        maxScore = CRAPI.sharedInstance.maxEvaluaterScore;
     
    
    for (UserWaypoint* waypoint in userWaypointArray)
    {
        CGColorRef fillColor = UIColor.orangeColor.CGColor;
        DPOINT pt;
        pt.x = waypoint.latlon.lon;
        pt.y = waypoint.latlon.lat;
        score = waypoint.name.floatValue;
        if (score == maxScore)
            ii = 1;
        pointID = waypoint.time;
        if (!numPoints)
        {
            CGContextMoveToPoint(context, pt.x,pt.y);
            currentRef = waypoint.refno;
            lastPointID = pointID;
            lastScore = score;
            numPoints = 1;
        }
        else if (waypoint.refno == currentRef && score == lastScore && pointID == lastPointID + 1)
        {
            numPoints++;
            CGContextAddLineToPoint(context, pt.x, pt.y);
            lastPointID = pointID;
        }
        else if (numPoints > 1)
        {
            UIColor *c = [UIColor colorWithRed:1 green:0 blue:0 alpha:min(lastScore/maxScore,1)];
            CGContextSetLineWidth(context, lineWidth);
            CGContextSetStrokeColorWithColor(context,c.CGColor);
            CGContextStrokePath(context);
            nDisplayed++;
            CGContextMoveToPoint(context, pt.x,pt.y);
            currentRef = waypoint.refno;
            lastPointID = pointID;
            lastScore = score;
            numPoints = 1;
        }
        else
        {
            CGContextMoveToPoint(context, pt.x,pt.y);
            currentRef = waypoint.refno;
            lastPointID = pointID;
            lastScore = score;
            numPoints = 1;
        }

    }
    if (numPoints > 1)
    {
        UIColor *c = [UIColor colorWithRed:1 green:0 blue:0 alpha:min(lastScore/maxScore,1)];
        CGContextSetLineWidth(context, lineWidth);
        CGContextSetStrokeColorWithColor(context,c.CGColor);
        CGContextStrokePath(context);
        nDisplayed++;
    }
    return nDisplayed;
}

-(void) evaluateEdges:(FILE*) fid
{
    sqlite3nv *database;
    sqlite3_stmt *statement = NULL;

    NSString *cmd = @"CREATE TABLE EDGES (Point INTEGER PRIMARY KEY, val1 INT, val2 INT, val3 INT,age1 INT, age2 INT, age3 INT, score INT,Refno INT,PointID INT)";
    int numPoints;
    
    NSString *savePointsDB= [NSString stringWithFormat:@"%@savedPoints.slt", NSTemporaryDirectory()];
    DeleteFile (savePointsDB);
    BOOL isOpen = !SQLOK(__FILE__,__LINE__,SQLite_Open(savePointsDB.UTF8String, &database), database);
    
    BOOL rtn = !SQLOK("",0,SQLiteExec(database, cmd.UTF8String, 0, 0, 0), database);
    SQLOK(__FILE__,__LINE__,SQLiteExec(database, "BEGIN", 0, 0, 0), database);

    int val1,val2,val3,score;
    int age1,age2,age3;
    int nDups = 0;
    int totPoints = 0;
    while (BigReadF(fid,&numPoints,sizeof(int)))
    {
        INT64 refno;
        int forestType, forestAge;
        BigReadF (fid,&refno,sizeof(INT64));
        BigReadF (fid,&forestType,sizeof(int));
        BigReadF (fid,&forestAge,sizeof(int));
        LPPOINT pPoints = malloc (numPoints*sizeof(POINT)+4);
        BigReadF (fid,pPoints,numPoints*sizeof(POINT));
        for (int i = 0;i<numPoints;i++)
        {
            totPoints++;
            INT64 pt,pt2;
            int ptx, pty;
            POINT dbPoint = pPoints[i];
            pt = (INT64)pPoints[i].x * UINT_MAX + (INT64)pPoints[i].y;
            NSString *query = [NSString stringWithFormat:@"SELECT * FROM EDGES WHERE Point = %lli",pt];
            SQLOK(__FILE__,__LINE__,SQLitePrepare(database, query.UTF8String, -1, &statement, 0),database);
            int haveRec = 0;
            if (i && pPoints[i].x==pPoints[i-1].x && pPoints[i].y==pPoints[i-1].y)
            {
                nDups++;
            }
            while ([self continueProcessing] && sqlite3_step(statement) == SQLITE_ROW)
            {
                int i = 0;
                haveRec++;
                pt2 = sqlite3_column_int64(statement,i++);
                val1 = sqlite3_column_int(statement,i++);
                val2 = sqlite3_column_int(statement,i++);
                val3 = sqlite3_column_int(statement,i++);
                age1 = sqlite3_column_int(statement,i++);
                age2 = sqlite3_column_int(statement,i++);
                age3 = sqlite3_column_int(statement,i++);
                score = sqlite3_column_int(statement,i++);
            }
            SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), database);
            cmd = nil;
            if (haveRec)
            {
                if (val2 == 0)
                {
                    if (val1 != forestType)
                    {
                        score *= ScoreForest (forestType,forestAge);
                        cmd = [NSString stringWithFormat:@"UPDATE EDGES set val2 = %i, age2 = %i, score = %i WHERE Point = %lli",forestType,forestAge,score,pt];
                    }
                    else
                    {
                        score = ScoreForest (forestType,(forestAge+age1)/2);
                        cmd = [NSString stringWithFormat:@"UPDATE EDGES set val1 = %i, age1 = %i, score = %i WHERE Point = %lli",forestType,(forestAge+age1)/2,score,pt];
                    }
                }
                else if (val3 == 0)
                {
                    if (val1 != forestType && val2 != forestType)
                    {
                        score *= ScoreForest (forestType,forestAge);
                        cmd = [NSString stringWithFormat:@"UPDATE EDGES set val3 = %i, age3 = %i, score = %i  WHERE Point = %lli",forestType,forestAge,score,pt];
                    }
                }
                if (cmd)
                    rtn = !SQLOK(__FILE__,__LINE__,SQLiteExec(database, cmd.UTF8String, 0, 0, 0), database);
            }
            else
            {
                score = ScoreForest (forestType,forestAge);
                cmd = [NSString stringWithFormat:@"INSERT INTO EDGES VALUES(%lli,%i,0,0,%i,0,0,%i,%lli,%i)",pt,forestType,forestAge,score,refno,i];
                rtn = !SQLOK(__FILE__,__LINE__,SQLiteExec(database, cmd.UTF8String, 0, 0, 0), database);
            }
        }
        free (pPoints);
    }

    SQLOK(__FILE__,__LINE__,SQLiteExec(database, "COMMIT", 0, 0, 0),database);
    rtn = SQLOK(__FILE__,__LINE__,SQLite_Close(&database),database);
}

int ScoreForest (int type, int age)
{
    int rtn = 1;
    if (type == 12)
    {
        //aspen
        if (age>6 && age<15)
            rtn = 25;
        else if (age>4 && age<7)
            rtn = 20;
        else if (age>14 && age<25)
            rtn = 20;
        else
            rtn = 10;
    }
    else if (type == 13)
    {
        //birch
        if (age>7 && age<15)
            rtn = 15;
        else if (age>4 && age<7)
            rtn = 12;
        else if (age>14 && age<25)
            rtn = 10;
        else
            rtn = 5;
    }
    else if (type > 50 && type < 59)
    {
        //pines
        if (age>9 && age<25)
            rtn = 15;
        else if (age>4 && age<8)
            rtn = 5;
        else if (age>25 && age<59)
            rtn = 10;
        else
            rtn = 5;
    }
    else if (type > 59 && type < 65)
    {
        //spruce and balsam fir
        if (age>9 && age<25)
            rtn = 15;
        else if (age>4 && age<8)
            rtn = 5;
        else if (age>25 && age<59)
            rtn = 10;
        else
            rtn = 5;
    }
    else if (type > 69 && type < 78)
    {
        //larch, lowland spruce, black spruce
        if (age>9 && age<25)
            rtn = 15;
        else if (age>4 && age<8)
            rtn = 5;
        else if (age>25 && age<59)
            rtn = 10;
        else
            rtn = 5;
    }

    return rtn;
}

-(NSArray*) getEdgePoints:(int *)maxScore
{
    NSMutableArray *array = NSMutableArray.new;
    NSString *savePointsDB= [NSString stringWithFormat:@"%@savedPoints.slt", NSTemporaryDirectory()];
    sqlite3nv *database;
    sqlite3_stmt *statement = NULL;

    *maxScore = 0;
    BOOL isOpen = !SQLOK(__FILE__,__LINE__,SQLite_Open(savePointsDB.UTF8String, &database), database);
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM EDGES WHERE Score > 1 AND Val3 = 0 ORDER BY Refno ASC, PointID ASC"];
    SQLOK(__FILE__,__LINE__,SQLitePrepare(database, query.UTF8String, -1, &statement, 0),database);
    int haveRec = 0;
    INT64 pt;
    int pointID;
    int val1,val2,val3,age1,age2,age3,score;
    INT64 refno;
    while ([self continueProcessing] && sqlite3_step(statement) == SQLITE_ROW)
    {
        int i = 0;
        pt = sqlite3_column_int64(statement,i++);
        val1 = sqlite3_column_int(statement,i++);
        val2 = sqlite3_column_int(statement,i++);
        val3 = sqlite3_column_int(statement,i++);
        age1 = sqlite3_column_int(statement,i++);
        age2 = sqlite3_column_int(statement,i++);
        age3 = sqlite3_column_int(statement,i++);
        score = sqlite3_column_int(statement,i++);
        refno = sqlite3_column_int64(statement,i++);
        pointID = sqlite3_column_int(statement,i++);
        //score = min (score,_topScore);
        UserWaypoint* waypoint = UserWaypoint.new;
        waypoint.refno = refno;
        waypoint.type = @"EdgePoint";
        LLPOINT ptll;
        ptll.lat = pt % UINT_MAX;
        ptll.lon = pt / UINT_MAX;
        waypoint.latlon = ptll;
        waypoint.name = [NSString stringWithFormat:@"%i",score];
        *maxScore = max (*maxScore,score);
        waypoint.time = pointID;
        [array addObject:waypoint];
        haveRec++;
    }
    SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), database);

    SQLOK(__FILE__,__LINE__,SQLite_Close(&database),database);
    //*maxScore = _topScore;
    
    DeleteFile (savePointsDB);

    return array;
}
/*
MN_CTYPE    VALUE    enumerated    Main Cover Type
0    None
1    Ash
6    Willow
9    Lowland Hardwoods
12    Aspen
13    Birch
14    Balm of Gilead
15    Cottonwood
17    Hybrid Poplar
20    Northern Hardwoods
25    Walnut
30    Oak
40    Central Hardwoods
51    White Pine
52    Norway Pine
53    Jack Pine
54    Scotch Pine
55    Ponderosa Pine
61    White Spruce
62    Balsam Fir
64    Norway Spruce
70    Upland Larch
71    Black Spruce-Lowland
72    Tamarack
73    White Cedar
74    Black Spruce-Upland
75    Stagnant Spruce
76    Stagnant Tamarack
77    Stagnant Cedar
78    Offsite Aspen
79    Offsite Oak
81    Red Cedar
82    Cutover Area
83    Lowland Grass
84    Upland Grass
85    Lowland Brush
86    Upland Brush
87    Duff
88    Moss
90    Unknown
91    Agricultural
92    Industrial Develop
93    Recreation Develop
94    Roads
95    Rock Outcrop
96    Permanent Water
97    Nonpermanent Water
98    Marsh
99    Muskeg
*/
@end
