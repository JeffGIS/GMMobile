//
//  AlleyWallData.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 4/26/15.
//  Copyright (c) 2015 GSSi. All rights reserved.
//
extern int keepProcessing;
static int fileSequence = 0;
#define COORDINATE_FACTOR 10000000.0

#import "AlleyWallData.h"

@implementation AlleyWallData


int SQLOKawd(int sqlReturn, sqlite3 *database)
{
    if (sqlReturn != SQLITE_OK)
    {
        //[self logError:sqlReturn
        //             method:database];
        NSLog(@"%@", [NSString stringWithFormat:@"SQLite Error %i = %i:%s",
                      sqlReturn, sqlite3_errcode(database), sqlite3_errmsg(database)]);
    }
    
    return sqlReturn;
}

- (void)logError:(int)sqlReturn
          method:(sqlite3*)database
{
    NSLog(@"%@", [NSString stringWithFormat:@"SQLite Error %i = %i:%s",
                  sqlReturn, sqlite3_errcode(database), sqlite3_errmsg(database)]);
}

- (BOOL) continue
{
    if (self.processingID == keepProcessing)
        return YES;
    return NO;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _documentsDirectory = UserDefaults.defaults.sharedFilePath;
        _fileName = @"AlleyWalls.sqlite";
        _path = [NSString stringWithFormat:@"%@/%@", _documentsDirectory, _fileName];
        
    }
    
    return self;
}

- (void)dealloc
{
    sqlite3_close(_database);
    NSLog(@"AlleyWall Database dealloc");
}
- (void)open
{
    if (!_isOpen)
    {
        self.isOpen = YES;
        self.isOpen = !SQLOKawd(sqlite3_open(self.path.UTF8String, &_database), _database);
        NSLog(@"AlleyWall Database open");
        
        _fileSize = [NSFileManager.defaultManager attributesOfItemAtPath:_path
                                                                   error:nil].fileSize;
    }
}

- (void)close
{
    SQLOKawd(sqlite3_close(_database),_database);
    NSLog(@"AlleyWall Database close");
    self.isOpen = NO;
}

- (void)clear
{
    [self close];
    
    //BOOL st = [NSFileManager.defaultManager removeItemAtPath:_path
    //error:nil];
}
- (int) datasetVersion
{
    int rtn = -1;
    [self open];
    if (_isOpen && _fileSize > 0)
    {
        NSString *query = [NSString stringWithFormat:@"SELECT max(Version) FROM ALLEYWALLS_VERSION"];
        
        sqlite3_stmt *statement = NULL;
        
        SQLOKawd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
        if (sqlite3_step(statement) == SQLITE_ROW)
        {
            LPSTR version = (LPSTR)sqlite3_column_text(statement, 0);
            if (version)
            {
                rtn = atoi (version);
            }
        }
        SQLOKawd(sqlite3_finalize(statement), _database);
    }
    [self close];
    return rtn;
}

- (BOOL)executeCmd:(char *)cmd
      sendToServer:(BOOL)sendToServer
     useUniqueFile:(BOOL)uniqueFile
{
    BOOL rtn = !SQLOKawd(sqlite3_exec(_database, cmd, 0, 0, 0), _database);
    if (rtn && sendToServer)
    {
        if (uniqueFile || !_sendToServerFile)
        {
            int iTime = NSDate.timeIntervalSinceReferenceDate;
            _sendToServerFile = [NSString stringWithFormat:@"%@/AlleyWallInventory_SQL_%i-%i.txt",
                                        CRAPI.sharedInstance.sharedOutputDirectory,iTime,fileSequence++];
            rtn = [[NSString stringWithUTF8String:cmd] writeToFile:_sendToServerFile
                                                        atomically:YES
                                                          encoding:NSUTF8StringEncoding
                                                             error:nil];
        }
        else
        {
            [CRAPI.sharedInstance appendString:[NSString stringWithUTF8String:cmd] toFile:_sendToServerFile];
        }
    }
    return rtn;
}

