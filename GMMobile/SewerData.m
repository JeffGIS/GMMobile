//  SewerData.m
//  GMMobile

extern int keepProcessing;

#import "SewerData.h"
#import "PickedItem.h"

static BOOL createDirectory = YES;

@interface SewerData ()

@property (nonatomic) GSSiPopoverView *popover;
@property (nonatomic) NSMutableArray *pointsArray;

@end

@implementation SewerData
{
    LPBYTE _textOverlapBuffer;
    int _textOverlapBufferSizeWidth, _textOverlapBufferSizeHeight;
    UIColor *_darkGreen;
}

static SewerData *_sewerData;

- (BOOL)continue
{
    if (self.processingID == keepProcessing)
        return YES;
    
    return NO;
}

- (void)logError:(int)sqlReturn
          method:(char *)method
{
    NSLog(@"%@", [NSString stringWithFormat:@"SQLite Error %i in %s = %i:%s",
                  sqlReturn, method, sqlite3_errcode(_database), sqlite3_errmsg(_database)]);
}

int SQLOKswr(int sqlReturn, char *method)
{
    if (sqlReturn != SQLITE_OK)
    {
        [_sewerData logError:sqlReturn
                      method:method];
    }
    
    return sqlReturn;
}


- (id)init
{
    self = [super init];
    
    if (self)
    {
        _documentsDirectory = UserDefaults.defaults.localFilePath;
        _fileName = @"Sewer.sqlite";
        _path = [NSString stringWithFormat:@"%@/%@", _documentsDirectory, _fileName];
        _sewerData = (__bridge SewerData *)((__bridge sqlite3 *)((SewerData *)self));
        _pointsArray = [[NSMutableArray alloc] init];
        _darkGreen = [[UIColor alloc] initWithRed:0.0
                                            green:0.5
                                             blue:0.0
                                            alpha:1.0];
        

    }
    
    return self;
}

- (void)dealloc
{
    [self close];
    CloseTRANS2 (&_pTranLLtoView);
    CloseTRANS2 (&_pTranViewtoLL);
    NSLog(@"Sewer Database dealloc");
}

- (void)open
{
    if (!_isOpen)
    {
        _isOpen = !SQLOKswr(sqlite3_open(self.path.UTF8String, &_database), "open(Sewer)");
        NSLog(@"Sewer Database open");
        
        _fileSize = [NSFileManager.defaultManager attributesOfItemAtPath:_path
                                                                   error:nil].fileSize;
    }
}

- (void)close
{
    if (_isOpen)
    {
        SQLOKswr(sqlite3_close(_database),"Close");
        NSLog(@"Sewer Database close");
    }
    _isOpen = NO;
}

- (void)clear
{
    [self close];
    
    BOOL st = [NSFileManager.defaultManager removeItemAtPath:_path
                                                       error:nil];
}

- (BOOL)executeCmd:(char *)cmd
{
    BOOL rtn = !SQLOKswr(sqlite3_exec(_database, cmd, 0, 0, 0), "Execute cmd");
    return rtn;
}

- (void)startTransaction
{
    [self open];
    SQLOKswr(sqlite3_exec(_database, "BEGIN", 0, 0, 0), "Start transaction");
}

- (void)commitTransaction
{
    SQLOKswr(sqlite3_exec(_database, "COMMIT", 0, 0, 0), "End transaction");
}

- (NSString *)getActualPlatFileName:(NSString *)platID
{
    NSString *outName;
    char name[128];
    strncpy (name, platID.UTF8String, 126);
    LPSTR pU = strrchr(name,'_');
    
    if (pU)
        *pU = 0;
    
    outName = [NSString stringWithUTF8String:name];
    return outName;
}

- (BOOL)loadPlat:(NSString *)platID
          ofType:(NSString*)type
    usingPopover:(GSSiPopoverView *)popover
     andDelegate:(id)delegate
{
    BOOL fileExists = NO;
    NSString *actualPlatID = [self getActualPlatFileName:platID];
    NSString *toDir = [NSString stringWithFormat:@"%@/%@Plats", type,_documentsDirectory];
    NSString *fileName = [NSString stringWithFormat:@"%@.jpg", actualPlatID];
    FTPDataPull *pull = FTPDataPull.pull;
    pull.delegate = delegate;
    pull.popover = _popover;
    pull.useOnlyPrimaryFTP = YES;
    pull.option = GET_SANPLAT;
    //pull.ipAddress = http://74.42.137.128/icons/MPLS/;
    
    [popover showAfter:0.5
              withTitle:[NSString stringWithFormat:@"Get %@ Plat %@", type,actualPlatID]];
    
    pull.ftpSiteOveride = @"74.42.136.100";
    pull.usernameOveride = @"GMMobile";
    pull.passwordOveride = @"GeoMaster";
    pull.portOveride = @"21";
    pull.createDirectory = createDirectory;
    pull.returnIfExists = NO;
    
    if ([pull getFile:fileName
        fromDirectory:[NSString stringWithFormat:@"Sewer/%@/Plats",type]
               toFile:fileName
          toDirectory:toDir
         forceRefresh:NO] == FTPStatusFileExists)
    {
        fileExists = YES;
    }
    
    createDirectory = NO;
    return fileExists;
}

- (void)FTPdidComplete:(int)option
            withStatus:(int)status
              filePath:(NSString *)path
{
    [_popover hide];
    
    if (status == FTPStatusOK)
    {
        
    }
}

