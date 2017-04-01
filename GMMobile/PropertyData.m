NSString *fileName = @"MetroGIS_database.gcf";
//  PropertyData.m
//  GMMobile
#import "PropertyData.h"
#import "BoundaryData.h"
#import "ConfigurationControl.h"
#import "NVMetroSettings.h"
#import "MapViewENUMS.h"
#import "CCodeLibrary/NVTextDrawing.h"
#import "CCodeLibrary/MathUtil.h"
MNMXCORD curbounds;

typedef struct { int EMV_LAND, EMV_BLDG, EMV_TOTAL, TAX_CAPACITY, TOTAL_TAX, SPEC_ASSES, SALE_YEAR, SALE_VALUE;
}YEARLYVALUES;
typedef YEARLYVALUES *LPYEARLYVALUES;
LPYEARLYVALUES pYearly;

@interface NSString (NSNumber)
- (BOOL) isNumberWithLocale:(NSLocale *) stringLocale;
- (BOOL) isNumber;
- (NSNumber *) getNumber;
- (NSNumber *) getNumberWithLocale:(NSLocale*) stringLocale;
@end

int SQLOKpd(int sqlReturn, sqlite3 *database, int method)
{
    return SQLOK (1000,sqlReturn,database);
}
@implementation NSString (NSNumber)
- (BOOL) isNumberWithLocale:(NSLocale *) stringLocale
{
    return [self getNumberWithLocale:stringLocale] != nil;
}
- (BOOL) isNumber
{
    return [ self getNumber ] != nil;
}
- (NSNumber *) getNumber
{
    NSLocale *l_en = [[NSLocale alloc] initWithLocaleIdentifier: @"en_US"] ;
    return [self getNumberWithLocale:l_en];
}

- (NSNumber *) getNumberWithLocale:(NSLocale*) stringLocale
{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc ] init];
    [formatter setLocale: stringLocale ];
    return [ formatter numberFromString:self ];
}
@end
#define COORDINATE_FACTOR 10000000.0

@implementation PropertyRecord

+ (instancetype)propertyRecordWithPin:(NSString *)pin
                            propOwner:(NSString *)propOwner
                           coordinate:(CLLocationCoordinate2D)coordinate
{
    PropertyRecord *propRec = PropertyRecord.new;
    propRec.pin = pin;
    propRec.propOwner = propOwner;
    propRec.coordinate = coordinate;
    return propRec;
}

@end

@implementation PropertyHistory

@end

@implementation PropertyDataExtract

@end

@interface PropertyData ()

@property (nonatomic) GSSiPopoverView *popover;

@end

@implementation PropertyData


- (BOOL)continue
{
    if (!self.processingID)
        return YES;
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
        _fileName = @"PropertyData.slt";
        _cenfileName = @"censusdata.slt";
        _path = [NSString stringWithFormat:@"%@/%@", _documentsDirectory, _fileName];
        _cenpath = [NSString stringWithFormat:@"%@/%@", _documentsDirectory, _cenfileName];
        _multiValueFile = [NSString stringWithFormat:@"%@/changevalues.bin", _documentsDirectory];
        
    }
    return self;
}

- (void)dealloc
{
    CloseTRANS2 (&_pTranLLtoView);
    CloseTRANS2 (&_pTranViewtoLL);
    sqlite3_close(_database);
    //NSLog(@"Property Database dealloc");
}
- (BOOL)open
{
    if (!_isOpen)
    {
        self.isOpen = YES;
        self.isOpen = !SQLOKpd(sqlite3_open(_path.UTF8String, &_database), _database, 1);
        
        //NSLog(@"Property Database open");
        
        _fileSize = [NSFileManager.defaultManager attributesOfItemAtPath:_cenpath
                     error:nil].fileSize;
        if (self.isOpen)
        {
            [self propVersion];
            NSString *attachCmd = [NSString stringWithFormat:@"ATTACH DATABASE '%@' AS CENSUSDB",self.cenpath];
            [self executeCmd:(LPSTR)attachCmd.UTF8String];
        }
        _fileSize = [NSFileManager.defaultManager attributesOfItemAtPath:_path
                                                                   error:nil].fileSize;
        return TRUE;
    }
    else
        return FALSE;
}

- (void)close:(BOOL)opened
{
    if (opened)
    {
        SQLOKpd(sqlite3_close(_database), _database, 0);
        //NSLog(@"Property Database close");
        _isOpen = NO;
    }
}

- (void)clear
{
    [self close:YES];
    
    //BOOL st = [NSFileManager.defaultManager removeItemAtPath:_path
    //error:nil];
}

- (BOOL)executeCmd:(char *)cmd
{
    BOOL rtn = !SQLOKpd(sqlite3_exec(_database, cmd, 0, 0, 0),_database, 3);
    return rtn;
}

- (void)startTransaction
{
    [self open];
    SQLOKpd(sqlite3_exec(_database, "BEGIN", 0, 0, 0), _database, 4);
}

- (void)commitTransaction
{
    SQLOKpd(sqlite3_exec(_database, "COMMIT", 0, 0, 0),_database, 5);
}

- (NSString *) propVersion
{
    _version = @"-1";
    NSString *query = [NSString stringWithFormat:@"SELECT VersionNum FROM VERSION"];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database, 6);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR ver = (LPSTR)sqlite3_column_text(statement, 0);
        _version = [NSString stringWithUTF8String:ver];
    }
    
    SQLOKpd(sqlite3_finalize(statement), _database, 7);
    return _version;
}

- (int)parcelDatasetVersion
{
    BOOL opened = [self open];
    
    [self close:opened];
    return atoi (_version.UTF8String);
}

- (int) censusDatasetVersion
{
    int rtn = -1;
    BOOL opened = [self open];
    
    if (_isOpen && _fileSize > 0)
    {
        //NSString *query = [NSString stringWithFormat:@"SELECT VersionNumber FROM VERSION"];
        NSString *query = [NSString stringWithFormat:@"SELECT VersionNum FROM CENSUSDB.VERSION"];
        
        sqlite3_stmt *statement = NULL;
        
        int st = SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database, 12);
        
        if (sqlite3_step(statement) == SQLITE_ROW)
        {
            LPSTR version  = (LPSTR)sqlite3_column_text(statement, 0);
            rtn = atoi (version);
        }
        
        SQLOKpd(sqlite3_finalize(statement), _database, 13);
    }
    
    [self close:opened];
    return rtn;
}

- (int) planDatasetVersion
{
    int rtn = -1;
    BOOL opened = [self open];
    
    if (_isOpen && _fileSize > 0)
    {
        NSString *query = [NSString stringWithFormat:@"SELECT max(id) FROM PLAN_LINE"];
        
        sqlite3_stmt *statement = NULL;
        
        SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database, 14);
        
        if (sqlite3_step(statement) == SQLITE_ROW)
        {
            int maxID = sqlite3_column_int(statement, 0);
            if (maxID > 0)
                rtn = 0;
        }
        
        SQLOKpd(sqlite3_finalize(statement), _database, 15);
    }
    
    [self close:opened];
    return rtn;
}

- (BOOL)getDistinctUseCodes:(NSString *)outFile
{
    BOOL rtn = NO;
    sqlite3_stmt *statement = NULL;
    NSString *query = @"";
    NSString *outString = @"Distinct Use Codes";
    
    BOOL opened = [self open];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_METROGIS:
            query = @"SELECT DISTINCT XUSE1_DESC FROM PROPINFO";
            break;
    }
    
    SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database, 16);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR useCode = (LPSTR)sqlite3_column_text(statement, 0);
        outString = [outString stringByAppendingString:[NSString stringWithFormat:@"\r\n%s", useCode]];
    }
    
    SQLOKpd(sqlite3_finalize(statement), _database, 17);
    
    [self close:opened];
    
    rtn = [outString writeToFile:outFile
                      atomically:YES
                        encoding:NSUTF8StringEncoding
                           error:nil];
    
    return rtn;
}

- (LLPOINT)getPointForPID:(NSString *)PID
{
    LLPOINT pt = {0};
    sqlite3_stmt *statement = NULL;
    NSString *query = @"";
    
    BOOL opened = [self open];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_MPLS:
            query = [NSString stringWithFormat:@"SELECT LAT,LON FROM PARCELPOINT Where PID = '%@'",
                     PID];
            break;
            
        case PROJECT_METROGIS:
            query = [NSString stringWithFormat:@"SELECT LATITUDE,LONGITUDE FROM PROPINFO Where PIN = '%@'",
                     PID];
            break;
    }
    
    SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database, 18);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        pt.lat = sqlite3_column_double(statement, 0);
        pt.lon = sqlite3_column_double(statement, 1);
    }
    
    SQLOKpd(sqlite3_finalize(statement), _database, 19);
    
    [self close:opened];
    return pt;
}

- (MNMXCORD)getBoundsForPID:(NSString *)PID
{
    MNMXCORD bounds = {0};
    sqlite3_stmt *statement = NULL;
    NSString *query = @"";
    
    BOOL opened = [self open];
    
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
    
    SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database, 20);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        bounds.xmn = sqlite3_column_double(statement, 1);
        bounds.xmx = sqlite3_column_double(statement, 2);
        bounds.ymn = sqlite3_column_double(statement, 3);
        bounds.ymx = sqlite3_column_double(statement, 4);
    }
    
    SQLOKpd(sqlite3_finalize(statement), _database, 21);
    
    [self close:opened];
    return bounds;
}

- (NSMutableArray *)getPIDsMatchingString:(NSString *)matchChar
{
    NSMutableArray *array = NSMutableArray.array;
    
    BOOL opened = [self open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT PIN FROM PROPINFO Where PIN LIKE '%@%%'",
                       matchChar];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database, 28);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR cpid = (LPSTR)sqlite3_column_text(statement, 0);
        NSString *pid = [NSString stringWithFormat:@"%s", cpid];
        [array addObject:pid];
    }
    
    SQLOKpd(sqlite3_finalize(statement), _database, 29);
    
    [self close:opened];
    return array;
}

- (NSMutableArray *)getPIDsWithOwnerMatchingString:(NSString *)matchChar
                                           limitOf:(int)lim
{
    NSMutableArray *array = NSMutableArray.array;
    int n = 0;
    
    BOOL opened = [self open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT PIN,\"Owner_Name\" FROM PROPINFO Where PIN >= '%@'",
                       matchChar];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0),_database, 30);
    
    while (n++ < lim && sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR cpid = (LPSTR)sqlite3_column_text(statement, 0);
        
        if (strncasecmp(cpid, matchChar.UTF8String, matchChar.length))
            break;
        
        LPSTR owner = (LPSTR)sqlite3_column_text(statement, 1);
        NSString *pid = [NSString stringWithFormat:@"%s\t%s", cpid, owner];
        [array addObject:pid];
    }
    
    SQLOKpd(sqlite3_finalize(statement), _database, 31);
    
    [self close:opened];
    return array;
}

- (NSMutableArray *)getPIDsMatchingAddress:(int)houseNumber
                                streetName:(NSString *)matchChar
{
    NSMutableArray *array = NSMutableArray.array;
    NSString *query = @"";
    NSString *lastName = [NSString stringWithFormat:@"%@%@", matchChar, @"Z"];
    BOOL opened = [self open];
    //NSString *query = [NSString stringWithFormat:@"SELECT HOUSE_NUM,STREET_NAME,UDIValue,AdditionalValue FROM ADDLOC4 Where STREET_NAME LIKE '%@%%' AND HOUSE_NUM = %i",matchChar,houseNumber];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_MPLS:
            query = [NSString stringWithFormat:@"SELECT HOUSENUM,STREET,PID,\"Owner Name\" FROM PROPINFO Where STREET LIKE '%@%%' AND HOUSENUM = %i",
                     matchChar,houseNumber];
            break;
            
        case PROJECT_METROGIS:
            query = [NSString stringWithFormat:@"SELECT BLDG_NUM,STREETNAME,PIN,\"Owner_Name\" FROM PROPINFO Where STREETNAME >= '%@' AND STREETNAME < '%@' AND BLDG_NUM = %i",
                     matchChar.uppercaseString, lastName.uppercaseString, houseNumber];
            break;
    }
    
    sqlite3_stmt *statement = NULL;
    
    SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement,0), _database, 32);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        int house = sqlite3_column_int(statement, 0);
        LPSTR street = (LPSTR)sqlite3_column_text(statement, 1);
        LPSTR pid = (LPSTR)sqlite3_column_text(statement, 2);
        LPSTR additionalVal = (LPSTR)sqlite3_column_text(statement, 3);
        
        NSString *output = [NSString stringWithFormat:@"%i\t%s\t%s\t%s",
                            house, street, pid, additionalVal];
        
        [array addObject:output];
    }
    
    SQLOKpd(sqlite3_finalize(statement), _database, 33);
    
    [self close:opened];
    return array;
}