- (void)startTransaction
{
    [self open];
    SQLOKawd(sqlite3_exec(_database, "BEGIN", 0, 0, 0), _database);
}

- (void)commitTransaction
{
    SQLOKawd(sqlite3_exec(_database, "COMMIT", 0, 0, 0), _database);
}

- (int)getAlleyLineStatus:(NSInteger)refno
{
    int status = 0;
    [self open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT ALLEY_LINE.CHECKED FROM ALLEY_LINE WHERE  ALLEY_LINE.id=%li",(long)refno];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOKawd(sqlite3_prepare_v2(self.database, query.UTF8String, -1, &statement,0), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        int checked = sqlite3_column_int(statement, 0);
        status = checked;
    }
    
    SQLOKawd(sqlite3_finalize(statement), _database);
    [self close];
    
    return status;
}

- (int)getAlleyLineSeg:(NSInteger)refno
{
    int segid = 0;
    [self open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT ALLEY_LINE.SEGID FROM ALLEY_LINE WHERE  ALLEY_LINE.id=%li",(long)refno];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOKawd(sqlite3_prepare_v2(self.database, query.UTF8String, -1, &statement,0), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        segid = sqlite3_column_int(statement, 0);
    }
    
    SQLOKawd(sqlite3_finalize(statement), _database);
    [self close];
    
    return segid;
}

- (void)setAlleyLineStatus:(NSInteger)refno
                        to:(int)status
{
    BOOL rtn;
    int iTime = NSDate.timeIntervalSinceReferenceDate;
    int segid = [self getAlleyLineSeg:refno];
    NSString *outputDataPath = [NSString stringWithFormat:@"%@/AlleyWallInventory_Alley_%i_%i.txt",
                                CRAPI.sharedInstance.outputDirectory, segid,iTime];
    NSMutableString *outData = [[NSMutableString alloc]init];
    [outData appendString:[NSString stringWithFormat:@"$GMDUPDATE([ALLEYSEGFILE],SEGID=%i,Status=%i;LastUpdate=%i,",segid,status,iTime]];
    [outData appendString:@");"];
    rtn = [outData writeToFile:outputDataPath
                    atomically:YES
                      encoding:NSUTF8StringEncoding
                         error:nil];
    [self open];
    NSString *cmd = [NSString stringWithFormat:@"UPDATE ALLEY_LINE SET CHECKED = %i, LastUpdate = %i WHERE id=%ld",status,iTime,(long)refno];
    [self executeCmd:(LPSTR)cmd.UTF8String
        sendToServer:YES
     useUniqueFile:YES];
    [self close];
}

- (BOOL)deleteAlleyWallPoint:(NSInteger)refno;
{
    int iTime = NSDate.timeIntervalSinceReferenceDate;
    BOOL rtn = NO;
    [self open];
    
    NSString *cmd = [NSString stringWithFormat:@"UPDATE ALLEYWALLS_NEW SET Current = 0, Deleted = 1, LastUpdate = %i WHERE id=%ld",
                     iTime, (long)refno];
    
    rtn = [self executeCmd:(LPSTR)cmd.UTF8String
              sendToServer:YES
             useUniqueFile:YES];
    
    [self close];
    return rtn;
}

- (BOOL)moveAlleyWallPoint:(NSInteger)refno
                        to:(CLLocationCoordinate2D)point
{
    BOOL rtn = FALSE;
    int iTime = NSDate.timeIntervalSinceReferenceDate;
    AlleyWallData *pd = [[AlleyWallData alloc] init];
    [pd open];
    
    NSString *query = [NSString stringWithFormat:@"UPDATE ALLEYWALLS_NEW SET LATITUDE = %f,LONGITUDE = %f,LastUpdate = %i WHERE id=%ld",
                       point.latitude,point.longitude, iTime,(long)refno];
    
    rtn = sqlite3_exec(pd.database, query.UTF8String, NULL, NULL, NULL);
    
    if (!rtn)
    {
        query = [NSString stringWithFormat:@"UPDATE ALLEYWALLS_NEW_index SET minY=%f,minX=%f,maxY=%f,maxX=%f WHERE ALLEYWALLS_NEW_index.id=%ld",
                 point.latitude,point.longitude, point.latitude,point.longitude, (long)refno];
        
        rtn = sqlite3_exec(pd.database, query.UTF8String, NULL, NULL, NULL);
    }
    
    [pd close];
    return !rtn;
}