/*- (MNMXCORD)getBoundsForSanPlat:(int)refno
{
    MNMXCORD bounds;
    
    sqlite3_stmt *statement;
    NSString *query = [[NSString alloc] init];
    
    [self open];
    [self startTransaction];
    [self executeCmd:"CREATE INDEX IF NOT EXISTS PARCELPOLY_pinindex ON PARCELPOLY ('PID' ASC)"];
    [self commitTransaction];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_MPLS:
            query = [NSString stringWithFormat:@"SELECT LAT,LON FROM PARCELPOINT Where PID = '%@'",
                     PID];
            break;
            
        case PROJECT_METROGIS:
            query = [NSString stringWithFormat:@"SELECT PARCELPOLY.id,minX,maxX,minY,maxY FROM PARCELPOLY,PARCELPOLY_index WHERE PARCELPOLY.PID='%@' AND PARCELPOLY_index.id=PARCELPOLY.id",
                     PID];
            break;
    }
    
    SQLOKswr(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "prepareGetBoundsForPID");
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        bounds.xmn = sqlite3_column_double(statement, 1);
        bounds.xmx = sqlite3_column_double(statement, 2);
        bounds.ymn = sqlite3_column_double(statement, 3);
        bounds.ymx = sqlite3_column_double(statement, 4);
    }
    
    SQLOKswr(sqlite3_finalize(statement), "getBoundsforPID");
    
    [self close];
    return bounds;
}*/

BOOL findClosestPoint (LPDPOINT pPoint,LPDPOINT pNearPt,double *mind,LPDPOINT p1)
{
    double d = ArcDistance(*p1,*pPoint);

    if (d < *mind)
    {
        *mind = d;
        *pNearPt = *pPoint;
        return YES;
    }
    return NO;
}

- (int)pickSanPlat:(LLPOINT *)pt
{
    int minRef = 0;
    dbounds bnds;
    DPOINT BasePt, point;
    LPSTR platID;
    int numPoints,numLoops, refno;
    CGFloat d, mind = DBL_MAX;
    CGFloat pickap = 0.005;
    DPOINT p1, p2, minpt;
    NSString *minPlatID=[[NSString alloc] init];
    
    p1.x = pt->lon;
    p1.y = pt->lat;
    minpt = p1;
    bnds.xmn = (p1.x - pickap);
    bnds.xmx = (p1.x + pickap);
    bnds.ymn = (p1.y - pickap);
    bnds.ymx = (p1.y + pickap);
    [self open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT STORM_PLAT.id, STORM_PLAT.PLAT_NAME, BasePointX, BasePointY,NumPoints,NumLoops,PolyPartLen,Points  FROM STORM_PLAT,STORM_PLAT_index WHERE STORM_PLAT.id=STORM_PLAT_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                       bnds.xmn, bnds.xmx, bnds.ymn, bnds.ymx];
    
    sqlite3_stmt *statement;
    
    SQLOKswr(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "preparePickPLAT");
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        refno = sqlite3_column_int(statement, 0);
        platID = (LPSTR)sqlite3_column_text(statement, 1);
        BasePt.x = sqlite3_column_double(statement, 2);
        BasePt.y = sqlite3_column_double(statement, 3);
        numPoints = sqlite3_column_int(statement,4);
        numLoops = sqlite3_column_int(statement,5);
        int *polyPartLen = (int *)sqlite3_column_blob(statement,6);
        int nBlobBytes = sqlite3_column_bytes(statement,6);
        LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement,7);
        nBlobBytes = sqlite3_column_bytes(statement,7);
        
        if (numPoints < 0)
        {
            numPoints = -numPoints;
            LPSPOINT offsetPoints16 = (LPSPOINT)offsetPoints;
            
            for (int i = 0; i < numPoints; i++)
            {
                point.x = (BasePt.x + offsetPoints16[i].x / COORDINATE_FACTOR);
                point.y = (BasePt.y + offsetPoints16[i].y / COORDINATE_FACTOR);
                if (findClosestPoint (&point,&minpt,&mind,&p1))
                    minRef = refno;
            }
        }
        
        else for (int i = 0; i < numPoints; i++)
        {
            point.x = (BasePt.x + offsetPoints[i].x / COORDINATE_FACTOR);
            point.y = (BasePt.y + offsetPoints[i].y / COORDINATE_FACTOR);
            if (findClosestPoint (&point,&minpt,&mind,&p1))
                minRef = refno;
        }
        
    }
    
    SQLOKswr(sqlite3_finalize(statement), "pickPLAT");
    [self close];
    pt->lon = minpt.x;
    pt->lat = minpt.y;
    
    NSString *platFile = [NSString stringWithFormat:@"%@/SanPlats/%@.jpg",
                          _documentsDirectory, minPlatID];
    
    CRAPI.sharedInstance.currentPlatImagePath = platFile;
    return minRef;
}

- (NSString *)getSanPlatIDFromRefno:(int)refno
{
    NSString *platID = [[NSString alloc] init];
    return platID;
}

- (void)displayPlats:(CGContextRef)context
                type:(NSString*)platType
           llCorners:(CORNERPOINTS *) latlonCornerPoints
            LLBounds:(MNMXCORD *)platlonBounds
          viewBounds:(MNMXCORD *)pvbounds
{
    [self setTrans:latlonCornerPoints viewBounds:pvbounds];
    
    NSString *query;
    sqlite3_stmt *statement;
    DPOINT BasePt;
    LPSTR platID;
    int numPoints,numLoops, refno;
    [self open];
    
    query = [NSString stringWithFormat:@"SELECT STORM_PLAT.id, STORM_PLAT.PLAT_NAME, BasePointX, BasePointY,NumPoints,NumLoops,PolyPartLen,Points FROM STORM_PLAT,STORM_PLAT_index WHERE STORM_PLAT.id=STORM_PLAT_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                       platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
    
    SQLOKswr(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "prepareDisplayPlats");
    while ([self continue] && sqlite3_step(statement) == SQLITE_ROW)
    {
        refno = sqlite3_column_int(statement,0);
        platID = (LPSTR)sqlite3_column_text(statement, 1);
        BasePt.x = sqlite3_column_double(statement,2);
        BasePt.y = sqlite3_column_double(statement,3);
        numPoints = sqlite3_column_int(statement,4);
        numLoops = sqlite3_column_int(statement,5);
        int *polyPartLen = (int *)sqlite3_column_blob(statement,6);
        int nBlobBytes = sqlite3_column_bytes(statement,6);
        LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement,7);
        nBlobBytes = sqlite3_column_bytes(statement,7);
        LPDPOINT llpoints = malloc(abs(numPoints) * sizeof(DPOINT) + 4);
        
        if (numPoints < 0)
        {
            numPoints = -numPoints;
            LPSPOINT offsetPoints16 = (LPSPOINT)offsetPoints;
            
            for (int i = 0; i < numPoints; i++)
            {
                llpoints[i].x = (BasePt.x + offsetPoints16[i].x / COORDINATE_FACTOR);
                llpoints[i].y = (BasePt.y + offsetPoints16[i].y / COORDINATE_FACTOR);
                llpoints[i] = TranDPOINT(&llpoints[i], _pTranLLtoView);
            }
        }
        
        else for (int i = 0; i < numPoints; i++)
        {
            llpoints[i].x = (BasePt.x + offsetPoints[i].x / COORDINATE_FACTOR);
            llpoints[i].y = (BasePt.y + offsetPoints[i].y / COORDINATE_FACTOR);
            llpoints[i] = TranDPOINT(&llpoints[i], _pTranLLtoView);
        }
        
        UIColor *color;
        if (refno == CRAPI.sharedInstance.showPlats)
        {
            color = [[UIColor alloc] initWithRed:1.0
                                           green:0.0
                                           blue:0.0
                                           alpha:0.4];
        }
        else
        {
            color = [[UIColor alloc] initWithRed:1.0
                                           green:1.0
                                            blue:0.0
                                           alpha:0.2];
        }
    
        [self fillPlat:context
               nPoints:numPoints
                points:llpoints
             withColor:color.CGColor];
        
        [self drawPlat:context
               nPoints:numPoints
                nLoops:numLoops
               partLen:polyPartLen
                points:llpoints
             withColor:UIColor.redColor.CGColor];
        
        free(llpoints);
    }
    
    SQLOKswr(sqlite3_finalize(statement), "displayPlats");
    [self close];
 
}

