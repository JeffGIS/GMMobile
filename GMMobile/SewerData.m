//
//  SewerData.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 2/15/15.
//  Copyright (c) 2015 GSSi. All rights reserved.
//
#import "SewerData.h"
#define COORDINATE_FACTOR 10000000.0

@interface SewerData ()

@property (nonatomic) GSSiPopoverView *popover;

@end

@implementation SewerData

static SewerData *_sewerData;

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
        
    }
    
    return self;
}

- (void)dealloc
{
    CloseTRANS2 (&_pTranLLtoView);
    CloseTRANS2 (&_pTranViewtoLL);
    sqlite3_close(_database);
    NSLog(@"Sewer Database dealloc");
}

- (void)open
{
    if (!_isOpen)
    {
        self.isOpen = !SQLOKswr(sqlite3_open(self.path.UTF8String, &_database), "open(Sewer)");
        NSLog(@"Sewer Database open");
        
        _fileSize = [NSFileManager.defaultManager attributesOfItemAtPath:_path
                                                                   error:nil].fileSize;
    }
}

- (void)close
{
    SQLOKswr(sqlite3_close(_database),"Close");
    NSLog(@"Sewer Database close");
    self.isOpen = NO;
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
- (NSString*) getActualPlatFileName:(NSString*)platID
{
    NSString * outName;
    char name[128];
    strncpy (name,platID.UTF8String,126);
    LPSTR pU = strrchr (name,'_');
    if (pU)
        *pU = 0;
    outName = [NSString stringWithUTF8String:name];
    return outName;
}

- (BOOL)loadPlat:(NSString *)platID usingPopover:(GSSiPopoverView*)popover andDelegate:(id)delegate
{
    BOOL fileExists;
    NSString *actualPlatID = [self getActualPlatFileName:platID];
    NSString *toDir = [NSString stringWithFormat:@"%@/SanPlats",_documentsDirectory];
    NSString *fileName = [NSString stringWithFormat:@"%@.jpg",actualPlatID];
    FTPDataPull *pull = FTPDataPull.pull;
    pull.delegate = delegate;
    pull.popover = _popover;
    pull.useOnlyPrimaryFTP = YES;
    pull.option = GET_SANPLAT;
    //pull.ipAddress = http://74.42.137.128/icons/MPLS/;
    
    [popover showAfter:0.5
              withTitle:[NSString stringWithFormat:@"Get Sanitary Plat %@",actualPlatID]];
    pull.ftpSiteOveride = @"74.42.137.128";
    pull.usernameOveride = @"GMMobile";
    pull.passwordOveride = @"GeoMaster";
    pull.portOveride = @"21";
    pull.createDirectory = YES;
    pull.returnIfExists = NO;
    if ([pull getFile:fileName
    fromDirectory:@"Sewer/Sanitary/Plats"
           toFile:fileName
      toDirectory:toDir
     forceRefresh:NO] == FTPStatusFileExists)
        return YES;
    return NO;
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

- (NSString*) getSanPlatIDFromRefno:(int)refno
{
    NSString* platID = [[NSString alloc]init];
    
    return platID;
}

- (int)pickSanPlat:(LLPOINT *)pt
{
    int minRef=0;
    dbounds bnds;
    CGFloat d, mind = DBL_MAX;
    CGFloat pickap = 0.005;
    DPOINT p1, p2, minpt;
    NSString * minPlatID=[[NSString alloc]init];;
    
    p1.x = pt->lon;
    p1.y = pt->lat;
    minpt = p1;
    bnds.xmn = p1.x - pickap;
    bnds.xmx = p1.x + pickap;
    bnds.ymn = p1.y - pickap;
    bnds.ymx = p1.y + pickap;
    [self open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT SANPLATAREAS.id, SANPLATAREAS.PLAT, BasePointX, BasePointY FROM SANPLATAREAS,SANPLATAREAS_index WHERE SANPLATAREAS.id=SANPLATAREAS_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                       bnds.xmn, bnds.xmx, bnds.ymn, bnds.ymx];
    
    sqlite3_stmt *statement;
    
    SQLOKswr(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "preparePickPLAT");
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        int refno = sqlite3_column_int(statement, 0);
        LPSTR platID = (LPSTR)sqlite3_column_text(statement, 1);
        CGFloat lat = sqlite3_column_double(statement, 2);
        CGFloat lon = sqlite3_column_double(statement, 3);
        p2.x = lon;
        p2.y = lat;
        d = ArcDistance(p1, p2);
        
        if (d < mind)
        {
            mind = d;
            minpt = p2;
            minRef = refno;
            minPlatID = [NSString stringWithUTF8String:platID];
        }
    }
    
    SQLOKswr(sqlite3_finalize(statement), "pickPLAT");
    [self close];
    pt->lon = minpt.x;
    pt->lat = minpt.y;
    return minRef;
}
- (NSMutableArray*) getAllSanPlats
{
    NSMutableArray * list=[[NSMutableArray alloc]init];
    [self open];
    
    NSString *query = @"SELECT PLAT FROM SANPLATAREAS";
    
    sqlite3_stmt *statement;
    
    SQLOKswr(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "getAllSanPlats");
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR platID = (LPSTR)sqlite3_column_text(statement, 0);
        NSString * plat = [NSString stringWithUTF8String:platID];
        [list addObject:plat];
    }
    
    SQLOKswr(sqlite3_finalize(statement), "pickPLAT");
    [self close];
    return list;
}

@end