- (BOOL)createNewWall:(NSString *)wallID
              atPoint:(CLLocationCoordinate2D)position
            withHouse:(NSString *)house
            andStreet:(NSString *)street
{
/*    INSERT INTO ALLEYWALLS VALUES(1,'6119.1',3536,'10TH AVE S','Yes',100.000000,2.000000,6.500000,'',' $20,000.00 ','CONCBLOCK  POURED','1/27/1987','MB','7','GOOD.  MINOR CRACKS.  ',-93.260388,44.938210,1,0)
    INSERT INTO ALLEYWALLS_index VALUES(2,-93.260613,-93.260613,44.936725,44.936725);
SELECT max(_id) FROM MyTable*/
    BOOL rtn=FALSE;
    int iTime = NSDate.timeIntervalSinceReferenceDate;
    NSInteger refno=0;
    NSInteger iHouse = [house integerValue];
    [self open];
    NSString *query = [NSString stringWithFormat:@"SELECT max(id) FROM ALLEYWALLS_NEW"];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOKawd(sqlite3_prepare_v2(self.database, query.UTF8String, -1, &statement, 0), _database);
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        refno = sqlite3_column_int(statement, 0);
        refno = [CRAPI.sharedInstance adjustNextRefno:refno];
    }
    SQLOKawd(sqlite3_finalize(statement), _database);
   
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.timeStyle = NSDateFormatterNoStyle;
    dateFormatter.dateStyle = NSDateFormatterShortStyle;
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *today = [dateFormatter stringFromDate:[[NSDate alloc] init]];
    
    NSString *cmd = [NSString stringWithFormat:@"INSERT INTO ALLEYWALLS_NEW([id],[Wall ID],[Hse No],[STREET],[InspDate],[Current],[LONGITUDE],[LATITUDE],[LastUpdate]) VALUES(%ld,'%@',%ld,'%@','%@',1,%f,%f,%i);",(long)refno,wallID,(long)iHouse,street,today,position.longitude,position.latitude,iTime];
    rtn = [self executeCmd:(LPSTR)cmd.UTF8String
              sendToServer:YES
             useUniqueFile:YES];
    cmd = [NSString stringWithFormat:@"INSERT INTO ALLEYWALLS_NEW_index VALUES(%ld,%f,%f,%f,%f)",(long)refno,position.longitude,position.longitude,position.latitude,position.latitude];
    rtn = [self executeCmd:(LPSTR)cmd.UTF8String
              sendToServer:YES
             useUniqueFile:NO];
    [self close];
    return rtn;
}
//CREATE TABLE ALLEYWALLS ('id' INT,'Wall ID' CHAR(8),'Hse No' INT,'STREET' CHAR(64),'City' CHAR(4),'Length' REAL,'Max Hght' REAL,'Offset' REAL,'Gar/Struc' CHAR(12),' COST' CHAR(12),'Type Const' CHAR(32),'InspDate' CHAR(12),'InspBy' CHAR(8),'Rating' CHAR(16),'Comments' CHAR(255),'LONGITUDE' REAL,'LATITUDE' REAL,PRIMARY KEY('id' ASC))