- (void)fillPlat:(CGContextRef)context
         nPoints:(int)np
          points:(LPDPOINT)pPoints
       withColor:(CGColorRef)color
{
    CGContextSetLineWidth(context, 3);
    //CGContextFillEllipseInRect(context, pointRect);
    //CGContextStrokeEllipseInRect(context, pointRect);
    //CGContextFillPath(context);
    
    
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

- (void)drawPlat:(CGContextRef)context
         nPoints:(int)np
          nLoops:(int)nLoops
         partLen:(int *)pPartLen
          points:(LPDPOINT)pPoints
       withColor:(CGColorRef)color
{
    
    CGContextSetLineWidth(context, 1);
    //CGContextFillEllipseInRect(context, pointRect);
    //CGContextStrokeEllipseInRect(context, pointRect);
    //CGContextFillPath(context);
    
    if (nLoops > 1)
    {
        int ip=0;
        int ii;
        
        for (int loop=0; loop < nLoops; loop++)
        {
            CGContextMoveToPoint(context, pPoints[ip].x, pPoints[ip].y);
            ip++;
            ii = pPartLen[loop];
            
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
        
        ii = ip;
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

- (int)pickSewer:(LLPOINT *)pt
   highlightList:(NSMutableArray *)hlist
{
    if (_zoom < CRAPI.sharedInstance.sewerVisibleAtZoom)
        return 0;
    int nPicked = 0;
    dbounds bnds;
    CGFloat d, mind = DBL_MAX;
    CGFloat pickap = 0.005;
    DPOINT p1, p2, minpt, point,BasePt;
    NSString * minFid=@"";
    int minref = 0;
    int numPoints, numLoops;
    
    p1.x = pt->lon;
    p1.y = pt->lat;
    minpt = p1;
    bnds.xmn = (p1.x - pickap);
    bnds.xmx = (p1.x + pickap);
    bnds.ymn = (p1.y - pickap);
    bnds.ymx = (p1.y + pickap);
    [self open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT STORM_LINE.id, STORM_LINE.FACILITY_ID, BasePointX, BasePointY,NumPoints,NumLoops,PolyPartLen,Points  FROM STORM_LINE,STORM_LINE_index WHERE STORM_LINE.SYMBOLNAME = \"STRM_PIPE\" AND STORM_LINE.id=STORM_LINE_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                       bnds.xmn, bnds.xmx, bnds.ymn, bnds.ymx];
    
    sqlite3_stmt *statement;
    
    SQLOKswr(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "preparePickPLAT");
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        int refno = sqlite3_column_int(statement, 0);
        LPSTR FACILITY_ID = (LPSTR)sqlite3_column_text(statement, 1);
        BasePt.x = sqlite3_column_double(statement, 2);
        BasePt.y = sqlite3_column_double(statement, 3);
        numPoints = sqlite3_column_int(statement,4);
        numLoops = sqlite3_column_int(statement,5);
        int *polyPartLen = (int *)sqlite3_column_blob(statement,6);
        int nBlobBytes = sqlite3_column_bytes(statement,6);
        LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement,7);
        nBlobBytes = sqlite3_column_bytes(statement,7);
        
        if (numPoints < 0)
        {
            numPoints = -numPoints;
            LPSPOINT offsetPoints16 = (LPSPOINT)offsetPoints;
            
            for (int i = 0; i < numPoints; i++)
            {
                point.x = (BasePt.x + offsetPoints16[i].x / COORDINATE_FACTOR);
                point.y = (BasePt.y + offsetPoints16[i].y / COORDINATE_FACTOR);
                if (findClosestPoint (&point,&minpt,&mind,&p1))
                {
                    nPicked++;
                    minref = refno;
                    minFid = [NSString stringWithUTF8String:FACILITY_ID];
                }
            }
        }
        
        else for (int i = 0; i < numPoints; i++)
        {
            point.x = (BasePt.x + offsetPoints[i].x / COORDINATE_FACTOR);
            point.y = (BasePt.y + offsetPoints[i].y / COORDINATE_FACTOR);
            if (findClosestPoint (&point,&minpt,&mind,&p1))
            {
                nPicked++;
                minref = refno;
                minFid = [NSString stringWithUTF8String:FACILITY_ID];
            }
        }
/*        p2.x = lon;
        p2.y = lat;
        d = ArcDistance(p1, p2);
        
        if (d < mind)
        {
            minref = refno;
            mind = d;
            minpt = p2;
            minFid = [NSString stringWithUTF8String:FACILITY_ID];
            nPicked = 1;
        }*/
    }
    
    SQLOKswr(sqlite3_finalize(statement), "pickPLAT");
    [self close];
    pt->lon = minpt.x;
    pt->lat = minpt.y;
    
    if (nPicked)
    {
        PickedItem *pi = [[PickedItem alloc] init];
        pi.refno = minref;
        pi.itemType = PTStormSewerLine;
        pi.distance = mind;
        pi.pickedPoint = minpt;
        pi.identifier = minFid;
        pi.symbolName = @"STRM_PIPE";
        [hlist addObject:pi];
    }
    
    return nPicked;
}

- (NSMutableArray *)getAllSanPlats
{
    NSMutableArray *list = [[NSMutableArray alloc] init];
    [self open];
    
    NSString *query = @"SELECT PLAT FROM SANPLATAREAS";
    
    sqlite3_stmt *statement;
    
    SQLOKswr(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "prepareGetAllSanPlats");
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR platID = (LPSTR)sqlite3_column_text(statement, 0);
        NSString *plat = [NSString stringWithUTF8String:platID];
        [list addObject:plat];
    }
    
    SQLOKswr(sqlite3_finalize(statement), "getAllSanPlats");
    [self close];
    return list;
}

- (NSMutableArray *)getAllStormPlats
{
    NSMutableArray *list = [[NSMutableArray alloc] init];
    [self open];
    
    NSString *query = @"SELECT PLAT_NAME FROM STORM_PLAT";
    
    sqlite3_stmt *statement;
    
    SQLOKswr(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "prepareGetAllSanPlats");
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR platID = (LPSTR)sqlite3_column_text(statement, 0);
        NSString *plat = [NSString stringWithUTF8String:platID];
        [list addObject:plat];
    }
    
    SQLOKswr(sqlite3_finalize(statement), "getAllSanPlats");
    [self close];
    return list;
}

LPSTR $RND(int i,double val,int ndec,BOOL addCommas,BOOL removeZ)
{
    static char rtn[2][32];
    char fmt[12];
    
    sprintf(fmt, "%%.%if", ndec);
    sprintf(rtn[i], fmt, val);
    
    if (removeZ)
    {
        int l = (int)strlen(rtn[i]);
        LPSTR pLoc = &rtn[i][l - 1];
        
        while (*pLoc == '0')
            pLoc--;
        
        if (*pLoc == '.')
            pLoc--;
        
        *(++pLoc) = 0;
    }
    
    return rtn[i];
}

- (void)setTrans:(CORNERPOINTS *)corners
      viewBounds:(MNMXCORD *)pvbounds
{

    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    _pTranLLtoView = STRANCornersToBounds(corners, pvbounds);
}


- (void)displayStormLine:(CGContextRef)context
                    pass:(int)pass
               llCorners:(CORNERPOINTS *) latlonCornerPoints
                LLBounds:(MNMXCORD *)platlonBounds
              viewBounds:(MNMXCORD *)pvbounds
{
    
    if (![self continue])
        return;
    
    NSString *query, *queries;
    sqlite3_stmt *statement;
    DPOINT BasePt;
    int numPoints,numLoops;
    LPSTR symName;
    CGColorRef color;
    int startpass=0;
    
    CGFloat width, invertIn, invertOut, diameterIn, widthIn, heightIn;
    LPSTR pipeShape, material;
    NSString *lineText = @"";
    BOOL addPointers;
    
    CGFloat sizeFactor = 1;
    
    if (_zoom > 18)
        sizeFactor *= (2.0 * (_zoom - 18.0));
    
    else if (_zoom < 18)
        sizeFactor /= (2.0 * (18.0 - _zoom));
    
    [self setTrans:latlonCornerPoints viewBounds:pvbounds];
    
    [self open];
    
    if (pass == TEXT_PASS)
    {
        startpass = 1;
        _textOverlapBufferSizeWidth = pvbounds->xmx - pvbounds->xmn;
        _textOverlapBufferSizeHeight = pvbounds->ymx - pvbounds->ymn;
        _textOverlapBuffer = (LPBYTE)calloc(_textOverlapBufferSizeWidth * _textOverlapBufferSizeHeight, 1);
    }
    for (int ipass = startpass; ipass < 2; ipass++)
    {
        switch (ipass)
        {
            case 1:
                /*CREATE TABLE STORM_MAIN ('FACILITY_ID' CHAR(12),'OBJECTID' INT,'Shape' CHAR(64),'Enabled' INT,'YEAR_BUILT' INT,'STATUS' CHAR(20),'DOCUMENT_LINK' CHAR(250),'BUILT_BY' CHAR(32),'DATA_SOURCE' CHAR(70),'DATA_SOURCE_TYPE' CHAR(16),'SOURCE_USED' CHAR(200),'OWNER' CHAR(60),'MAINTAINED_BY' CHAR(40),'CREATED_BY' CHAR(20),'CREATED_DATE' INT,'LAST_MODIFIED_BY' CHAR(20),'SUBTYPE_CODE' INT,'COMMON_NAME' CHAR(32),'MATERIAL' CHAR(60),'SOURCE_LENGTH_FT' REAL,'MANNINGS_N' REAL,'LINED' CHAR(3),'CAST_IN_PLACE' CHAR(3),'INVERT_IN_ELEV' REAL,'INVERT_OUT_ELEV' REAL,'DIAMETER_IN' REAL,'EQUIVALENT_DIAMETER_IN' REAL,'WIDTH_IN' REAL,'HEIGHT_IN' REAL,'HEIGHT_FT' REAL,'PLAT' CHAR(64),'PIPE_SHAPE' CHAR(30),'UP_NODE' CHAR(12),'DOWN_NODE' CHAR(12),'COMMENTS' CHAR(250),'CONFIDENCE' CHAR(1),'LOCATOR_NAME' CHAR(12),'GlobalID' CHAR(38),'PACP_SHAPE' CHAR(1),'PACP_HEIGHT' REAL,'PACP_CITY' CHAR(10),'PACP_LOCATION' CHAR(64),'YEAR_LINED' INT,'LAST_MODIFIED_DATE' INT,'UDI' CHAR(12),'MODELING_PIPE_SHAPE' INT,'MODELING_PIPE_SHAPE_INDEX' INT,'PACP_YEAR_BUILT' INT,'PACP_MATERIAL' CHAR(5),'Shape_STLength__' REAL,'Shape_STLength_1' REAL,'Shape_Length' REAL,PRIMARY KEY('FACILITY_ID' ASC))*/
                
                query = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,\
                         STORM_LINE.SYMBOLNAME,\
                         STORM_MAIN.INVERT_IN_ELEV,\
                         STORM_MAIN.INVERT_OUT_ELEV,\
                         STORM_MAIN.DIAMETER_IN,\
                         STORM_MAIN.WIDTH_IN,\
                         STORM_MAIN.HEIGHT_IN,\
                         STORM_MAIN.PIPE_SHAPE,\
                         STORM_MAIN.MATERIAL \
                         FROM STORM_LINE,STORM_LINE_index,STORM_MAIN WHERE STORM_LINE.SYMBOLNAME = \"STRM_PIPE\" AND STORM_MAIN.FACILITY_ID = STORM_LINE.FACILITY_ID AND STORM_LINE.id=STORM_LINE_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                         platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
                break;
                
            case 0:
                query = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,SYMBOLNAME FROM STORM_LINE,STORM_LINE_index WHERE STORM_LINE.SYMBOLNAME != \"STRM_PIPE\" AND STORM_LINE.id=STORM_LINE_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                         platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
                break;
        }
        
        SQLOKswr(sqlite3_prepare_v2(self.database, query.UTF8String, -1, &statement, 0), "prepareDisplayStormLine");
        
        while ([self continue] && sqlite3_step(statement) == SQLITE_ROW)
        {
            BasePt.x = sqlite3_column_double(statement,0);
            BasePt.y = sqlite3_column_double(statement,1);
            numPoints = sqlite3_column_int(statement,2);
            numLoops = sqlite3_column_int(statement,3);
            int *polyPartLen = (int *)sqlite3_column_blob(statement,4);
            int nBlobBytes = sqlite3_column_bytes(statement,4);
            LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement,5);
            nBlobBytes = sqlite3_column_bytes(statement,5);
            LPDPOINT llpoints = malloc(abs(numPoints) * sizeof(DPOINT) + 4);
            symName = (LPSTR)sqlite3_column_text(statement,6);
            invertIn = sqlite3_column_double(statement,7);
            invertOut = sqlite3_column_double(statement,8);
            diameterIn = sqlite3_column_double(statement,9);
            widthIn = sqlite3_column_double(statement,10);
            heightIn = sqlite3_column_double(statement,11);
            pipeShape = (LPSTR)sqlite3_column_text(statement,12);
            material = (LPSTR)sqlite3_column_text(statement,13);
            
            if (numPoints < 0)
            {
                numPoints = -numPoints;
                LPSPOINT offsetPoints16 = (LPSPOINT)offsetPoints;
                
                for (int i = 0; i < numPoints; i++)
                {
                    llpoints[i].x = (BasePt.x + offsetPoints16[i].x / COORDINATE_FACTOR);
                    llpoints[i].y = (BasePt.y + offsetPoints16[i].y / COORDINATE_FACTOR);
                    llpoints[i] = TranDPOINT(&llpoints[i], _pTranLLtoView);
                }
            }
            
            else for (int i = 0; i < numPoints; i++)
            {
                llpoints[i].x = (BasePt.x + offsetPoints[i].x / COORDINATE_FACTOR);
                llpoints[i].y = (BasePt.y + offsetPoints[i].y / COORDINATE_FACTOR);
                llpoints[i] = TranDPOINT(&llpoints[i], _pTranLLtoView);
            }
            
            if (!strcasecmp(symName, "STRM_PIPE"))
            {
                CGFloat pattern[2] = {40.0, 10.0};
                addPointers = YES;
                width = (9.0 * sizeFactor);
                CGContextSetLineDash (context, 5, pattern, 2);
                color = _darkGreen.CGColor;
                
                if (diameterIn <= 0)
                {
                    lineText = [NSString stringWithFormat:@"%.2f\t%s\"x%s\" %s\t%.2f",
                                invertIn, $RND(0, widthIn, 1, FALSE, TRUE),
                                $RND(1, heightIn, 1, FALSE, TRUE), material, invertOut];
                }
                
                else
                {
                    lineText = [NSString stringWithFormat:@"%.2f\t%s\" %s\t%.2f",
                                invertIn, $RND(0, diameterIn, 1, FALSE, TRUE), material, invertOut];
                };
            }
            
            else
            {
                addPointers = NO;
                lineText = @"";
                width = (3 * sizeFactor);
                CGContextSetLineDash (context, 1, NULL, 0);
                color = UIColor.greenColor.CGColor;
            }
            
            [self drawStormLine:context
                           pass:pass
                        nPoints:numPoints
                         points:llpoints
                      withColor:color
                       andWidth:width
                        andText:lineText
                    andPointers:addPointers];
        }
        
        SQLOKswr(sqlite3_finalize(statement), "");
    }
    
    if (pass == TEXT_PASS)
    {
        free (_textOverlapBuffer);
    }

    [self close];
}