- (int)pickPID:(LLPOINT *)pt
 useVisibility:(BOOL)useVis
 highlightList:(NSMutableArray*)hlist
{
    if (useVis && ![ConfigurationControl.sharedInstance layer:HCLayerParcels
                                      visibleAtZoom:_zoom
                                            andPass:PickPass])
        return 0;
    
    NSString *minPID = @"";
    CGFloat d, mind = DBL_MAX;
    DPOINT p1, p2, minpt;
    int minref = 0;
    int npicked = 0;
    
    p1.x = pt->lon;
    p1.y = pt->lat;
    minpt = p1;
    dbounds bnds = [CRAPI.sharedInstance getPickApBoundsAtPoint:pt];
    BOOL opened = [self open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT PROPINFO.id, PIN, LATITUDE, LONGITUDE FROM PROPINFO,PROPINFO_index WHERE PROPINFO.id=PROPINFO_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                       bnds.xmn, bnds.xmx, bnds.ymn, bnds.ymx];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database, 34);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        int refno = sqlite3_column_int(statement, 0);
        LPSTR cpid = (LPSTR)sqlite3_column_text(statement, 1);
        CGFloat lat = sqlite3_column_double(statement, 2);
        CGFloat lon = sqlite3_column_double(statement, 3);
        p2.x = lon;
        p2.y = lat;
        d = ArcDistance(p1, p2);
        
        if (d < mind)
        {
            npicked++;
            minref = refno;
            mind = d;
            minpt = p2;
            minPID = [NSString stringWithUTF8String:cpid];
        }
    }
    
    SQLOKpd(sqlite3_finalize(statement), _database, 35);
    [self close:opened];
    pt->lon = minpt.x;
    pt->lat = minpt.y;
    if (npicked)
    {
        PickedItem *pi = [[PickedItem alloc]init];
        pi.itemType = ParcelBoundary;
        pi.distance = mind;
        pi.pickedPoint = minpt;
        pi.identifier = minPID;
        pi.symbolName = @"PARCEL";
        pi.refno = minref;
        [hlist addObject:pi];
    }
    return npicked;
}
- (NSString*)getNearestPID:(CLLocationCoordinate2D*)pt
{
    NSString *minPID = @"";
    CGFloat d, mind = DBL_MAX;
    DPOINT p1, p2, minpt;
    int npicked = 0;
    
    p1.x = pt->longitude;
    p1.y = pt->latitude;
    minpt = p1;
    dbounds bnds = [CRAPI.sharedInstance getBoundsAtPoint:pt andDist:500];
    BOOL opened = [self open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT PIN, LATITUDE, LONGITUDE FROM PROPINFO,PROPINFO_index WHERE PROPINFO.id=PROPINFO_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                       bnds.xmn, bnds.xmx, bnds.ymn, bnds.ymx];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database, 36);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR cpid = (LPSTR)sqlite3_column_text(statement, 0);
        CGFloat lat = sqlite3_column_double(statement, 1);
        CGFloat lon = sqlite3_column_double(statement, 2);
        p2.x = lon;
        p2.y = lat;
        d = ArcDistance(p1, p2);
        
        if (d < mind)
        {
            npicked++;
            mind = d;
            minpt = p2;
            minPID = [NSString stringWithUTF8String:cpid];
        }
    }
    
    SQLOKpd(sqlite3_finalize(statement), _database, 37);
    [self close:opened];
    pt->longitude = minpt.x;
    pt->latitude = minpt.y;
    if (npicked)
    {
        return minPID;
    }
    return nil;
}

+ (NSString *)getCensusBlockForPID:(NSString *)PID
{
    NSString *block = @"";
    PropertyData *pd = [[PropertyData alloc]init];
    BOOL opened = [pd open];
    NSString *query = [NSString stringWithFormat:@"SELECT [CENBLOCK] FROM PROPINFO Where PIN = '%@'",
                       PID];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOKpd(sqlite3_prepare_v2(pd.database, query.UTF8String, -1, &statement, 0), pd.database, 38);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR cblock = (LPSTR)sqlite3_column_text(statement, 0);
        block = [NSString stringWithUTF8String:cblock];
    }
    
    SQLOKpd(sqlite3_finalize(statement), pd.database, 39);
    [pd close:opened];
    
    return block;
}


- (NSString *)getOwnerNameForPID:(NSString *)PID
{
    NSString *ownerName = @"";
    
    BOOL opened = [self open];
    NSString *query = [NSString stringWithFormat:@"SELECT [Owner_Name] FROM PROPINFO Where PIN = '%@'",
                       PID];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database, 38);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR owner = (LPSTR)sqlite3_column_text(statement, 0);
        ownerName = [NSString stringWithUTF8String:owner];
    }
    
    SQLOKpd(sqlite3_finalize(statement), _database, 39);
    [self close:opened];
    return ownerName;
}
- (NSString *) noNullString:(LPSTR)str
{
    NSString * rtn = @"";
    if (str)
        rtn = [NSString stringWithUTF8String:str];
    return rtn;
}
- (BOOL)getAddressForPID:(NSString *)PID
         houseNumAndUnit:(NSString **)houseAndUnit
              streetName:(NSString **)streetName
                    city:(NSString **)city
             ownerName:(NSString **)owner
             taxpayerName:(NSString **)taxpayer
             censusBlock:(NSString **)cenblock
                 useDesc:(NSString **)usedesc
                  totEMV:(double *)totEMV
                  landEMV:(double *)landEMV
                 bldgEMV:(double *)bldgEMV
                  totTAX:(double *)totTax
                 specAss:(double *)specAss
                  acres:(double *)acres
{
    BOOL rtn = FALSE;
    *houseAndUnit = @"";
    *streetName = @"";
    if (city)
        *city = @"";
    if (cenblock)
        *cenblock = @"";
    if (usedesc)
        *usedesc = @"";
    if (totEMV)
        *totEMV = 0;
    BOOL opened = [self open];
    NSString *query = [NSString stringWithFormat:@"SELECT [BLDG_NUM],[STREETNAME],[UNIT_INFO],[CITY],[CENBLOCK],[USE1_DESC],[EMV_TOTAL],[OWNER_NAME],[OWNER_MORE],[TAX_NAME],[EMV_LAND],[EMV_BLDG],[TOTAL_TAX],[SPEC_ASSES],[ACRES_POLY]  FROM PROPINFO Where PIN = '%@'",
                       PID];
    sqlite3_stmt *statement = NULL;
    
    SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0),_database, 40);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        int i=0;
        LPSTR bldgnum = (LPSTR)sqlite3_column_text(statement, i++);
        LPSTR street = (LPSTR)sqlite3_column_text(statement, i++);
        LPSTR unit = (LPSTR)sqlite3_column_text(statement, i++);
        LPSTR cityc = (LPSTR)sqlite3_column_text(statement, i++);
        LPSTR cenblockc = (LPSTR)sqlite3_column_text(statement, i++);
        LPSTR usedescc = (LPSTR)sqlite3_column_text(statement, i++);
        double emvtot = sqlite3_column_double(statement, i++);
        LPSTR ownerName = (LPSTR)sqlite3_column_text(statement, i++);
        LPSTR ownerMore = (LPSTR)sqlite3_column_text(statement, i++);
        LPSTR taxpayr = (LPSTR)sqlite3_column_text(statement, i++);
        double emvLand = sqlite3_column_double(statement, i++);
        double emvBldg = sqlite3_column_double(statement, i++);
        double totTx = sqlite3_column_double(statement, i++);
        double specAssmt = sqlite3_column_double(statement, i++);
        double acresp = sqlite3_column_double(statement, i++);
        *houseAndUnit = [NSString stringWithFormat:@"%s%s",bldgnum,unit];
        *streetName = [NSString stringWithUTF8String:street];
        if (city)
            *city = [self noNullString:cityc];
        if (cenblock)
            *cenblock = [self noNullString:cenblockc];
        if (usedesc)
            *usedesc = [self noNullString:usedescc];
        if (owner)
        {
            *owner = [self noNullString:ownerName];
            if (strlen (ownerMore)>0)
                *owner = [*owner stringByAppendingFormat:@"\\n%s",ownerMore];
        }
        if (taxpayer)
            *taxpayer = [self noNullString:taxpayr];
        if (usedesc)
            *usedesc = [self noNullString:usedescc];
        if (totEMV)
            *totEMV = emvtot;
        if (landEMV)
            *landEMV = emvLand;
        if (bldgEMV)
            *bldgEMV = emvBldg;
        if (totTax)
            *totTax = totTx;
        if (specAss)
            *specAss = specAssmt;
        if (acres)
            *acres = acresp;
        rtn = TRUE;
    }
    
    SQLOKpd(sqlite3_finalize(statement), _database, 41);
    [self close:opened];
    return rtn;
}

- (void)GSSiPopoverViewdidCancel:(GSSiPopoverView *)popoverView
{
    [_popover hide];
}

- (BOOL)loadParcelPolygons:(NSString *)fromPath
{
    BOOL rtn = NO;
    
    BOOL opened = [self open];
    
    NSString *cmd = @"CREATE VIRTUAL TABLE demo_index USING rtree(id,minX,maxX,minY,maxY);";
    
    [self executeCmd:(char *)cmd.UTF8String];
    [self close:opened];
    return rtn;
}

- (void)fillParcel:(CGContextRef)context
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