-(NSString*)nearestAlleyLine:(CLLocationCoordinate2D*)pt
{
    int nPicked = 0;
    CGFloat mind = DBL_MAX;
    DPOINT p1, pickedPoint, minpt, BasePt;
    NSString *minFid = @"";
    int minref = 0;
    int numPoints;
    
    p1.x = pt->longitude;
    p1.y = pt->latitude;
    minpt = p1;
    dbounds bnds = [CRAPI.sharedInstance getBoundsAtPoint:pt andDist:20];
    [self open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT ALLEY_LINE.id, ALLEY_LINE.ALLEYSEG, BasePointX, BasePointY,NumPoints,NumLoops,PolyPartLen,Points  FROM ALLEY_LINE,ALLEY_LINE_index WHERE  ALLEY_LINE.id=ALLEY_LINE_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                       bnds.xmn, bnds.xmx, bnds.ymn, bnds.ymx];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOKawd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        int refno = sqlite3_column_int(statement, 0);
        LPSTR ALLEYSEG = (LPSTR)sqlite3_column_text(statement, 1);
        NSInteger iALLEYSEG = sqlite3_column_int(statement, 1);
        BasePt.x = sqlite3_column_double(statement, 2);
        BasePt.y = sqlite3_column_double(statement, 3);
        numPoints = sqlite3_column_int(statement,4);
        LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement,7);
        
        LPDPOINT llpoints = malloc(abs(numPoints) * sizeof(DPOINT) + 4);
        
        if (numPoints < 0)
        {
            numPoints = -numPoints;
            LPSPOINT offsetPoints16 = (LPSPOINT)offsetPoints;
            
            for (int i = 0; i < numPoints; i++)
            {
                llpoints[i].x = (BasePt.x + offsetPoints16[i].x / COORDINATE_FACTOR);
                llpoints[i].y = (BasePt.y + offsetPoints16[i].y / COORDINATE_FACTOR);
            }
        }
        
        else for (int i = 0; i < numPoints; i++)
        {
            llpoints[i].x = (BasePt.x + offsetPoints[i].x / COORDINATE_FACTOR);
            llpoints[i].y = (BasePt.y + offsetPoints[i].y / COORDINATE_FACTOR);
        }
        
        if (PICK_POINT_ON_LINE(p1, bnds, &pickedPoint, numPoints, llpoints))
        {
            if (findClosestPoint (&pickedPoint, &minpt, &mind, &p1))
            {
                nPicked++;
                minref = refno;
                minFid = [NSString stringWithUTF8String:ALLEYSEG];
            }
        }
        free (llpoints);
    }
    
    SQLOKawd(sqlite3_finalize(statement),_database);
    [self close];
    pt->longitude = minpt.x;
    pt->latitude = minpt.y;

    return minFid;
}