- (void)drawStormLine:(CGContextRef)context
                 pass:(int)pass
              nPoints:(int)np
               points:(LPDPOINT)pPoints
            withColor:(CGColorRef)color
             andWidth:(CGFloat)width
              andText:(NSString *)text
          andPointers:(BOOL)addPointers
{
    static CGFloat startDist = 0;
    if (pass == LINE_PASS)
    {
        CGContextSetLineWidth(context, width);
        CGContextMoveToPoint(context, pPoints[0].x, pPoints[0].y);
        
        for (int i = 1; i < np; i++)
            CGContextAddLineToPoint(context, pPoints[i].x, pPoints[i].y);
        
        //CGContextAddLineToPoint(context, pPoints[0].x, pPoints[0].y);
        
        if (!CGContextIsPathEmpty(context))
        {
            CGContextSetStrokeColorWithColor(context, color);
            CGContextDrawPath(context, kCGPathStroke);
        }
        
        if (addPointers)
        {
            startDist = [self drawDirectionalPointersOnLine:context
                                                  numPoints:np
                                                     points:pPoints
                                                  withColor:color
                                                   andWidth:width
                                                 startingAt:startDist];
        }
    }
    else
    if (text && ![text isEqualToString:@""])
    {
        if (np == 2)
        {
            [self drawTextOnLine:context
                            text:text
                          points:pPoints];
        }
        else
        {
            int maxd = abs (pPoints[1].x - pPoints[0].x)+abs (pPoints[1].y - pPoints[0].y), maxi=0;
            for (int i=1;i<np-1;i++)
            {
                int d = abs (pPoints[i+1].x - pPoints[i].x)+abs (pPoints[i+1].y - pPoints[i].y);
                if (d>maxd)
                {
                    maxd = d;
                    maxi = i;
                }
            }
            [self drawTextOnLine:context
                            text:text
                          points:&pPoints[maxi]];
        }
    }
}