- (void)drawParcel:(CGContextRef)context
           nPoints:(int)np
            nLoops:(int)nLoops
           partLen:(int *)pPartLen
            points:(LPDPOINT)pPoints
         withColor:(CGColorRef)color
          andWidth:(int)width;
{
    
    CGContextSetLineWidth(context, width);
    //CGContextFillEllipseInRect(context, pointRect);
    //CGContextStrokeEllipseInRect(context, pointRect);
    //CGContextFillPath(context);
    
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
-(void) datadef
{
    /*
     CREATE TABLE PROPINFO ('id' INT,'PIN' CHAR(17),'BLDG_NUM' CHAR(10),'STREETNAME' CHAR(60),'UNIT_INFO' CHAR(12),'CITY' CHAR(30),'CITY_USPS' CHAR(30),'ZIP' CHAR(5),'ZIP4' CHAR(4),'PLAT_NAME' CHAR(50),'BLOCK' CHAR(5),'LOT' CHAR(5),'ACRES_POLY' REAL,'ACRES_DEED' REAL,'USE1_DESC' CHAR(100),'USE2_DESC' CHAR(100),'USE3_DESC' CHAR(100),'USE4_DESC' CHAR(100),'MULTI_USES' CHAR(1),'LANDMARK' CHAR(100),'OWNER_NAME' CHAR(50),'OWNER_MORE' CHAR(50),'OWN_ADD_L1' CHAR(40),'OWN_ADD_L2' CHAR(40),'OWN_ADD_L3' CHAR(40),'TAX_NAME' CHAR(40),'TAX_ADD_L1' CHAR(40),'TAX_ADD_L2' CHAR(40),'TAX_ADD_L3' CHAR(40),'HOMESTEAD' CHAR(1),'EMV_LAND' REAL,'EMV_BLDG' REAL,'EMV_TOTAL' REAL,'TAX_CAPAC' REAL,'TOTAL_TAX' REAL,'SPEC_ASSES' REAL,'TAX_EXEMPT' CHAR(1),'XUSE1_DESC' CHAR(100),'XUSE2_DESC' CHAR(100),'XUSE3_DESC' CHAR(100),'XUSE4_DESC' CHAR(100),'DWELL_TYPE' CHAR(30),'HOME_STYLE' CHAR(30),'FIN_SQ_FT' REAL,'GARAGE' CHAR(1),'GARAGESQFT' CHAR(11),'BASEMENT' CHAR(1),'HEATING' CHAR(30),'COOLING' CHAR(30),'YEAR_BUILT' CHAR(5),'NUM_UNITS' CHAR(6),'SALE_DATE' CHAR(8),'SALE_VALUE' REAL,'SCHOOL_DST' CHAR(6),'WSHD_DIST' CHAR(50),'GREEN_ACRE' CHAR(1),'OPEN_SPACE' CHAR(1),'AG_PRESERV' CHAR(1),'AGPRE_ENRD' CHAR(8),'AGPRE_EXPD' CHAR(8),'PARC_CODE' CHAR(5),'CENBLOCK' CHAR(15),'LONGITUDE' REAL,'LATITUDE' REAL,PRIMARY KEY('id' ASC))
     */
}
- (int)pickParcel:(LLPOINT *)pt
    highlightList:(NSMutableArray*)hlist
{
    if (ConfigurationControl.sharedInstance.currentApp == HCConfigMetroProp)
    {
        switch (NVMetroSettings.sharedInstance.currentFeature)
        {
            case CPFParcels:
            case CPFParcels_IND:
            case CPFParcels_AG:
            case CPFParcels_RES:
            case CPFParcels_COM:
                break;
            default:
                return 0;
        }
    }
    else if (![ConfigurationControl.sharedInstance layer:HCLayerParcels
                                           visibleAtZoom:_zoom
                                                 andPass:PickPass])
        return 0;
    
    NSString *minPID = [[NSString alloc] init];
    CGFloat d, mind = DBL_MAX;
    DPOINT p1, p2, minpt;
    int minref = 0;
    int refno;
    int npicked = 0;
    int minLinks = 0;
    int nLinks;
    DPOINT BasePt;
    LPSTR pid;
    int numPoints, numLoops;
    
    p1.x = pt->lon;
    p1.y = pt->lat;
    minpt = p1;
    dbounds bnds = [CRAPI.sharedInstance getPickApBoundsAtPoint:pt];
    BOOL opened = [self open];
    
    /*    NSString *query = [NSString stringWithFormat:@"SELECT PROPINFO.id, PIN, LATITUDE, LONGITUDE FROM PROPINFO,PROPINFO_index WHERE PROPINFO.id=PROPINFO_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
     bnds.xmn, bnds.xmx, bnds.ymn, bnds.ymx];*/
    NSString *query = [NSString stringWithFormat:@"SELECT PID,BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,PARCELPOLY.id, NUMLINKEDPARCELS FROM PARCELPOLY,PROPINFO,PARCELPOLY_index WHERE PROPINFO.PIN = PARCELPOLY.PID AND PARCELPOLY.id=PARCELPOLY_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                       bnds.xmn, bnds.xmx, bnds.ymn, bnds.ymx];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database, 34);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        pid = (LPSTR)sqlite3_column_text(statement, 0);
        BasePt.x = sqlite3_column_double(statement,1);
        BasePt.y = sqlite3_column_double(statement,2);
        numPoints = sqlite3_column_int(statement,3);
        numLoops = sqlite3_column_int(statement,4);
        int *polyPartLen = (int *)sqlite3_column_blob(statement,5);
        LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement,6);
        refno = sqlite3_column_int(statement,7);
        nLinks = sqlite3_column_int(statement,8);
        
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
        if (POINT_IN_AREAD(p1, numPoints, llpoints, 1, 0, 0, 0))
        {
            npicked++;
            minref = refno;
            mind = 0;
            minpt = p1;
            minPID = [NSString stringWithUTF8String:pid];
            minLinks = nLinks;
        }
        free (llpoints);
        if (npicked)
            break;
    }
    
    SQLOKpd(sqlite3_finalize(statement), _database, 35);
    [self close:opened];
    pt->lon = minpt.x;
    pt->lat = minpt.y;
    if (npicked)
    {
        PickedItem *pi = [[PickedItem alloc]init];
        pi.itemType = ParcelBoundary;
        pi.distance = mind;
        pi.pickedPoint = minpt;
        pi.identifier = minPID;
        pi.symbolName = @"PARCEL";
        pi.refno = minref;
        pi.nLinks = minLinks;
        [hlist addObject:pi];
    }
    return npicked;
}

- (double) getTargetPidValue
{
    double value = -1;
    sqlite3_stmt *statement = NULL;
    
    if (CRAPI.sharedInstance.parcelColorOption)
    {
        NSString *query = [NSString stringWithFormat:@"SELECT ACRES_POLY,USE1_DESC,EMV_LAND,EMV_BLDG,EMV_TOTAL,TOTAL_TAX,CENBLOCK FROM PROPINFO WHERE PROPINFO.PIN='%s'", CRAPI.sharedInstance.selectedPID.UTF8String];
        SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database, 42);
        if (sqlite3_step(statement) == SQLITE_ROW)
        {
            double acres = sqlite3_column_double(statement,0);
            LPSTR useDesc = (LPSTR)sqlite3_column_text(statement, 1);
            double landEMV = sqlite3_column_double(statement,2);
            double bldgEMV = sqlite3_column_double(statement,3);
            double totEMV = sqlite3_column_double(statement,4);
            double totTax = sqlite3_column_double(statement,5);
            LPSTR cenBlock = (LPSTR)sqlite3_column_text(statement, 6);
            int opt = CRAPI.sharedInstance.parcelShadingOption;
            
            switch (CRAPI.sharedInstance.parcelColorOption)
            {
                case ParcelColorSettingTotEMV:
                    value = totEMV;
                    break;
                    
                case ParcelColorSettingLandEMV:
                    value = landEMV;
                    break;
                    
                case ParcelColorSettingLandEMVPerAcre:
                    if (acres > 0)
                        value = landEMV / acres;
                    break;
                    
                case ParcelColorSettingBuildingEMV:
                    value = bldgEMV;
                    break;
            }
            SQLOKpd(sqlite3_finalize(statement), _database, 43);
        }
    }

    return value;
}
- (void)displayParcels:(CGContextRef)context
             llCorners:(CORNERPOINTS *) latlonCornerPoints
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds
                themes:(Themes*)themes
{
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    
    _pTranLLtoView = STRANCornersToBounds(latlonCornerPoints, pvbounds);
    
    UIColor *parcelLineColor = [UIColor colorWithRed:0.5 green:0 blue:0 alpha:1];
    int parcelLineWidth = 3;
    NSString *query = @"";
    sqlite3_stmt *statement = NULL;
    //LPSTR pid;
    DPOINT BasePt;
    int numPoints, numLoops;
    //int refno;
    int numlinked;
    CGFloat emvTotal, emvLand, emvBldg, acres, saleval;
    CGFloat valuePerAcre;
    CGFloat specAssmt;
    LPSTR homeStead, useCode, taxExempt, owner, saledate;
    //LPSTR useDesc;
    char homeSteadCode = 'H';
    char taxExemptCode = 'E';
    BOOL opened = [self open];
    
    double targetPidValue = [self getTargetPidValue];
    
    if (ConfigurationControl.sharedInstance.GMTilesVisible)
        parcelLineColor = [UIColor colorWithRed:1 green:1 blue:0 alpha:1];
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_MPLS:
            query = [NSString stringWithFormat:@"SELECT PROPINFO.PID,BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,PARCELPOLY.id,HOMESTEAD,USECODE,USE_DESC,TAX_EXEMPT,TOTAL_VALUE FROM PARCELPOLY,PARCELPOLY_index, PROPINFO WHERE PARCELPOLY.id=PARCELPOLY_index.id AND PROPINFO.PID=PARCELPOLY.PID AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                     platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
            break;
            
        case PROJECT_METROGIS:
            homeSteadCode = 'Y';
            taxExemptCode = 'Y';
            query = [NSString stringWithFormat:@"SELECT PID,BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,PARCELPOLY.id,HOMESTEAD,USE1_DESC,USE2_DESC,TAX_EXEMPT,EMV_TOTAL,EMV_LAND,EMV_BLDG,ACRES_POLY,SPEC_ASSES,OWNER_NAME,SALE_DATE,SALE_VALUE,NUMLINKEDPARCELS  FROM PARCELPOLY,PARCELPOLY_index,PROPINFO WHERE PARCELPOLY.id=PARCELPOLY_index.id AND PROPINFO.PIN=PARCELPOLY.PID AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                     platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
    }
    
    SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database, 42);
    NSLog (@"Prepared");
    
    while ([self continue] && sqlite3_step(statement) == SQLITE_ROW)
    {
        //refno = sqlite3_column_int(statement,7);
        homeStead = (LPSTR)sqlite3_column_text(statement, 8);
        useCode = (LPSTR)sqlite3_column_text(statement, 9);
        //useDesc = (LPSTR)sqlite3_column_text(statement, 10);
        taxExempt = (LPSTR)sqlite3_column_text(statement, 11);
        emvTotal = (CGFloat)sqlite3_column_double(statement, 12);
        emvLand = (CGFloat)sqlite3_column_double(statement, 13);
        emvBldg = (CGFloat)sqlite3_column_double(statement, 14);
        acres = (CGFloat)sqlite3_column_double(statement, 15);
        specAssmt = (CGFloat)sqlite3_column_double(statement, 16);
        owner = (LPSTR)sqlite3_column_text(statement, 17);
        saledate = (LPSTR)sqlite3_column_text(statement, 18);
        saleval = (CGFloat)sqlite3_column_double(statement, 19);
        numlinked = (CGFloat)sqlite3_column_int(statement, 20);
        //pid = (LPSTR)sqlite3_column_text(statement, 0);
        BasePt.x = sqlite3_column_double(statement,1);
        BasePt.y = sqlite3_column_double(statement,2);
        numPoints = sqlite3_column_int(statement,3);
        numLoops = sqlite3_column_int(statement,4);
        int *polyPartLen = (int *)sqlite3_column_blob(statement,5);
        //int nBlobBytes = sqlite3_column_bytes(statement,5);
        LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement,6);
        //nBlobBytes = sqlite3_column_bytes(statement,6);
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
        
        if (CRAPI.sharedInstance.parcelShadingOption)
        {
            CGFloat alpha = 0;
            UIColor *color;
            int opt = CRAPI.sharedInstance.parcelShadingOption;
            
            switch (opt)
            {
                case 1://homestead
                    if (*homeStead == homeSteadCode)
                        alpha = 0.6;
                    
                    color = [[UIColor alloc]initWithRed:1.0
                                                  green:1.0
                                                   blue:0.0
                                                  alpha:alpha];
                    break;
                    
                case 2://res-com
                    color = [self resComColor:useCode];
                    break;
                    
                case 3://Special Assessment
                    if (specAssmt > 0)
                        alpha = 0.6;
                    
                    color = [[UIColor alloc]initWithRed:1.0
                                                  green:1.0
                                                   blue:0.0
                                                  alpha:alpha];
                    break;
                    
                case 4://tax_exempt
                    if (*taxExempt == taxExemptCode)
                        alpha = 0.6;
                    
                    /*color = [[UIColor alloc]initWithRed:0.0
                     green:1.0
                     blue:0.0
                     alpha:alpha];*/
                case 5://tax_forfeit
                    if (!strcasecmp (owner,"HENNEPIN FORFEITED LAND"))
                        alpha = 0.8;
                    
                    color = [[UIColor alloc]initWithRed:0.0
                                                  green:1.0
                                                   blue:1.0
                                                  alpha:alpha];
                    break;
                case 6://last_sale
                    if (saleval > 0)
                        alpha = 0.8;
                    
                    color = [[UIColor alloc]initWithRed:0.0
                                                  green:1.0
                                                   blue:1.0
                                                  alpha:alpha];
                    break;
            }
            
            [self fillParcel:context
                     nPoints:numPoints
                      points:llpoints
                   withColor:color.CGColor];
        }
        else if (CRAPI.sharedInstance.parcelColorOption)
        {
            CGFloat alpha = 0;
            UIColor *color;
            int opt = CRAPI.sharedInstance.parcelColorOption;
            
            switch (opt)
            {
                case ParcelColorSettingTotEMV:
                    if (*homeStead == homeSteadCode)
                        alpha = 0.6;
                    
                    color = [[UIColor alloc]initWithRed:1.0
                                                  green:1.0
                                                   blue:0.0
                                                  alpha:alpha];
                    break;
                    
                case ParcelColorSettingLandEMV:
                    color = [self resComColor:useCode];
                    break;
                    
                case ParcelColorSettingLandEMVPerAcre:
                {
                    float r,g,b;
                    r = g = b = alpha = 0;
                    if (acres > 0)
                    {
                        valuePerAcre = emvLand / acres;
                        if (valuePerAcre > targetPidValue * 1.01)
                        {
                            alpha = 0.6;
                            r = 1;
                            g = 0;
                            b = 0;
                        }
                        else if (valuePerAcre < targetPidValue * 0.99)
                        {
                            alpha = 0.6;
                            r =0;
                            g = 0;
                            b = 1;
                        }

                    }
                    
                    color = [[UIColor alloc]initWithRed:r
                                                  green:g
                                                   blue:b
                                                  alpha:alpha];
                }
                    break;
                    
                case ParcelColorSettingBuildingEMV:
                    if (*taxExempt == taxExemptCode)
                        alpha = 0.6;
                    
                    /*color = [[UIColor alloc]initWithRed:0.0
                     green:1.0
                     blue:0.0
                     alpha:alpha];*/
                case 6://tax_forfeit
                    if (!strcasecmp (owner,"HENNEPIN FORFEITED LAND"))
                        alpha = 0.8;
                    
                    color = [[UIColor alloc]initWithRed:0.0
                                                  green:1.0
                                                   blue:1.0
                                                  alpha:alpha];
                    break;
            }
            
            [self fillParcel:context
                     nPoints:numPoints
                      points:llpoints
                   withColor:color.CGColor];
        }
        
        if (CRAPI.sharedInstance.showParcelBoundary)
        {
            [self drawParcel:context
                     nPoints:numPoints
                      nLoops:numLoops
                     partLen:polyPartLen
                      points:llpoints
                   withColor:parcelLineColor.CGColor
                    andWidth:parcelLineWidth];
        }
        
        free (llpoints);
    }
    
    SQLOKpd(sqlite3_finalize(statement), _database, 43);
    [self close:opened];
}