- (NSString *)getNextWallForAlley:(NSString *)nearestAlley
{
    NSString *nextWall = @"";
    CGFloat maxWall = 0;
    [self open];
    
    if ([nearestAlley isEqualToString:@""])
        return @"";
    
    NSString *minID = [[nearestAlley substringToIndex:4] stringByAppendingString:@".0"];
    NSString *maxID = [[nearestAlley substringToIndex:4] stringByAppendingString:@".99"];
    NSString *query = [NSString stringWithFormat:@"SELECT [Wall ID] FROM ALLEYWALLS_NEW WHERE  [Wall ID] >= %@ AND [Wall ID] <= %@",minID,maxID];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOKawd(sqlite3_prepare_v2(self.database, query.UTF8String, -1, &statement, 0), _database);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR wallID = (LPSTR)sqlite3_column_text(statement, 0);
        CGFloat fWall = atof (wallID);
        NSInteger iWall = fWall;
        
        if (strlen (wallID)<7)
            fWall = iWall + (fWall - iWall)/10.0;
        
        maxWall = max (fWall,maxWall);
    }
    
    SQLOKawd(sqlite3_finalize(statement), _database);
    [self close];
    
    if (maxWall < 1)
        nextWall = [[nearestAlley substringToIndex:4] stringByAppendingString:@".01"];
    
    else
        nextWall = [NSString stringWithFormat:@"%.2f",maxWall + 0.01];
    
    return nextWall;
}
- (BOOL)createNewTable:(BOOL)sendToServer
{
    BOOL rtn = TRUE;
    NSString * cmd = @"\
    DROP TABLE IF EXISTS ALLEYWALLS_VERSION;\
    CREATE TABLE ALLEYWALLS_VERSION ('Version' CHAR(16));\
    INSERT INTO ALLEYWALLS_VERSION ([VERSION]) VALUES ('1.0');\
    DROP TABLE IF EXISTS ALLEYWALLS_NEW;\
    DROP TABLE IF EXISTS ALLEYWALLS_NEW_index;\
    CREATE VIRTUAL TABLE ALLEYWALLS_NEW_index USING rtree(id,minX, maxX, minY, maxY);\
    DROP TABLE IF EXISTS ALLEYWALL_SEGS;\
    CREATE TABLE IF NOT EXISTS ALLEYWALLS_NEW (\
        'id' INT,\
        'Wall ID' CHAR(8),\
        'InspDate' CHAR(12),\
        'InspBy' CHAR(16),\
        'Current' INT,\
        'LastUpdate' INT,\
        'Deleted' INT,\
        'Complete' INT,\
        'Version' CHAR(16),\
        'Hse No' INT,\
        'STREET' CHAR(64),\
        'CityStamp' CHAR(32),\
        'Photos' INT,\
        'BEARING' REAL,\
        'GroundCoverBehindWall' CHAR(255),\
        'VisibleWeepHoles' CHAR(4),\
        'HistAndConstYear' CHAR(255),\
        'StructuresInWall' CHAR(255),\
        'ItemsBehindWall' CHAR(255),\
        'SoilSurcharge' REAL,\
        'Deficiency' CHAR(255),\
        'Rating' INT,\
        'NumSegments' INT,\
        'Comments' CHAR(255),\
        'LONGITUDE' REAL,\
        'LATITUDE' REAL,\
        PRIMARY KEY('Wall ID','InspDate'));\
    CREATE TABLE IF NOT EXISTS ALLEYWALL_SEGS(\
        'Wall ID' CHAR(8),\
        'InspDate' CHAR(12),\
        'SEGMENT' INT,\
        'SegmentLength' REAL,\
        'SegmentMaxHeight' REAL,\
        'SegmentOffset' REAL,\
        'TypeConst' CHAR(32),\
        'SegmentPlumbness' REAL,\
        'PlumbnessDistance' REAL,\
        PRIMARY KEY('Wall ID','InspDate','SEGMENT'));";
    if (sendToServer)
        [CRAPI.sharedInstance clearOutputDirectory];
    [self executeCmd:(char *)cmd.UTF8String
        sendToServer:sendToServer
       useUniqueFile:YES];
    return rtn;
}
-(BOOL)transferExistingTableIntoNewTable:(BOOL)sendToServer
{
    BOOL rtn=FALSE;

    [self startTransaction];
    NSString *query = @"SELECT * FROM ALLEYWALLS;";
    
    sqlite3_stmt *statement = NULL;
    
    SQLOKawd(sqlite3_prepare_v2(self.database, query.UTF8String, -1, &statement, 0), _database);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        NSString * newNames = @"";
        NSString * newVals = @"";
        NSString * delim = @"";
        NSString * newSegNames = @"";
        NSString * newSegVals = @"";
        NSString * segdelim = @"";
        int iref=0;
        double longitude=0,latitude=0;
        
        int ncol = sqlite3_column_count(statement);
        for (int icol = 0;icol<ncol;icol++)
        {
            int isSegField = 0;
            LPSTR pFieldName = (LPSTR)sqlite3_column_name(statement,icol);
            LPSTR pVal = (LPSTR)sqlite3_column_text(statement, icol);
            NSString * val = [NSString stringWithUTF8String:pVal];
            val = [val stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
            if (!strcmp (pFieldName,"Gar/Struc") || !strcmp(pFieldName," COST"))
                continue;
            NSString * fname = [NSString stringWithUTF8String:pFieldName];
            if (!strcmp (pFieldName,"Wall ID"))
            {
                isSegField = 2;
            }
            if (!strcmp (pFieldName,"InspDate"))
            {
                isSegField = 2;
                NSArray *array = [val componentsSeparatedByString:@"/"];
                if ([array count] == 3)
                    val = [NSString stringWithFormat:@"%@-%2.2li-%2.2li",array[2],(long)[array[0] integerValue],(long)[array[1] integerValue]];
                else
                    val = @"1970-01-01";
            }
            if (!strcmp (pFieldName,"id"))
            {
                iref = atoi (pVal);
            }
            if (!strcmp (pFieldName,"LONGITUDE"))
            {
                longitude = atof (pVal);
            }
            if (!strcmp (pFieldName,"LATITUDE"))
            {
                latitude = atof (pVal);
            }
            if (!strcmp (pFieldName,"City"))
            {
                fname = @"CityStamp";
            }
            if (!strcmp (pFieldName,"Length"))
            {
                fname = @"SegmentLength";
                isSegField = 1;
            }
            if (!strcmp (pFieldName,"Max Hght"))
            {
                fname = @"SegmentMaxHeight";
                isSegField = 1;
            }
            if (!strcmp (pFieldName,"Offset"))
            {
                fname = @"SegmentOffset";
                isSegField = 1;
            }
            if (!strcmp (pFieldName,"Type Const"))
            {
                fname = @"TypeConst";
                isSegField = 1;
            }
            if (isSegField)
            {
                NSString * newSegName = [NSString stringWithFormat:@"%@[%@]",segdelim,fname];
                newSegNames = [newSegNames stringByAppendingString:newSegName];
                newSegVals = [newSegVals stringByAppendingString:[NSString stringWithFormat:@"%@'%@'",segdelim,val]];
                segdelim = @",";
            }
            if (!isSegField || isSegField == 2)
            {
                NSString * newName = [NSString stringWithFormat:@"%@[%@]",delim,fname];
                newNames = [newNames stringByAppendingString:newName];
                newVals = [newVals stringByAppendingString:[NSString stringWithFormat:@"%@'%@'",delim,val]];
                delim = @",";
            }
        }
        NSString* cmd = [NSString stringWithFormat:@"INSERT OR REPLACE INTO ALLEYWALLS_NEW([Current],%@) VALUES(1,%@)",newNames,newVals];
        [self executeCmd:(LPSTR)cmd.UTF8String
            sendToServer:sendToServer
           useUniqueFile:NO];
        cmd = [NSString stringWithFormat:@"INSERT OR REPLACE INTO ALLEYWALL_SEGS([SEGMENT],%@) VALUES(1,%@)",newSegNames,newSegVals];
        [self executeCmd:(LPSTR)cmd.UTF8String
            sendToServer:sendToServer
           useUniqueFile:NO];
        cmd = [NSString stringWithFormat:@"INSERT INTO ALLEYWALLS_NEW_index VALUES(%i,%f,%f,%f,%f);",iref,longitude,longitude,latitude,latitude];
        [self executeCmd:(LPSTR)cmd.UTF8String
            sendToServer:sendToServer
           useUniqueFile:NO];

    }
    SQLOKawd(sqlite3_finalize(statement),_database);
/*    INSERT INTO ALLEYWALLS_index VALUES(14,-93.260717,-93.260717,44.910437,44.910437);
    CREATE TABLE ALLEYWALLS ('id' INT,'Wall ID' CHAR(8),'Hse No' INT,'STREET' CHAR(64),'City' CHAR(4),'Length' REAL,'Max Hght' REAL,'Offset' REAL,'Gar/Struc' CHAR(12),' COST' CHAR(12),'Type Const' CHAR(32),'InspDate' CHAR(12),'InspBy' CHAR(8),'Rating' CHAR(16),'Comments' CHAR(255),'LONGITUDE' REAL,'LATITUDE' REAL,'NUMSEGMENTS' INT,'LASTUPDATE' INT,PRIMARY KEY('id' ASC))
 */
    [self commitTransaction];
    return rtn;
}
@end