- (CGFloat)drawDirectionalPointersOnLine:(CGContextRef)context
                               numPoints:(int)np
                                  points:(LPDPOINT)pPoints
                               withColor:(CGColorRef)color
                                andWidth:(CGFloat)lineWidth
                              startingAt:(CGFloat)startDist
{
    CGFloat pointerWidth = (lineWidth / 5.0);
    CGFloat pointerLength = (lineWidth * 2.0);
    CGFloat spacing = (lineWidth * 8.0);
    CGFloat nextDist = startDist;
    int startPointIndex = 0;
    
    if (nextDist <= (spacing / 2.0))
        nextDist = spacing;
    
    CGContextSetLineDash (context, 1, NULL, 0);
    
    while (startPointIndex < np-1)
    {
        CGFloat dist = ddistp(&pPoints[startPointIndex], &pPoints[startPointIndex + 1]);
        CGFloat az = getazd (&pPoints[startPointIndex], &pPoints[startPointIndex + 1]);
        DPOINT startPoint, pointerPoint, offsetPoint;
        
        startPoint = pPoints[startPointIndex];
        
        while (dist > nextDist)
        {
            pointerPoint = dnewpoint(&startPoint, az, nextDist);
            startPoint = pointerPoint;
            offsetPoint = dnewpoint(&pointerPoint, (az + (1.5 * HALFPI)), pointerLength);
            dist -= spacing;
            nextDist = spacing;
            CGContextSetLineWidth(context, pointerWidth);
            CGContextMoveToPoint(context, offsetPoint.x, offsetPoint.y);
            CGContextAddLineToPoint(context, pointerPoint.x, pointerPoint.y);
            offsetPoint = dnewpoint(&pointerPoint, (az - (1.5 * HALFPI)), pointerLength);
            CGContextAddLineToPoint(context, offsetPoint.x, offsetPoint.y);
            CGContextSetStrokeColorWithColor(context, color);
            CGContextDrawPath(context, kCGPathStroke);
        }
        
        nextDist -= dist;
        startPointIndex++;
    }
    
    return nextDist;
}