- (LPDPOINT)getParcelPolygonPointsForPID:(NSString *)PID
                               numPoints:(int *)numPoints
                                numLoops:(int *)numLoops
                             polyPartLen:(int **)polyPartLen
{
    DPOINT basePoint = {0};
    LPDPOINT llpoints = NULL;
    sqlite3_stmt *statement = NULL;
    if (polyPartLen)
        *polyPartLen = 0;
    BOOL opened = [self open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points FROM PARCELPOLY WHERE PARCELPOLY.PID = '%@'", PID];
    
    SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database, 44);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        basePoint.x = sqlite3_column_double(statement, 0);
        basePoint.y = sqlite3_column_double(statement, 1);
        *numPoints = sqlite3_column_int(statement, 2);
        *numLoops = sqlite3_column_int(statement, 3);
        if (*numLoops > 1 && polyPartLen)
        {
            *polyPartLen = malloc (*numLoops * sizeof (int));
            memcpy (*polyPartLen,(int *)sqlite3_column_blob(statement,4),*numLoops * sizeof(int));
        }
        LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement, 5);
        llpoints = malloc(abs(*numPoints) * sizeof(DPOINT) + 4);
        
        if (*numPoints < 0)
        {
            *numPoints = -*numPoints;
            LPSPOINT offsetPoints16 = (LPSPOINT)offsetPoints;
            
            for (int i = 0; i < *numPoints; i++)
            {
                llpoints[i].x = (basePoint.x + offsetPoints16[i].x / COORDINATE_FACTOR);
                llpoints[i].y = (basePoint.y + offsetPoints16[i].y / COORDINATE_FACTOR);
            }
        }
        
        else for (int i = 0; i < *numPoints; i++)
        {
            llpoints[i].x = (basePoint.x + offsetPoints[i].x / COORDINATE_FACTOR);
            llpoints[i].y = (basePoint.y + offsetPoints[i].y / COORDINATE_FACTOR);
        }
    }
    
    SQLOKpd(sqlite3_finalize(statement), _database, 45);
    
    [self close:opened];
    
    return llpoints;
}
- (UIColor *)resComColor:(char *)useCode
{
    UIColor *color = nil;
    CGFloat alpha = 0.6;
    
    switch ([self useCodeClass:useCode])
    {
        case 'N':
            color = [[UIColor alloc]initWithRed:0.0
                                          green:1.0
                                           blue:0.0
                                          alpha:alpha];
            break;
            
        case 'M':
            color = [[UIColor alloc]initWithRed:1.0
                                          green:1.0
                                           blue:0.0
                                          alpha:alpha];
            break;
            
        case 'R':
            color = [[UIColor alloc]initWithRed:0.0
                                          green:0.0
                                           blue:1.0
                                          alpha:alpha];
            break;
            
        case 'V':
            color = [[UIColor alloc]initWithRed:0.0
                                          green:1.0
                                           blue:1.0
                                          alpha:alpha];
            break;
    }
    
    return color;
}

- (char)useCodeClass:(char *)useCode
{
    if (!strcasecmp(useCode, "CAUT"))
        return 'N';
    
    if (!strcasecmp(useCode, "CBRE"))
        return 'N';
    
    if (!strcasecmp(useCode, "CMXD"))
        return 'M';
    
    if (!strcasecmp(useCode, "COFF"))
        return 'N';
    
    if (!strcasecmp(useCode, "CRET"))
        return 'N';
    
    if (!strcasecmp(useCode, "CSCH"))
        return 'N';
    
    if (!strcasecmp(useCode, "CUTL"))
        return 'N';
    
    if (!strcasecmp(useCode, "CWKS"))
        return 'N';
    
    if (!strcasecmp(useCode, "GMRS"))
        return 'R';
    
    if (!strcasecmp(useCode, "GRES"))
        return 'R';
    
    if (!strcasecmp(useCode, "HMTL"))
        return 'N';
    
    if (!strcasecmp(useCode, "IWFW"))
        return 'N';
    
    if (!strcasecmp(useCode, "MFAP"))
        return 'R';
    
    if (!strcasecmp(useCode, "MFRS"))
        return 'R';
    
    if (!strcasecmp(useCode, "MISC"))
        return 'N';
    
    if (!strcasecmp(useCode, "RCMS"))
        return 'R';
    
    if (!strcasecmp(useCode, "SFAD"))
        return 'R';
    
    if (!strcasecmp(useCode, "SFDD"))
        return 'R';
    
    if (!strcasecmp(useCode, "SPRC"))
        return 'N';
    
    if (!strcasecmp(useCode, "VLND"))
        return 'V';
    
    return '?';
}