- (void)drawTextOnLine:(CGContextRef)context
                  text:(NSString *)text
                points:(LPDPOINT)points
{
    CGFloat fontSize = 24.0;
    CGFloat az = getazd(&points[0], &points[1]);
    BOOL flip = NO, rectFits = NO;
    NSAttributedString *attString;
    
    if ((az > HALFPI) && (az < (3 * HALFPI)))
    {
        DPOINT savePt = points[0];
        points[0] = points[1];
        points[1] = savePt;
        az += PY;
        flip = YES;
    }
    
    if (_zoom > 18)
        fontSize += ((_zoom - 18.0) * 6.0);
    
    UIColor *color = [[UIColor alloc] initWithRed:0.0
                                            green:0.5
                                             blue:0.0
                                            alpha:1.0];
    
    CGContextSaveGState(context);
    
    NSString *invertIn, *invertOut;
    
    if (flip)
    {
        invertOut = [UserDefaults.defaults includeTextBeforeTab:text];
        invertIn = [UserDefaults.defaults includeTextAfterLastTab:text];
    }
    
    else
    {
        invertIn = [UserDefaults.defaults includeTextBeforeTab:text];
        invertOut = [UserDefaults.defaults includeTextAfterLastTab:text];
    }
    
    NSString *pipe = [UserDefaults.defaults includeTextBeforeTab:
                      [UserDefaults.defaults includeTextAfterTab:text]];
    
    CTFontRef fontRef = CTFontCreateWithName((CFStringRef)@"GillSans-Bold", fontSize, NULL);
    
    NSMutableParagraphStyle *style = NSParagraphStyle.defaultParagraphStyle.mutableCopy;
    style.alignment = NSTextAlignmentCenter;
    
    NSDictionary *pipeAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    (__bridge id)fontRef, kCTFontAttributeName,
                                    style, kCTParagraphStyleAttributeName,
                                    color.CGColor, kCTForegroundColorAttributeName,
                                    nil];
    
    NSDictionary *invertInAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                        (__bridge id)fontRef, kCTFontAttributeName,
                                        style, kCTParagraphStyleAttributeName,
                                        UIColor.redColor.CGColor, kCTForegroundColorAttributeName,
                                        nil];
    
    NSDictionary *invertOutAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                         (__bridge id)fontRef, kCTFontAttributeName,
                                         style, kCTParagraphStyleAttributeName,
                                         UIColor.blueColor.CGColor, kCTForegroundColorAttributeName,
                                         nil];
    
    NSDictionary *shadowAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                      (__bridge id)fontRef, kCTFontAttributeName,
                                      style, kCTParagraphStyleAttributeName,
                                      UIColor.whiteColor.CGColor, kCTForegroundColorAttributeName,
                                      nil];
    
    CFRelease(fontRef);
    
    CGSize textSize = [pipe sizeWithAttributes:pipeAttributes];
    
    CGPoint center = CGPointMake(((points[0].x + points[1].x) / 2.0),
                                 ((points[0].y + points[1].y) / 2.0));
    
    CGContextTranslateCTM(context, center.x, center.y);
    CGContextRotateCTM(context, az);
    
    CGRect rect1 = CGRectMake((-textSize.width * 0.55), (textSize.height * 0.4),
                              (textSize.width * 1.1), (textSize.height * 1.1));
    
    rectFits = [self rectWillFit2:rect1
                        inContext:context];
    
    if (rectFits)
    {
        attString = [[NSAttributedString alloc] initWithString:pipe
                                                    attributes:shadowAttributes];
        
        [self drawTextShadowForRect:rect1
                          attString:attString
                            context:context];
        
        CGPathRef path1 = CGPathCreateWithRect(rect1, NULL);

        attString = [[NSAttributedString alloc] initWithString:pipe
                                                    attributes:pipeAttributes];
        
        CTFramesetterRef framesetter1 = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attString);
        CTFrameRef frame1 = CTFramesetterCreateFrame(framesetter1, CFRangeMake(0, 0), path1, NULL);
        CTFrameDraw(frame1, context);
        
        CFRelease(frame1);
        CFRelease(path1);
        CFRelease(framesetter1);
    }
    
    CGContextRestoreGState(context);
    CGContextSaveGState(context);
    
    textSize = [invertOut sizeWithAttributes:invertOutAttributes];
    
    center = CGPointMake(points[1].x, points[1].y);
    
    CGContextTranslateCTM(context, center.x, center.y);
    CGContextRotateCTM(context, az);
    
    CGRect rect2 = CGRectMake((-textSize.width * 1.2), (-textSize.height * 1.5),
                              (textSize.width * 1.1), (textSize.height * 1.1));
    
    rectFits = [self rectWillFit2:rect2
                        inContext:context];
    
    if (rectFits)
    {
        attString = [[NSAttributedString alloc] initWithString:invertOut
                                                    attributes:shadowAttributes];
        
        [self drawTextShadowForRect:rect2
                          attString:attString
                            context:context];
        
        CGPathRef path2 = CGPathCreateWithRect(rect2, NULL);
        
        attString = [[NSAttributedString alloc] initWithString:invertOut
                                                    attributes:invertOutAttributes];
        
        CTFramesetterRef framesetter2 = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attString);
        CTFrameRef frame2 = CTFramesetterCreateFrame(framesetter2, CFRangeMake(0, 0), path2, NULL);
        
        CTFrameDraw(frame2, context);
        CFRelease(frame2);
        CFRelease(path2);
        CFRelease(framesetter2);
    }
    
    CGContextRestoreGState(context);
    CGContextSaveGState(context);
    
    textSize = [invertIn sizeWithAttributes:invertInAttributes];
    
    center = CGPointMake(points[0].x, points[0].y);
    
    CGContextTranslateCTM(context, center.x, center.y);
    CGContextRotateCTM(context, az);
    
    CGRect rect3 = CGRectMake((textSize.width * 0.1), (-textSize.height * 1.5),
                              (textSize.width * 1.1), (textSize.height * 1.1));
    
    rectFits = [self rectWillFit2:rect3
                        inContext:context];
    
    if (rectFits)
    {
        attString = [[NSAttributedString alloc] initWithString:invertIn
                                                    attributes:shadowAttributes];
        
        [self drawTextShadowForRect:rect3
                          attString:attString
                            context:context];
        
        CGPathRef path3 = CGPathCreateWithRect(rect3, NULL);
        
        attString = [[NSAttributedString alloc] initWithString:invertIn
                                                    attributes:invertInAttributes];
        
        CTFramesetterRef framesetter3 = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attString);
        CTFrameRef frame3 = CTFramesetterCreateFrame(framesetter3, CFRangeMake(0, 0), path3, NULL);
        
        CTFrameDraw(frame3, context);
        CFRelease(frame3);
        CFRelease(path3);
        CFRelease(framesetter3);
    }
    
    CGContextRestoreGState(context);
}