+(NSString*) adjustParcelText:(NSString*)text
{
    
    text = [text stringByReplacingOccurrencesOfString:@"& "
                                           withString:@"&\n"];
    
    text = [text stringByReplacingOccurrencesOfString:@"1/2"
                                           withString:@"!@#"];
    
    text = [text stringByReplacingOccurrencesOfString:@"/"
                                           withString:@"/\n"];
    
    text = [text stringByReplacingOccurrencesOfString:@"/ "
                                           withString:@"/\n"];
    
    text = [text stringByReplacingOccurrencesOfString:@"!@#"
                                           withString:@"1/2"];
    
    text = [text stringByReplacingOccurrencesOfString:@"\n "
                                           withString:@"\n"];
    
    text = [text stringByReplacingOccurrencesOfString:@" \n "
                                           withString:@"\n"];
    
    text = [text stringByReplacingOccurrencesOfString:@" ET AL"
                                           withString:@"\nET AL"];
    
    if ([text characterAtIndex:0] == ' ')
    {
        NSMutableString *tempString = text.mutableCopy;
        NSRange firstCharRange = {0,1};
        [tempString deleteCharactersInRange:firstCharRange];
        text = tempString;
    }
    
    if ([text characterAtIndex:(text.length - 1)] == ' ' ||
        [text characterAtIndex:(text.length - 1)] == '\n' ||
        [text characterAtIndex:(text.length - 1)] == '\r')
    {
        NSMutableString *tempString = text.mutableCopy;
        NSRange firstCharRange = {0,1};
        [tempString deleteCharactersInRange:firstCharRange];
        text = tempString;
    }
    
    return text;
}
- (void)displayText:(NSString *)text
             forPID:(NSString *)PID
            atPoint:(LPDPOINT)pviewPointx
             inRect:(CGRect *)ptextRect
          maxPixels:(CGFloat)maxPixels
            context:(CGContextRef)context
{
    extern MNMXCORD curbounds;
    //BOOL dbug = NO;
    CGFloat scale = [UIScreen mainScreen].scale;
    scale = [UIScreen mainScreen].nativeScale;
    CGFloat fontSize = 18.0 * scale;
    CGFloat minFontSize = 4.0 * scale;
    int numPoints = 0, numLoops = 0;
    int *polyPartLen = 0;
    //int ii=0;
    UIColor *textColor = nil;
    if (text.length < 1)
        return;
    if (text.length * minFontSize * minFontSize > maxPixels)
        return;
    if (ConfigurationControl.sharedInstance.GMTilesVisible)
        textColor = UIColor.redColor;
    else
        textColor = UIColor.blackColor;
    
    text = [PropertyData adjustParcelText:text];
    //if ([text isEqualToString:@"CALHOUN SQ ENTERPRISE LLC\n$1,112,000"])
    //ii=0;
    
    LPDPOINT pPoints = [self getParcelPolygonPointsForPID:PID
                                                numPoints:&numPoints
                                                 numLoops:&numLoops
                                              polyPartLen:&polyPartLen];
    
    for (int i = 0; i < numPoints; i++)
        pPoints[i] = TranDPOINT(&pPoints[i], _pTranLLtoView);
    
    [NVTextDrawing drawText:text
                  inContext:context
              withinPolygon:pPoints
              withNumPoints:numPoints
                andNumLoops:numLoops
                    loopLen:polyPartLen
               withinBounds:&curbounds
                   fontSize:fontSize
                minFontSize:minFontSize
                  textColor:textColor
               processingID:_processingID];
    if (polyPartLen)
        free (polyPartLen);
    
    free(pPoints);
    
    
Exit:
    return;
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

-(double)totalEMVforLinkedParcels:(NSString*)pid
{
    double tot = 0;
    sqlite3_stmt *statement = NULL;
    
    double acres;
    double emvTotal;
    double emvLand;
    LPSTR homeStead, useCode, useDesc, taxExempt, owner, taxName, bldgNum;
    LPSTR saleDate;
    double saleVal, specAssmt;
    int numLinked;
    
    NSString *query = [NSString stringWithFormat:@"SELECT PIN,ACRES_POLY,HOMESTEAD,USE1_DESC,USE2_DESC,TAX_EXEMPT,EMV_TOTAL,EMV_LAND,SPEC_ASSES, OWNER_NAME,TAX_NAME,BLDG_NUM,SALE_DATE,SALE_VALUE, NUMLINKEDPARCELS FROM PROPINFO WHERE PROPINFO.LINKEDPARCEL = '%@'",pid];
    
    SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database, 46);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR pid = (LPSTR)sqlite3_column_text(statement, 0);
        //PID = [NSString stringWithUTF8String:pid];
        acres = (CGFloat)sqlite3_column_double(statement, 1);
        homeStead = (LPSTR)sqlite3_column_text(statement, 2);
        useCode = (LPSTR)sqlite3_column_text(statement, 3);
        useDesc = (LPSTR)sqlite3_column_text(statement, 4);
        taxExempt = (LPSTR)sqlite3_column_text(statement, 5);
        emvTotal = (CGFloat)sqlite3_column_double(statement, 6);
        emvLand = (CGFloat)sqlite3_column_double(statement, 7);
        specAssmt = (CGFloat)sqlite3_column_double(statement, 8);
        owner = (LPSTR)sqlite3_column_text(statement, 9);
        taxName = (LPSTR)sqlite3_column_text(statement, 10);
        bldgNum = (LPSTR)sqlite3_column_text(statement, 11);
        saleDate = (LPSTR)sqlite3_column_text(statement, 12);
        saleVal = (CGFloat)sqlite3_column_double(statement, 13);
        numLinked = (CGFloat)sqlite3_column_int(statement, 14);
        tot += emvTotal;
    }
    SQLOKpd(sqlite3_finalize(statement), _database, 47);
    return tot;
}
-(NSArray*)getLinkedParcels:(NSString*)pid
{
    NSMutableArray * array=NSMutableArray.new;
    BOOL opened = [self open];
    sqlite3_stmt *statement = NULL;
    
    double emvTotal;
    double emvLand;
    LPSTR homeStead, useCode, useDesc, taxExempt, owner, taxName, bldgNum, unit;
    LPSTR saleDate;
    double saleVal, specAssmt;
    
    NSString *query = [NSString stringWithFormat:@"SELECT PIN,HOMESTEAD,USE1_DESC,USE2_DESC,TAX_EXEMPT,EMV_TOTAL,EMV_LAND,SPEC_ASSES, OWNER_NAME,TAX_NAME,BLDG_NUM,STREETNAME,UNIT_INFO,CITY,SALE_DATE,SALE_VALUE FROM PROPINFO WHERE PROPINFO.LINKEDPARCEL = '%@'",pid];
    
    SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database, 46);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        PropertyDataExtract * pde = PropertyDataExtract.new;
        
        LPSTR pid = (LPSTR)sqlite3_column_text(statement, 0);
        pde.PIN = [NSString stringWithUTF8String:pid];
        //PID = [NSString stringWithUTF8String:pid];
        homeStead = (LPSTR)sqlite3_column_text(statement, 2);
        useCode = (LPSTR)sqlite3_column_text(statement, 3);
        useDesc = (LPSTR)sqlite3_column_text(statement, 4);
        taxExempt = (LPSTR)sqlite3_column_text(statement, 5);
        emvTotal = (CGFloat)sqlite3_column_double(statement, 6);
        emvLand = (CGFloat)sqlite3_column_double(statement, 7);
        specAssmt = (CGFloat)sqlite3_column_double(statement, 8);
        owner = (LPSTR)sqlite3_column_text(statement, 9);
        taxName = (LPSTR)sqlite3_column_text(statement, 10);
        unit = (LPSTR)sqlite3_column_text(statement, 12);
        pde.unit = [NSString stringWithUTF8String:unit];
        saleDate = (LPSTR)sqlite3_column_text(statement, 13);
        saleVal = (CGFloat)sqlite3_column_double(statement, 14);
        [array addObject:pde];
    }
    SQLOKpd(sqlite3_finalize(statement), _database, 47);
    [self close:opened];
    return array;
}
- (void)displayParcelText:(CGContextRef)context
                llCorners:(CORNERPOINTS *)latlonCornerPoints
                 LLBounds:(MNMXCORD *)platlonBounds
               viewBounds:(MNMXCORD *)pvbounds
{
    if (!CRAPI.sharedInstance.parcelTextOption)
        return;
    curbounds = *pvbounds;//db
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    
    _pTranLLtoView = STRANCornersToBounds(latlonCornerPoints, pvbounds);
    int numLinked;
    int maxPixels;
    DPOINT p1, p2;
    MNMXCORD bnds, bndsScreen;
    CGFloat boundsWidthInMeters, boundsHeightInMeters;
    LPSTR saleDate;
    double saleVal;
    p1.x = platlonBounds->xmn;
    p1.y = platlonBounds->ymn;
    p2.x = platlonBounds->xmn;
    p2.y = platlonBounds->ymx;
    boundsHeightInMeters = ArcDistance(p1, p2);
    p2.x = platlonBounds->xmx;
    p2.y = platlonBounds->ymn;
    boundsWidthInMeters = ArcDistance(p1, p2);
    CGFloat boundsInAcres = boundsWidthInMeters * boundsHeightInMeters * ACRES_PER_SQMETER;
    CGFloat boundsInPixels = (pvbounds->xmx - pvbounds->xmn) * (pvbounds->ymx - pvbounds->ymn);
    CGFloat acresToPixelsFactor = fabs(boundsInPixels / boundsInAcres);
    NSString *query;
    sqlite3_stmt *statement = NULL;
    //LPSTR pid;
    DPOINT BasePt, viewPoint;
    CGFloat emvTotal, emvLand,acres;
    //CGFloat specAssmt;
    LPSTR owner, taxName,bldgNum;
    //LPSTR homeStead, useCode, useDesc, taxExempt;
    //char homeSteadCode = 'H';
    //char taxExemptCode = 'E';
    NSString *text = @"";
    NSString *PID = @"";
    NSNumberFormatter *dollarFmt = [[NSNumberFormatter alloc] init];
    dollarFmt.numberStyle = NSNumberFormatterCurrencyStyle;
    dollarFmt.groupingSeparator = @"'";
    dollarFmt.groupingSize = 3;
    dollarFmt.alwaysShowsDecimalSeparator = NO;
    dollarFmt.usesGroupingSeparator = YES;
    dollarFmt.maximumFractionDigits = 0;
    BOOL opened = [self open];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_MPLS:
            query = [NSString stringWithFormat:@"SELECT PROPINFO.PID,BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,PARCELPOLY.id,HOMESTEAD,USECODE,USE_DESC,TAX_EXEMPT,TOTAL_VALUE FROM PARCELPOLY,PARCELPOLY_index, PROPINFO WHERE PARCELPOLY.id=PARCELPOLY_index.id AND PROPINFO.PID=PARCELPOLY.PID AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                     platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
            break;
            
        case PROJECT_METROGIS:
            //homeSteadCode = 'Y';
            //taxExemptCode = 'Y';
            query = [NSString stringWithFormat:@"SELECT PIN,LATITUDE,LONGITUDE,ACRES_POLY,HOMESTEAD,USE1_DESC,USE2_DESC,TAX_EXEMPT,EMV_TOTAL,EMV_LAND,SPEC_ASSES,OWNER_NAME,TAX_NAME,BLDG_NUM,SALE_DATE,SALE_VALUE, NUMLINKEDPARCELS, \
                     PARCELPOLY_index.minX,PARCELPOLY_index.maxX,PARCELPOLY_index.minY,PARCELPOLY_index.maxY\
                     FROM PROPINFO,PROPINFO_index,PARCELPOLY,PARCELPOLY_index WHERE PROPINFO.id=PROPINFO_index.id AND PARCELPOLY_index.maxX>=%f AND PARCELPOLY_index.minX<=%f AND PARCELPOLY_index.maxY>=%f AND PARCELPOLY_index.minY<=%f AND PARCELPOLY.PID = PROPINFO.PIN AND PARCELPOLY_index.id = PARCELPOLY.id",
                     platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
            /* query = [NSString stringWithFormat:@"SELECT PIN,LATITUDE,LONGITUDE,ACRES_POLY,HOMESTEAD,USE1_DESC,USE2_DESC,TAX_EXEMPT,EMV_TOTAL,SPEC_ASSES,OWNER_NAME,BLDG_NUM FROM PROPINFO,PROPINFO_index WHERE PROPINFO.id=PROPINFO_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
             platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
             query = [NSString stringWithFormat:@"SELECT PID,BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,PARCELPOLY.id,HOMESTEAD,USE1_DESC,USE2_DESC,TAX_EXEMPT,EMV_TOTAL,SPEC_ASSES,OWNER_NAME  FROM PARCELPOLY,PARCELPOLY_index,PROPINFO WHERE PARCELPOLY.id=PARCELPOLY_index.id AND PROPINFO.PIN=PARCELPOLY.PID AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",*/
            
    }
    
    SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database, 46);
    
    while ([self continue] && sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR pid = (LPSTR)sqlite3_column_text(statement, 0);
        PID = [NSString stringWithUTF8String:pid];
        BasePt.y = sqlite3_column_double(statement,1);
        BasePt.x = sqlite3_column_double(statement,2);
        acres = (CGFloat)sqlite3_column_double(statement, 3);
        maxPixels = acres *acresToPixelsFactor;
        if (maxPixels < 100)
            continue;
        //homeStead = (LPSTR)sqlite3_column_text(statement, 4);
        //useCode = (LPSTR)sqlite3_column_text(statement, 5);
        //useDesc = (LPSTR)sqlite3_column_text(statement, 6);
        //taxExempt = (LPSTR)sqlite3_column_text(statement, 7);
        emvTotal = (CGFloat)sqlite3_column_double(statement, 8);
        emvLand = (CGFloat)sqlite3_column_double(statement, 9);
        //specAssmt = (CGFloat)sqlite3_column_double(statement, 10);
        owner = (LPSTR)sqlite3_column_text(statement, 11);
        taxName = (LPSTR)sqlite3_column_text(statement, 12);
        bldgNum = (LPSTR)sqlite3_column_text(statement, 13);
        saleDate = (LPSTR)sqlite3_column_text(statement, 14);
        saleVal = (CGFloat)sqlite3_column_double(statement, 15);
        numLinked = (CGFloat)sqlite3_column_int(statement, 16);

        bnds.xmn = (CGFloat)sqlite3_column_double(statement, 17);
        bnds.xmx = (CGFloat)sqlite3_column_double(statement, 18);
        bnds.ymn = (CGFloat)sqlite3_column_double(statement, 19);
        bnds.ymx = (CGFloat)sqlite3_column_double(statement, 20);
        //CGFloat alpha = 0.0;
        //UIColor *color;
        //int opt = CRAPI.sharedInstance.parcelTextOption;
        NSNumber *num;
        text = @"";
        
        switch (CRAPI.sharedInstance.parcelTextOption)
        {
            case ParcelTextSettingOwnerTax://homestead
                if (numLinked < 0)
                {
                    int nLinked = (-numLinked)+1;
                    double emvTotal = [self totalEMVforLinkedParcels:PID];
                    double emvAve = emvTotal / nLinked;
                    num = [[NSNumber alloc] initWithDouble:emvTotal];
                    NSNumber *numAve = [[NSNumber alloc] initWithDouble:emvAve];
                    text = [NSString stringWithFormat:@"%i Parcels\nTotal:%@\nAve:%@", nLinked, [dollarFmt stringFromNumber:num],[dollarFmt stringFromNumber:numAve]];
                }
                else
                {
                    LPSTR name = owner;
                    
                    if (!*name)
                        name = taxName;
                    num = [[NSNumber alloc] initWithDouble:emvTotal];
                    text = [NSString stringWithFormat:@"%s\n%@", name, [dollarFmt stringFromNumber:num]];
                }
                break;
                
            case ParcelTextSettingBuildingNum:
                text = [NSString stringWithUTF8String:bldgNum];
                break;
                
            case ParcelTextSettingEMVLand:
                text = [NSString stringWithFormat:@"%.0f",emvLand];
                break;
                
            case ParcelTextSettingEMVLandPerAcre:
                if (acres > 0)
                    text = [NSString stringWithFormat:@"%.0f",emvLand/acres];
                break;
            case 5:
                if (saleVal > 0)
                {
                    char year[5], month[3];
                    strncpy (year,saleDate,4);
                    year[4] = 0;
                    strncpy (month,&saleDate[4],2);
                    month[2] = 0;
                    num = [[NSNumber alloc] initWithDouble:saleVal];
                    text = [NSString stringWithFormat:@"%@\n%s-%s", [dollarFmt stringFromNumber:num],year,month];
                }
                break;
                
            default:
                break;
        }
        
        viewPoint = TranDPOINT(&BasePt, _pTranLLtoView);
        TranMNMXCORD(&bnds, &bndsScreen, _pTranLLtoView);
        CGRect textRect = MNMXCORDtoCGRect(&bndsScreen);
        
        [self displayText:text
                   forPID:PID
                  atPoint:&viewPoint
                   inRect:(CGRect*)&textRect
                maxPixels:maxPixels
                  context:context];
    }
    
    SQLOKpd(sqlite3_finalize(statement), _database, 47);
    [self close:opened];
}

- (void)computeValuesFromTables:(DATA_FROM_TABLES *)values
                   inCensusArea:(LPSTR)cenBlockIN
                         totEMV:(int)totEMV
                        useDesc:(LPSTR) usedescIN
{
    sqlite3_stmt *statement = NULL;
    int nHomestead=0;
    int totProp = 0;
    double sumEMV=0;
    double sumAcres=0;
    //double pctAveEMV;
    //double aveEMV;
    //double pctMedianEMV;
    int medianEMV=0;
    
    //double pctMedEMV;
    int myTotEMV = totEMV;
    int nAge = 0, nSales5yr = 0, nSales15yr = 0;
    int minSale = INT_MAX;
    CGFloat totYears = 0;
    //CGFloat medianAge = 0;
    CGFloat totAcres = 0, totOSAcres = 0;
    
    memset (values,0,sizeof(DATA_FROM_TABLES));
    /*    NSString *query = [NSString stringWithFormat:@"SELECT ACRES_POLY,USE1_DESC,SALE_DATE,EMV_TOTAL,TOTAL_TAX,HOMESTEAD,YEAR_BUILT,OPEN_SPACE FROM PROPINFO WHERE CENBLOCK='%s'",
     cenBlock];*/
    NSString *query;
    if (strlen (cenBlockIN) == 12)
        query = [NSString stringWithFormat:@"SELECT ACRES_POLY,USE1_DESC,SALE_DATE,EMV_TOTAL,TOTAL_TAX,HOMESTEAD,YEAR_BUILT,OPEN_SPACE FROM PROPINFO WHERE CENBLOCK>='%s000' AND CENBLOCK<='%s999'",cenBlockIN,cenBlockIN];
    else if (strlen (cenBlockIN) > 12)
        query = [NSString stringWithFormat:@"SELECT ACRES_POLY,USE1_DESC,SALE_DATE,EMV_TOTAL,TOTAL_TAX,HOMESTEAD,YEAR_BUILT,OPEN_SPACE FROM PROPINFO WHERE CENBLOCK='%s'",cenBlockIN];
    else
        return;
    
    BOOL opened = [self open];
    NSMutableArray * array=[[NSMutableArray alloc]init];
    NSMutableArray * ageArray=[[NSMutableArray alloc]init];
    SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database, 48);
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        CGFloat acres = sqlite3_column_double(statement,0);
        LPSTR useDesc = (LPSTR)sqlite3_column_text(statement, 1);
        LPSTR saleDate = (LPSTR)sqlite3_column_text(statement, 2);
        int totEMV = (int)sqlite3_column_double(statement, 3);
        //double totTax = sqlite3_column_double(statement, 4);
        LPSTR homestead = (LPSTR)sqlite3_column_text(statement, 5);
        LPSTR yearBuilt = (LPSTR)sqlite3_column_text(statement, 6);
        LPSTR openSpace = (LPSTR)sqlite3_column_text(statement, 7);
        
        totProp++;
        int yrBuilt = atoi (yearBuilt);
        if (*homestead == 'y' || *homestead == 'Y')
            nHomestead++;
        totAcres += acres;
        if (*openSpace != 'N')
        {
            if (*openSpace == 'y' || *openSpace == 'Y')
                totOSAcres += acres;
        }
        if (!strcasecmp (useDesc,usedescIN))
        {
            values->nMatchingProperties++;
            if (*saleDate)
            {
                int date = atoi (saleDate);
                minSale = min (minSale,date);
                date /= 10000;
                if (date >= 2010)
                    nSales5yr++;
                if (date >= 2005)
                    nSales15yr++;
            }
            if (yrBuilt > 1800)
            {
                totYears += yrBuilt;
                nAge++;
                NSNumber *age = [[NSNumber alloc]initWithInt:yrBuilt];
                [ageArray addObject:age];
            }
            if (totEMV > 0)
            {
                NSNumber * emv = [NSNumber numberWithInteger:totEMV];
                [array addObject:emv];
                sumAcres += acres;
                sumEMV += totEMV;
            }
        }
    }
    if (values->nMatchingProperties)
    {
        values->stability5yr  = IDNINT(100.0-(100.0 * nSales5yr) / values->nMatchingProperties);
        values->stability15yr = IDNINT(100.0-(100.0 * nSales15yr) / values->nMatchingProperties);
    }
    if (totProp)
    {
        values->pctHomestead  = IDNINT((100.0 * nHomestead) / totProp);
    }
    if (nAge)
    {
        //totYears /= nAge;
        [ageArray sortUsingComparator: ^(id obj1, id obj2)
         {
             NSNumber *v1 = obj1;
             NSNumber *v2 = obj2;
             
             if (v1 > v2)
                 return (NSComparisonResult)NSOrderedDescending;
             
             if (v1 < v2)
                 return (NSComparisonResult)NSOrderedAscending;
             
             return (NSComparisonResult)NSOrderedSame;
         }];
        
        int median = (nAge / 2);
        NSNumber *age1 = (NSNumber *)ageArray[median];
        
        if (!(nAge %2))
        {
            NSNumber *age2 = (NSNumber *)ageArray[median - 1];
            values->medianBuiltYear = ((age1.floatValue + age2.floatValue) / 2.0);
        }
        else
            values->medianBuiltYear = age1.intValue;
    }
    
    [array sortUsingComparator: ^(id obj1, id obj2)
     {
         NSNumber *v1 = obj1;
         NSNumber *v2 = obj2;
         
         if (v1 > v2)
             return (NSComparisonResult)NSOrderedDescending;
         
         if (v1 < v2)
             return (NSComparisonResult)NSOrderedAscending;
         
         return (NSComparisonResult)NSOrderedSame;
     }];
    
    if ([array count])
    {
        int n=1;
        int myStartRank= -1;
        int myEndRank= -1;
        int medianN = (int)array.count / 2;
        int medianM = array.count % 2;
        //NSNumber *minEMV = array[0];
        //NSNumber *maxEMV = array[array.count - 1];
        for (NSNumber *EMVvalue in array)
        {
            if (n == medianN)
                medianEMV = EMVvalue.intValue;
            
            if (n == medianN + medianM)
                medianEMV = (medianEMV + EMVvalue.intValue) / 2;
            
            if (EMVvalue.integerValue == myTotEMV)
            {
                if (myStartRank < 0)
                    myStartRank = n;
                myEndRank = n;
            }
            n++;
        }
        
        //aveEMV = sumEMV / [array count];
        //pctAveEMV = ((double)myTotEMV / aveEMV) * 100;
        //pctMedianEMV = ((double)myTotEMV / medianEMV) * 100;
        values->rankTotEMV = IDNINT((100.0 * (myStartRank + myEndRank)/2.0)/[array count]);
    }
    
    SQLOKpd(sqlite3_finalize(statement),_database, 49);
    
    
    if (strlen (cenBlockIN) > 12)
        query = [NSString stringWithFormat:@"SELECT MEDIANAGE,HOMEOWNPCT,HHTOTAL,HH_UNDER18,HH_65OVER FROM CENSUSBLOCKDATA WHERE GEOG_UNIT ='%s'",cenBlockIN];
    else
        query = [NSString stringWithFormat:@"SELECT MEDIANAGE,HOMEOWNPCT,HHTOTAL,HH_UNDER18,HH_65OVER FROM CENSUSBLOCKGROUPDATA WHERE GEOG_UNIT ='%s'",cenBlockIN];
    SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database, 50);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        values->medianAgePop = sqlite3_column_double(statement,0);
        values->homeOwnPct = 100.0 * sqlite3_column_double(statement,1);
        int hhTot = sqlite3_column_int(statement,2);
        int hh18 = sqlite3_column_int(statement,3);
        int hh65 = sqlite3_column_int(statement,4);
        if (hhTot > 0)
        {
            values->pctChildren = (100.0 * hh18)/hhTot;
            values->pctSenior   = (100.0 * hh65)/hhTot;
        }
    }
    
    SQLOKpd(sqlite3_finalize(statement), _database, 51);
    
    [self close:opened];
}

-(NSMutableArray *) getParcelHistory:(NSString*)PID
{
    NSMutableArray * values = [NSMutableArray new];
    LPYEARLYVALUES pYearly;
    int nYears, firstYear, lastYear, offset=0;
    BOOL opened = [self open];
    
    sqlite3_stmt *statement = NULL;
    
    NSString *query = [NSString stringWithFormat:@"SELECT MULTIYEAROFFSET FROM PROPINFO WHERE PIN = '%@'",PID];
    
    SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database, 46);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        offset = sqlite3_column_int(statement, 0);
    }
    SQLOKpd(sqlite3_finalize(statement), _database, 47);

    if (offset)
    {
        FILE * fid = fopen (_multiValueFile.UTF8String,"rb");
        BOOL homestead, taxexempt;
        int ii = sizeof(YEARLYVALUES);
        int compressedSize;
        int decompressedSize;
        LPBYTE pCompressed;
        LPINT pInts, pIntsInit;
    
        fread(&nYears, 4, 1, fid);
        fread(&firstYear, 4, 1, fid);
        fread(&lastYear, 4, 1, fid);
        pYearly = (LPYEARLYVALUES)malloc (nYears * sizeof(YEARLYVALUES));
        pIntsInit = pInts = (LPINT)malloc (nYears*8*4);
        fseek(fid, offset, SEEK_SET);
        BigRead(fid, &compressedSize, 4);
        pCompressed = malloc (compressedSize);
        BigRead (fid,pCompressed,compressedSize);
        fclose(fid);
        decompressedSize = DecompressBinaryRecordUnsafe((LPBYTE)pInts, pCompressed, compressedSize);
        for (int ival = 0;ival<8;ival++)
        {
            for (int iyear=0;iyear<nYears;iyear++)
            {
                LPINT pInt2 = (LPINT)&pYearly[iyear];
                pInt2 += ival;
                *pInt2++ = *pInts++;
            }
        }
        for (int iyear=0;iyear<nYears;iyear++)
        {
            PropertyHistory *ph = PropertyHistory.new;
            
            ph.year = lastYear - iyear;
            ph.emvLand = pYearly[iyear].EMV_LAND;
            if (ph.emvLand < 0)
            {
                ph.emvLand = -(ph.emvLand + 1);
                homestead = TRUE;
            }
            ph.emvBldg = pYearly[iyear].EMV_BLDG;
            if (ph.emvBldg < 0)
            {
                ph.emvBldg = -(ph.emvBldg + 1);
                taxexempt = TRUE;
            }
            ph.emvTotal = pYearly[iyear].EMV_TOTAL;
            ph.taxCapacity = pYearly[iyear].TAX_CAPACITY;
            ph.totalTax = pYearly[iyear].TOTAL_TAX;
            ph.specAsses = pYearly[iyear].SPEC_ASSES;
            ph.saledate = pYearly[iyear].SALE_YEAR;
            ph.saleVal = pYearly[iyear].SALE_VALUE;
            [values addObject:ph];
        }
        free (pYearly);
        free (pIntsInit);
        free (pCompressed);
    }
    [self close:opened];
    return values;
}