- (void)drawTextShadowForRect:(CGRect)rect
                    attString:(NSAttributedString *)attString
                      context:(CGContextRef)context
{
    CGFloat shadowOffset = 2.0;
    
    CGRect shadowRect = CGRectMake((rect.origin.x + shadowOffset), (rect.origin.y + shadowOffset),
                                   rect.size.width, rect.size.height);
    
    CGPathRef shadowPath = CGPathCreateWithRect(shadowRect, NULL);
    
    CTFramesetterRef shadowFramesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attString);
    CTFrameRef shadowFrame = CTFramesetterCreateFrame(shadowFramesetter, CFRangeMake(0, 0), shadowPath, NULL);
    CTFrameDraw(shadowFrame, context);
    
    CFRelease(shadowFrame);
    CFRelease(shadowPath);
    CFRelease(shadowFramesetter);
    
    CGRect shadowRect2 = CGRectMake((rect.origin.x - shadowOffset), (rect.origin.y - shadowOffset),
                                   rect.size.width, rect.size.height);
    
    CGPathRef shadowPath2 = CGPathCreateWithRect(shadowRect2, NULL);
    
    CTFramesetterRef shadowFramesetter2 = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attString);
    CTFrameRef shadowFrame2 = CTFramesetterCreateFrame(shadowFramesetter2, CFRangeMake(0, 0), shadowPath2, NULL);
    CTFrameDraw(shadowFrame2, context);
    
    CFRelease(shadowFrame2);
    CFRelease(shadowPath2);
    CFRelease(shadowFramesetter2);
    
    CGRect shadowRect3 = CGRectMake((rect.origin.x + shadowOffset), (rect.origin.y - shadowOffset),
                                   rect.size.width, rect.size.height);
    
    CGPathRef shadowPath3 = CGPathCreateWithRect(shadowRect3, NULL);
    
    CTFramesetterRef shadowFramesetter3 = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attString);
    CTFrameRef shadowFrame3 = CTFramesetterCreateFrame(shadowFramesetter3, CFRangeMake(0, 0), shadowPath3, NULL);
    CTFrameDraw(shadowFrame3, context);
    
    CFRelease(shadowFrame3);
    CFRelease(shadowPath3);
    CFRelease(shadowFramesetter3);
    
    CGRect shadowRect4 = CGRectMake((rect.origin.x - shadowOffset), (rect.origin.y + shadowOffset),
                                    rect.size.width, rect.size.height);
    
    CGPathRef shadowPath4 = CGPathCreateWithRect(shadowRect4, NULL);
    
    CTFramesetterRef shadowFramesetter4 = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attString);
    CTFrameRef shadowFrame4 = CTFramesetterCreateFrame(shadowFramesetter4, CFRangeMake(0, 0), shadowPath4, NULL);
    CTFrameDraw(shadowFrame4, context);
    
    CFRelease(shadowFrame4);
    CFRelease(shadowPath4);
    CFRelease(shadowFramesetter4);
}