- (NSMutableArray *)getReport:(PropDataOption)option
                       forPID:(NSString *)pid
{
    NSMutableArray *history = nil;//[self getParcelHistory:pid];
    NSMutableArray *report = [[NSMutableArray alloc] init];
    sqlite3_stmt *statement = NULL;
    char censusBlock[32];
    char usedesc[32];
    BOOL opened = [self open];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_MPLS:
        {
            NSString *query = [NSString stringWithFormat:@"SELECT HOUSENUM,HOUSEFRACT,STREET,UNITNUM,ZIPCODE,\"OWNER NAME\",\"TAXPAYER NAME\",\"TAXPAYER ADDR1\",\"TAXPAYER ADDR2\",\"TAXPAYER ADDR3\",PARCEL_DEPTH,PARCEL_FRONTAGE,AREA_SQFT,USECODE,USE_DESC,TAX_EXEMPT,LAND_VALUE,BLDG_VALUE,TOTAL_VALUE,TOTAL_TAX,HOMESTEAD,WTRSHD,PARCELZONE.ZONETYPE,ASSESSMENT_YEAR,Date_of_Query FROM PROPINFO,PARCELZONE WHERE PROPINFO.PID='%s' AND PARCELZONE.PID='%s'",
                               pid.UTF8String,pid.UTF8String];
            
            SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database, 54);
            
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                int house = sqlite3_column_int(statement,0);
                LPSTR houseFrac = (LPSTR)sqlite3_column_text(statement, 1);
                LPSTR street = (LPSTR)sqlite3_column_text(statement, 2);
                LPSTR unit = (LPSTR)sqlite3_column_text(statement, 3);
                LPSTR zipcode = (LPSTR)sqlite3_column_text(statement, 4);
                LPSTR ownerName = (LPSTR)sqlite3_column_text(statement, 5);
                LPSTR taxpayerName = (LPSTR)sqlite3_column_text(statement, 6);
                LPSTR taxpayerAddr1 = (LPSTR)sqlite3_column_text(statement, 7);
                LPSTR taxpayerAddr2 = (LPSTR)sqlite3_column_text(statement, 8);
                LPSTR taxpayerAddr3 = (LPSTR)sqlite3_column_text(statement, 9);
                CGFloat depth = sqlite3_column_double(statement, 10);
                CGFloat frontage = sqlite3_column_double(statement, 11);
                CGFloat sqfeet = sqlite3_column_double(statement, 12);
                LPSTR useCode = (LPSTR)sqlite3_column_text(statement, 13);
                LPSTR useDesc = (LPSTR)sqlite3_column_text(statement, 14);
                LPSTR taxExempt = (LPSTR)sqlite3_column_text(statement, 15);
                CGFloat landValue = sqlite3_column_double(statement, 16);
                CGFloat bldgValue = sqlite3_column_double(statement, 17);
                CGFloat totalValue = sqlite3_column_double(statement, 18);
                CGFloat totalTax = sqlite3_column_double(statement, 19);
                LPSTR homeStead = (LPSTR)sqlite3_column_text(statement, 20);
                LPSTR waterShed = (LPSTR)sqlite3_column_text(statement, 21);
                LPSTR zoning = (LPSTR)sqlite3_column_text(statement, 22);
                LPSTR assessmentYr = (LPSTR)sqlite3_column_text(statement, 23);
                LPSTR dateOfQuery = (LPSTR)sqlite3_column_text(statement, 24);
                
                NSNumberFormatter *dollarFmt = [[NSNumberFormatter alloc] init];
                dollarFmt.numberStyle = NSNumberFormatterCurrencyStyle;
                dollarFmt.groupingSeparator = @"'";
                dollarFmt.groupingSize = 3;
                dollarFmt.alwaysShowsDecimalSeparator = NO;
                dollarFmt.usesGroupingSeparator = YES;
                dollarFmt.maximumFractionDigits = 0;
                
                NSString *line;
                line = [NSString stringWithFormat:@"PID:%@", pid];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"House Number:%i %s", house, houseFrac];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Street:%s", street];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Unit:%s", unit];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Zipcode:%s", zipcode];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Owner:%s", ownerName];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Taxpayer:%s", taxpayerName];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Taxpayer Addr1:%s", taxpayerAddr1];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Taxpayer Addr2:%s", taxpayerAddr2];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Taxpayer Addr3:%s", taxpayerAddr3];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Parcel Depth:%.0f", depth];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Parcel Width:%.0f", frontage];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Parcel Area Sqft:%.0f", sqfeet];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Use Code:%s", useCode];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Use Desc:%s", useDesc];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Tax Exempt Status:%s", taxExempt];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Land Value:%@", [dollarFmt stringFromNumber:[NSNumber numberWithInt:(int)landValue]]];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Bldg Value:%@", [dollarFmt stringFromNumber:[NSNumber numberWithInt:(int)bldgValue]]];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Total Value:%@", [dollarFmt stringFromNumber:[NSNumber numberWithInt:(int)totalValue]]];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Total Tax:%@", [dollarFmt stringFromNumber:[NSNumber numberWithInt:(int)totalTax]]];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Homestead:%s", homeStead];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Watershed:%s", waterShed];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Zoning:%s", zoning];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Assessment Year:%s", assessmentYr];
                [report addObject:line];
                
                LPSTR pSpace = strrchr(dateOfQuery,' ');
                
                if (pSpace)
                    *pSpace = 0;
                
                line = [NSString stringWithFormat:@"Date of Query:%s", dateOfQuery];
                [report addObject:line];
                
                SQLOKpd(sqlite3_finalize(statement), _database, 55);
            }
        }
            break;
            
        case PROJECT_METROGIS:
        {
            NSString *query = [NSString stringWithFormat:@"SELECT BLDG_NUM,STREETNAME,UNIT_INFO,CITY,CITY_USPS,ZIP,ZIP4,PLAT_NAME,BLOCK,LOT,ACRES_POLY,ACRES_DEED,USE1_DESC,USE2_DESC,USE3_DESC,USE4_DESC,MULTI_USES,LANDMARK,OWNER_NAME,OWNER_MORE,EMV_LAND,EMV_BLDG,EMV_TOTAL,TAX_CAPAC,TOTAL_TAX,SPEC_ASSES,SALE_DATE,SALE_VALUE,CENBLOCK,TAX_NAME,HOMESTEAD,OWN_ADD_L1,OWN_ADD_L2,OWN_ADD_L3,TAX_ADD_L1,TAX_ADD_L2,TAX_ADD_L3,MULTIYEAROFFSET FROM PROPINFO WHERE PROPINFO.PIN='%s'",
                               pid.UTF8String];
            
            SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database, 56);
            /*
             CREATE TABLE PROPINFO ('id' INT,'PIN' CHAR(17),'BLDG_NUM' CHAR(10),'STREETNAME' CHAR(60),'UNIT_INFO' CHAR(12),'CITY' CHAR(30),'CITY_USPS' CHAR(30),'ZIP' CHAR(5),'ZIP4' CHAR(4),'PLAT_NAME' CHAR(50),'BLOCK' CHAR(5),'LOT' CHAR(5),'ACRES_POLY' REAL,'ACRES_DEED' REAL,'USE1_DESC' CHAR(100),'USE2_DESC' CHAR(100),'USE3_DESC' CHAR(100),'USE4_DESC' CHAR(100),'MULTI_USES' CHAR(1),'LANDMARK' CHAR(100),'OWNER_NAME' CHAR(50),'OWNER_MORE' CHAR(50),'OWN_ADD_L1' CHAR(40),'OWN_ADD_L2' CHAR(40),'OWN_ADD_L3' CHAR(40),'TAX_NAME' CHAR(40),'TAX_ADD_L1' CHAR(40),'TAX_ADD_L2' CHAR(40),'TAX_ADD_L3' CHAR(40),'HOMESTEAD' CHAR(1),'EMV_LAND' REAL,'EMV_BLDG' REAL,'EMV_TOTAL' REAL,'TAX_CAPAC' REAL,'TOTAL_TAX' REAL,'SPEC_ASSES' REAL,'TAX_EXEMPT' CHAR(1),'XUSE1_DESC' CHAR(100),'XUSE2_DESC' CHAR(100),'XUSE3_DESC' CHAR(100),'XUSE4_DESC' CHAR(100),'DWELL_TYPE' CHAR(30),'HOME_STYLE' CHAR(30),'FIN_SQ_FT' REAL,'GARAGE' CHAR(1),'GARAGESQFT' CHAR(11),'BASEMENT' CHAR(1),'HEATING' CHAR(30),'COOLING' CHAR(30),'YEAR_BUILT' CHAR(5),'NUM_UNITS' CHAR(6),'SALE_DATE' CHAR(8),'SALE_VALUE' REAL,'SCHOOL_DST' CHAR(6),'WSHD_DIST' CHAR(50),'GREEN_ACRE' CHAR(1),'OPEN_SPACE' CHAR(1),'AG_PRESERV' CHAR(1),'AGPRE_ENRD' CHAR(8),'AGPRE_EXPD' CHAR(8),'PARC_CODE' CHAR(5),'CENBLOCK' CHAR(15),'LONGITUDE' REAL,'LATITUDE' REAL,PRIMARY KEY('id' ASC))
             */
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                LPSTR house = (LPSTR)sqlite3_column_text(statement,0);
                LPSTR street = (LPSTR)sqlite3_column_text(statement, 1);
                LPSTR unit = (LPSTR)sqlite3_column_text(statement, 2);
                LPSTR city = (LPSTR)sqlite3_column_text(statement, 3);
                LPSTR cityUSPS = (LPSTR)sqlite3_column_text(statement, 4);
                LPSTR zipcode = (LPSTR)sqlite3_column_text(statement, 5);
                LPSTR zip4 = (LPSTR)sqlite3_column_text(statement, 6);
                LPSTR platName = (LPSTR)sqlite3_column_text(statement, 7);
                LPSTR block = (LPSTR)sqlite3_column_text(statement, 8);
                LPSTR lot = (LPSTR)sqlite3_column_text(statement, 9);
                CGFloat acresPoly = sqlite3_column_double(statement, 10);
                CGFloat acresDeed = sqlite3_column_double(statement, 11);
                LPSTR UseDesc1 = (LPSTR)sqlite3_column_text(statement, 12);
                LPSTR UseDesc2 = (LPSTR)sqlite3_column_text(statement, 13);
                LPSTR UseDesc3 = (LPSTR)sqlite3_column_text(statement, 14);
                LPSTR UseDesc4 = (LPSTR)sqlite3_column_text(statement, 15);
                LPSTR multiUses = (LPSTR)sqlite3_column_text(statement,16);
                LPSTR landMark = (LPSTR)sqlite3_column_text(statement, 17);
                LPSTR ownerName = (LPSTR)sqlite3_column_text(statement, 18);
                LPSTR ownerMore = (LPSTR)sqlite3_column_text(statement, 19);
                CGFloat landEMV = sqlite3_column_double(statement, 20);
                CGFloat bldgEMV = sqlite3_column_double(statement, 21);
                CGFloat totalEMV = sqlite3_column_double(statement, 22);
                CGFloat taxCapac = sqlite3_column_double(statement, 23);
                CGFloat totalTax = sqlite3_column_double(statement, 24);
                CGFloat specAsses = sqlite3_column_double(statement, 25);
                LPSTR saleDate = (LPSTR)sqlite3_column_text(statement, 26);
                CGFloat saleValue = sqlite3_column_double(statement, 27);
                LPSTR cenBlock = (LPSTR)sqlite3_column_text(statement,28);
                LPSTR taxName = (LPSTR)sqlite3_column_text(statement, 29);
                LPSTR homestead = (LPSTR)sqlite3_column_text(statement, 30);
                LPSTR ownerAdd1 = (LPSTR)sqlite3_column_text(statement, 31);
                LPSTR ownerAdd2 = (LPSTR)sqlite3_column_text(statement, 32);
                LPSTR ownerAdd3 = (LPSTR)sqlite3_column_text(statement, 33);
                LPSTR taxAdd1 = (LPSTR)sqlite3_column_text(statement, 34);
                LPSTR taxAdd2 = (LPSTR)sqlite3_column_text(statement, 35);
                LPSTR taxAdd3 = (LPSTR)sqlite3_column_text(statement, 36);
                int multiYearOffset = sqlite3_column_int(statement, 37);
                strcpy (censusBlock,cenBlock);
                NSNumberFormatter *dollarFmt = [[NSNumberFormatter alloc] init];
                dollarFmt.numberStyle = NSNumberFormatterCurrencyStyle;
                dollarFmt.groupingSeparator = @"'";
                dollarFmt.groupingSize = 3;
                dollarFmt.alwaysShowsDecimalSeparator = NO;
                dollarFmt.usesGroupingSeparator = YES;
                dollarFmt.maximumFractionDigits = 0;
                
                strncpy (usedesc,UseDesc1,31);
                usedesc[31] = 0;
                NSString *line;
                line = [NSString stringWithFormat:@"PIN:%@", pid];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"House Number: %s", house];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Street:%s", street];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Unit:%s", unit];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"City:%s", city];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Owner:%s", ownerName];
                [report addObject:line];
                line = [NSString stringWithFormat:@":%s", ownerAdd1];
                if (*ownerAdd1)   [report addObject:line];
                line = [NSString stringWithFormat:@":%s", ownerAdd2];
                if (*ownerAdd2)   [report addObject:line];
                line = [NSString stringWithFormat:@":%s", ownerAdd3];
                if (*ownerAdd3)   [report addObject:line];
                
                line = [NSString stringWithFormat:@"Taxpayer:%s", taxName];
                [report addObject:line];
                line = [NSString stringWithFormat:@":%s", taxAdd1];
                [report addObject:line];
                line = [NSString stringWithFormat:@":%s", taxAdd2];
                [report addObject:line];
                line = [NSString stringWithFormat:@":%s", taxAdd3];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Land EMV:%@", [dollarFmt stringFromNumber:[NSNumber numberWithInt:(int)landEMV]]];
                [report addObject:line];
                
                /* if (acresPoly > 0 && landEMV > 0)
                 {
                 line = [NSString stringWithFormat:@"Land EMV per Acre:%@", [dollarFmt stringFromNumber:[NSNumber numberWithInt:(int)landEMV/acresPoly]]];
                 [report addObject:line];
                 }
                 */
                line = [NSString stringWithFormat:@"Last Sale Date:%s", saleDate];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Sale Value:%@", [dollarFmt stringFromNumber:[NSNumber numberWithInt:(int)saleValue]]];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Building EMV:%@", [dollarFmt stringFromNumber:[NSNumber numberWithInt:(int)bldgEMV]]];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Total EMV:%@", [dollarFmt stringFromNumber:[NSNumber numberWithInt:(int)totalEMV]]];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Total Tax:%@", [dollarFmt stringFromNumber:[NSNumber numberWithInt:(int)totalTax]]];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Special Assessment:%@", [dollarFmt stringFromNumber:[NSNumber numberWithInt:(int)specAsses]]];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Tax Capacity:%@", [dollarFmt stringFromNumber:[NSNumber numberWithInt:(int)taxCapac]]];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Homestead:%s", homestead];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"City USPS:%s", cityUSPS];
                [report addObject:line];
                
                if (*zip4)
                    line = [NSString stringWithFormat:@"Zipcode:%s-%s", zipcode,zip4];
                else
                    line = [NSString stringWithFormat:@"Zipcode:%s", zipcode];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Plat:%s", platName];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Block:%s", block];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Lot:%s", lot];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Acres:%.2f (deed) %.2f (map)", acresDeed,acresPoly];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Use Desc1:%s", UseDesc1];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Use Desc2:%s", UseDesc2];
                if (*UseDesc2)[report addObject:line];
                
                line = [NSString stringWithFormat:@"Use Desc3:%s", UseDesc3];
                if (*UseDesc3)[report addObject:line];
                
                line = [NSString stringWithFormat:@"Use Desc4:%s", UseDesc4];
                if (*UseDesc4)[report addObject:line];
                
                line = [NSString stringWithFormat:@"Multi Uses:%s", multiUses];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Landmark:%s", landMark];
                [report addObject:line];
                
                //SQLOKpd(sqlite3_finalize(statement),_database, 57);
                
                DATA_FROM_TABLES values;
                [self computeValuesFromTables:&values
                                 inCensusArea:(LPSTR)censusBlock
                                       totEMV:(int)totalEMV
                                      useDesc:(LPSTR)usedesc];
                
                line = [NSString stringWithFormat:@"Stability:%.i%%", values.stability5yr];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Percent Commercial:%i%%", values.pctHomestead];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"EMV Rank:%i%%", values.rankTotEMV];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Census Block:%s", cenBlock];
                [report addObject:line];
            }
            
            SQLOKpd(sqlite3_finalize(statement), _database, 58);
        }
    }
    
    [self close:opened];
    return report;
}