- (void)displayStormPoint:(CGContextRef)context
                llCorners:(CORNERPOINTS *) latlonCornerPoints
                 LLBounds:(MNMXCORD *)platlonBounds
               viewBounds:(MNMXCORD *)pvbounds
{
    NSString *query;
    sqlite3_stmt *statement;
    DPOINT BasePt;
    int numPoints, numLoops;
    LPSTR symName;
    CGFloat size;
    CGColorRef color;
    CGFloat sizeFactor = 1;
    
    if (_zoom > 18)
        sizeFactor *= (2.0 *(_zoom - 18.0));
    
    else if (_zoom < 18)
        sizeFactor /= (2.0 * (18.0 - _zoom));
    
    if (![self continue])
        return;
    
    [self setTrans:latlonCornerPoints viewBounds:pvbounds];
    
    [self open];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_METROGIS:
            query = [NSString stringWithFormat:@"SELECT PointX,PointY,SYMBOLNAME FROM STORM_POINT,STORM_POINT_index WHERE STORM_POINT.id=STORM_POINT_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                     platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
    }
    
    SQLOKswr(sqlite3_prepare_v2(self.database, query.UTF8String, -1, &statement, 0), "prepareDisplayStorm");
    
    while ([self continue] && sqlite3_step(statement) == SQLITE_ROW)
    {
        BasePt.x = sqlite3_column_double(statement,0);
        BasePt.y = sqlite3_column_double(statement,1);
        symName = (LPSTR)sqlite3_column_text(statement,2);
        
        DPOINT llpoint = TranDPOINT(&BasePt, _pTranLLtoView);
        
        if (!strcasecmp(symName, "STRM_MHOL"))
        {
            color = _darkGreen.CGColor;
            size = 20.0;
        }
        else
        {
            color = UIColor.greenColor.CGColor;
            size = 8.0;
        }
        
        [self drawStormPoint:context
                    atPoint:&llpoint
                  withColor:color
                    andSize:(size * sizeFactor)];
    }
    
    SQLOKswr(sqlite3_finalize(statement), "displayParcels");
    [self close];
}

- (void)drawStormPoint:(CGContextRef)context
               atPoint:(DPOINT *)pPoint
             withColor:(CGColorRef)color
               andSize:(CGFloat)size

{
    CGRect pointRect = CGRectMake((pPoint->x - size / 2.0),
                                  (pPoint->y - size / 2.0), size, size);
    
    //CGContextSetStrokeColorWithColor(context,color);
    CGContextSetFillColorWithColor(context,color);
    CGContextFillEllipseInRect(context, pointRect);
    //CGContextStrokeEllipseInRect(context, pointRect);
    //CGContextFillPath(context);
}

- (BOOL)rectWillFit:(CGRect)rect
          inContext:(CGContextRef)context
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    int minX = roundIntToNearestTen((int)(CGRectGetMinX(rect)));
    int maxX = roundIntToNearestTen((int)(CGRectGetMaxX(rect)));
    int minY = roundIntToNearestTen((int)(CGRectGetMinY(rect)));
    int maxY = roundIntToNearestTen((int)(CGRectGetMaxY(rect)));
    
    for (int i = minX; i <= maxX; i += 10)
    {
        for (int j = minY; j <= maxY; j+= 10)
             {
                 CGPoint point = CGContextConvertPointToDeviceSpace(context, CGPointMake(i, j));
                 point.x = roundFloatToNearestTen(point.x);
                 point.y = roundFloatToNearestTen(point.y);
                 NSValue *roundedPoint = [NSValue valueWithCGPoint:point];
                 
                 if ([_pointsArray containsObject:roundedPoint])
                     return NO;
                 
                 [array addObject:roundedPoint];
             }
    }
    
    [_pointsArray addObjectsFromArray:array];
    return YES;
}

int roundIntToNearestTen(int x)
{
    return ((x + 5) / 10) * 10;
}

float roundFloatToNearestTen(float x)
{
    int y = round(x);
    return roundIntToNearestTen(y);
}

- (BOOL)rectWillFit2:(CGRect)rect
           inContext:(CGContextRef)context
{
    int minX = CGRectGetMinX(rect);
    int maxX = CGRectGetMaxX(rect);
    int minY = CGRectGetMinY(rect);
    int maxY = CGRectGetMaxY(rect);
    
    for (int i = minX; i < maxX; i++)
    {
        for (int j = minY; j < maxY; j++)
        {
            CGPoint point = CGContextConvertPointToDeviceSpace(context, CGPointMake(i, j));
            int x = point.x;
            int y = point.y;
            
            if (point.x >= 0 && point.x < _textOverlapBufferSizeWidth &&
                point.y >= 0 && point.y < _textOverlapBufferSizeHeight)
            {
                if (_textOverlapBuffer[y * _textOverlapBufferSizeWidth + x])
                    return NO;
            }
        }
    }
    
    for (int i = minX; i < maxX; i++)
    {
        for (int j = minY; j < maxY; j++)
        {
            CGPoint point = CGContextConvertPointToDeviceSpace(context, CGPointMake(i, j));
            int x = point.x;
            int y = point.y;
            
            if (point.x >= 0 && point.x < _textOverlapBufferSizeWidth &&
                point.y >= 0 && point.y < _textOverlapBufferSizeHeight)
            {
                _textOverlapBuffer[y * _textOverlapBufferSizeWidth + x] = 1;
            }
        }
    }
    
    return YES;
}

@end