#define MAXHITS 4096
#define MAXOFFSETS 262136L
#define	MAXWIOFFSETS 100
#define MAXPARTS 32

typedef struct	{char Word[8];
    short Seq;
    short nOffsets;
    long Offsets[MAXWIOFFSETS];} WORDINDEX;
typedef WORDINDEX *LPWORDINDEX;

int GetWIHits(LPINT Hits, int nParts, LPINT nPartOffsets, LPINT *pPartOffsets, int MaxHits)
{
    int	nHits = 0;
    int	Order[32];
    int	i, j, k, ihit, ipart, nValidParts = 0;
    //int ii;
    LPINT pOff1, pOff2;
    BOOL HaveHit;
    
    Order[0] = 0;
    
    for (ipart = 1; ipart < nParts; ipart++)
    {
        for (i = 0; i < ipart; i++)
        {
            if (nPartOffsets[ipart] < nPartOffsets[Order[i]])
            {
                for (j = ipart; j > i; j--)
                    Order[j] = Order[j - 1];
                
                Order[i] = ipart;
                goto Inserted;
            }
        }
        
        Order[ipart] = ipart;
        
    Inserted:;
    }
    
    for (ipart = 0; ipart < nParts; ipart++)
    {
        if (nPartOffsets[ipart] < INT_MAX)
            nValidParts++;
    }
    
    if (!nValidParts)
        return 0;
    
    pOff1 = pPartOffsets[Order[0]];
    
    for (i = 0; i < nPartOffsets[Order[0]]; i++)
    {
        HaveHit = TRUE;
        
        for (j = 1; j < nValidParts; j++)
        {
            pOff2 = pPartOffsets[Order[j]];
            
            for (k = 0; k < nPartOffsets[Order[j]] ;k++)
            {
                if (*pOff1 == *pOff2++)
                    goto Next;
            }
            
            HaveHit = FALSE;
            
        Next:
            if (!HaveHit)
                goto NextOff;
        }
        
        if (nHits >= MaxHits)
            break;
        
        for (ihit = 0; ihit < nHits; ihit++)
        {
            if (Hits[ihit] == *pOff1)
                goto NextOff;
        }
        
        Hits[nHits++] = *pOff1;
        
        //if (!*pOff1)
        //ii = 1;
        
    NextOff:
        pOff1++;
        // if (GSSiPeekMessage(&msg,hwndCtl,WM_KEYDOWN,WM_KEYDOWN,PM_NOREMOVE))
        //     break;
    }
    
    return nHits;
}

- (BOOL)getOwnersMatchingString:(NSString *)INstring
                        limitTo:(LimitToOption)limitTo
{
    if (!INstring)
        return FALSE;
    dispatch_queue_t ownerQueue;
    ownerQueue = dispatch_queue_create(NULL, NULL);
    dispatch_async(ownerQueue,
                   ^{
    
    NSMutableArray *ownerArray = [[NSMutableArray alloc] init];
    int	nParts, ipart, iparttest;
    //int nOwners;
    //LPWORDINDEX	pRec;
    //WORDINDEX Rec;
    LPINT partOffsets[MAXPARTS], partoff;
    int nPartOffsets[MAXPARTS], PartLen[MAXPARTS], PartLenTest[MAXPARTS];
    LPSTR PartLoc[MAXPARTS], PartLocTest[MAXPARTS];
    int Trigger = 1, nHits = 0;
    //int nowner;
    BOOL GetNext = TRUE;
    char Name[66];
    NSString * cityName = @"";
    sqlite3_stmt *statement = NULL;
    
    NSString *string = INstring.uppercaseString;
    strncpy(Name, string.UTF8String, 64);
    nParts = GetNameParts(Name, PartLoc, PartLen, MAXPARTS);
    
    if (nParts)
    {
    for (ipart = 0; ipart < nParts; ipart++)
    {
        nPartOffsets[ipart] = 0;
        partOffsets[ipart] = 0;
    }
    
    for (ipart = 0; ipart < nParts; ipart++)
    {
        if (PartLen[ipart] >= Trigger)
        {
            char endWord[12] = {0};
            char begWord[12] = {0};
            [self open];
            
            strncpy (begWord, PartLoc[ipart], 8);
            strncpy (endWord, PartLoc[ipart], 8);
            for (int i= (int)strlen(begWord); i < 11; i++)
                endWord[i] = 'Z';
            
            endWord[11] = 0;
            
            NSString *query = [NSString stringWithFormat:@"SELECT Word,NOFFSETS,OFFSETS FROM NAMEINDEX WHERE Word >='%s' AND Word < '%s'",
                               begWord,endWord];
            
            SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database, 59);
            
            while ([self continue] && sqlite3_step(statement) == SQLITE_ROW)
            {
                LPSTR word = (LPSTR)sqlite3_column_text(statement, 0);
                int nOffsets = sqlite3_column_int(statement,1);
                LPINT pOffsets = (LPINT)sqlite3_column_blob(statement, 2);
                
                if (nPartOffsets[ipart] + nOffsets >= MAXOFFSETS)
                    GetNext = FALSE;
                
                else
                {
                    partOffsets[ipart] = realloc(partOffsets[ipart], (nPartOffsets[ipart]+nOffsets)*sizeof(int));
                    partoff = partOffsets[ipart] + nPartOffsets[ipart];
                    memmove (partoff,pOffsets,nOffsets*sizeof(int));
                    nPartOffsets[ipart] += nOffsets;
                }
            }
            
            SQLOKpd(sqlite3_finalize(statement), _database, 60);
            
            if (!nPartOffsets[ipart])
                GetNext = FALSE;
        }
        
        else
            nPartOffsets[ipart] = INT_MAX;
    }
    
   LPINT Hits = malloc(MAXHITS * sizeof(int));
   if ([self continue] && GetNext)
        nHits = GetWIHits (Hits, nParts, nPartOffsets, partOffsets, MAXHITS);
    
    for (ipart = 0; ipart < nParts; ipart++)
    {
        if (partOffsets[ipart])
            free (partOffsets[ipart]);
    }
    
    if (nHits)
    {
        NSString *inList=[[NSString alloc] init];
        char delim = 0;
        
        for (int i = 0; i < nHits; i++)
        {
            inList = [inList stringByAppendingString:[NSString stringWithFormat:@"%c%i", delim, Hits[i]]];
            delim = ',';
        }
        
        NSString *query = [NSString stringWithFormat:@"SELECT PIN,OWNER_NAME,TAX_NAME,BLDG_NUM,STREETNAME,CITY, LATITUDE, LONGITUDE, OWNER_MORE,TAX_NAME FROM PROPINFO WHERE id IN(%@)",
                           inList];
        BoundaryData * bd = BoundaryData.new;
        SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database, 61);
        
        while ([self continue] && sqlite3_step(statement) == SQLITE_ROW)
        {
            LPSTR pin = (LPSTR)sqlite3_column_text(statement, 0);
            LPSTR owner = (LPSTR)sqlite3_column_text(statement,1);
            LPSTR taxpayer = (LPSTR)sqlite3_column_text(statement,2);
            LPSTR house = (LPSTR)sqlite3_column_text(statement,3);
            LPSTR street = (LPSTR)sqlite3_column_text(statement,4);
            LPSTR city = (LPSTR)sqlite3_column_text(statement,5);
            cityName = [NSString stringWithUTF8String:city];
            double lat = sqlite3_column_double(statement,6);
            double lon = sqlite3_column_double(statement,7);
            char testName[256];
            strcpy(testName,owner);
            int nPartsTest = GetNameParts(testName, PartLocTest, PartLenTest, MAXPARTS);
            int ShowThisOwner = 1;
            
            for (ipart = 0; ipart < nParts; ipart++)
            {
                for (iparttest = 0; iparttest <nPartsTest; iparttest++)
                {
                    if (!strncasecmp (PartLoc[ipart], PartLocTest[iparttest], PartLen[ipart]))
                    {
                        *PartLocTest[iparttest] = 0;
                        goto FoundPart;
                    }
                }
                
                ShowThisOwner = 0;
                break;
                
            FoundPart:;
            }
            if (!ShowThisOwner)
            {
                strcpy(testName,taxpayer);
                nPartsTest = GetNameParts(testName, PartLocTest, PartLenTest, MAXPARTS);
                ShowThisOwner = 2;
                
                for (ipart = 0; ipart < nParts; ipart++)
                {
                    for (iparttest = 0; iparttest <nPartsTest; iparttest++)
                    {
                        if (!strncasecmp (PartLoc[ipart], PartLocTest[iparttest], PartLen[ipart]))
                        {
                            *PartLocTest[iparttest] = 0;
                            goto FoundPart2;
                        }
                    }
                    
                    ShowThisOwner = 0;
                    break;
                    
                FoundPart2:;
                }

            }
            if (ShowThisOwner)
            {
                LLPOINT llpt;
                llpt.lat = lat;
                llpt.lon = lon;
                /*PickedItem *pi = [bd pickBoundaryArea:llpt type:@"Cities And Townships"];
                if (pi)
                    cityName = pi.identifier;*/
            }
            if (ShowThisOwner == 1)
            {
                NSString *name = [[NSString stringWithUTF8String:owner] stringByReplacingOccurrencesOfString:@"," withString:@""];
                NSString *output = [NSString stringWithFormat:@"%@\t%s\t%s %s, %@",
                                    name, pin, house, street, cityName];
                if ([self checkLimits:limitTo PIN:pin City:(LPSTR)cityName.UTF8String])
                    [ownerArray addObject:output];
            }
            if (ShowThisOwner == 2)
            {
                NSString *name = [[NSString stringWithUTF8String:taxpayer] stringByReplacingOccurrencesOfString:@"," withString:@""];
                NSString *output = [NSString stringWithFormat:@"%@\t%s\t%s %s, %s",
                                   name, pin, house, street, cityName.UTF8String];
                
                if ([self checkLimits:limitTo PIN:pin City:city])
                    [ownerArray addObject:output];
            }
        }
        
        SQLOKpd(sqlite3_finalize(statement), _database, 62);
    }
    free (Hits);
    [self close:25];
    if ([self continue] && _delegate)
        [_delegate matchingOwners:[ownerArray.copy sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];
    }
                   });
    return TRUE;
}

- (BOOL) checkLimits:(LimitToOption)limitTo PIN:(LPSTR)pinC City:(LPSTR)cityC
{
    NSString *pin = [NSString stringWithUTF8String:pinC];
    NSString *city = [NSString stringWithUTF8String:cityC];
    if (limitTo == LimitToOptionNoLimit)
        return YES;
    NSString *county = textBefore(pin, @"-");
    if (limitTo == LimitToOptionCurrentCounty)
    {
        if ([county isEqualToString:CRAPI.sharedInstance.currentCounty])
            return YES;
    }
    if (limitTo == LimitToOptionCurrentCity)
    {
        NSString * curCity = [CRAPI.sharedInstance.currentCity uppercaseString];
        if ([[city uppercaseString] isEqualToString:curCity])
            return YES;
    }
    if (limitTo == LimitToOptionMapBounds)
    {
        MNMXCORD parcelBounds = [self getBoundsForPID:pin];
        MNMXCORD displayBounds = CRAPI.sharedInstance.lastDisplayBounds;
        if (BoundsInBounds(&parcelBounds, &displayBounds,1))
            return YES;
    }
    return NO;
}
int GetNameParts(LPSTR Field, LPSTR *pLoc, LPINT pLen, int MaxParts)
{
    int	nParts = 0;
    LPSTR pWord, pEnd;
    
    pWord = Field;
    ReplaceChar(Field,'-',' ');
    ReplaceChar(Field,'/',' ');
    ReplaceChar(Field,'(',' ');
    ReplaceChar(Field,')',' ');
    ReplaceChar(Field,'&',' ');
    ReplaceChar(Field,',',' ');
    ReplaceChar(Field,'\'',' ');
    ReplaceChar(Field,'#',' ');
    ReplaceChar(Field,'"',' ');
    ReplaceChar(Field,'.',' ');
    OneSpace(Field);
    
    while (*pWord && nParts < MaxParts)
    {
        if (*pWord == ' ')
            pWord++;
        
        if ((pEnd = strchr (pWord,' ')))
            *pEnd++ = 0;
        
        else
            pEnd = strchr (pWord,0);
        
        *(pLoc + nParts) = pWord;
        *(pLen + nParts++) = (int)strlen(pWord);
        pWord = pEnd;
    }
    
    return nParts;
}
@end












