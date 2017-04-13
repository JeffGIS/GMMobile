//
//  CrimeList.m
//  NVMobile
//
//  Created by Jeff Smith on 4/5/17.
//  Copyright © 2017 GSSi. All rights reserved.
//

#import "CrimeList.h"
#import "CCodeLibrary/SQLiteLib.h"
#import "CCodeLibrary/MathUtil.h"


//#define CURRENT_VERSION 28

@interface CrimeList ()

@property NSString *fileName, *path;
@property sqlite3 *database;
@property BOOL isOpen;
@property unsigned long long fileSize;
@property int dbIsOpen;
@property NSArray * controlNumberList;
@end

@implementation CrimeList

- (void)logError:(int)sqlReturn
          method:(sqlite3*)database
{
    NSLog(@"%@", [NSString stringWithFormat:@"SQLite Error %i = %i:%s",
                  sqlReturn, sqlite3_errcode(database), sqlite3_errmsg(database)]);
}

NSString * GetCrimeListDirectory (void)
{
    NSString * documentsDirectory = CRAPI.sharedInstance.documentsDirectory;
    NSString * crimeListDir = [NSString stringWithFormat:@"%@/CrimeLists",documentsDirectory];
    [NSFileManager.defaultManager createDirectoryAtPath:crimeListDir
                            withIntermediateDirectories:YES
                                             attributes:nil
                                                  error:nil];
    
    return crimeListDir;
}

+ (NSArray *) getCrimeLists
{
    NSString *dir = GetCrimeListDirectory();
    NSMutableArray *array = [[NSMutableArray alloc]init];
    for (NSString *fileName in [NSFileManager.defaultManager contentsOfDirectoryAtPath:dir
                                                                                 error:nil])
    {
        NSString *leafName = textBefore (fileName.lastPathComponent,@".");
        [array addObject:leafName];
    }
    return array;
}

+ (NSString *) createNewCrimeList
{
    NSString *baseName = @"CrimeList";
    
    int n = 1;
    NSArray * lists = [CrimeList getCrimeLists];
    n = (int)lists.count + 1;
    NSString *newName = [NSString stringWithFormat:@"%@%i", baseName, n];
    
    while (nameInList (newName,lists))
    {
        n++;
        newName = [NSString stringWithFormat:@"%@%i", baseName, n];
    }
    
    [UserDefaults.defaults saveString:newName
                               forKey:@"CurrentCrimeList"];
    CrimeList * cl = CrimeList.new;
    return newName;
}

+ (NSString*) getControlNumberList:(NSString *)listName
{
    NSString * list = @"";
    [CrimeList setCurrentCrimeList:listName];
    CrimeList * cl = CrimeList.new;
    BOOL opened = [cl open];
    NSArray *controlNumbers = [cl getControlNumbers];
    char delim = 0;
    for (NSNumber *cnum in controlNumbers)
    {
        list = [list stringByAppendingString:[NSString stringWithFormat:@"%c%i",delim,(int)cnum.integerValue]];
        delim = ',';
    }
    [cl close:opened];
    return list;
}

+ (NSString*) getCurrentCrimeListName
{
    NSString *name = [UserDefaults.defaults stringForKey:@"CurrentCrimeList"];
    if (!name)
        name = [CrimeList createNewCrimeList];
    return name;
}

+ (BOOL) renameCurrentCrimeList:(NSString *)newName
{
    CrimeList *cl = [[CrimeList alloc]init];
    NSString *currentFile = cl.path;
    NSString *newFile = [NSString stringWithFormat:@"%@/%@.sqlite", cl.crimeListDir, newName];
    
    [cl close:YES];
    NSError * err = NULL;
    BOOL result = [NSFileManager.defaultManager  moveItemAtPath:currentFile
                                                         toPath:newFile
                                                          error:&err];
    if(!result)
    {
        NSLog(@"Error: %@", err);
        return FALSE;
    }
    [UserDefaults.defaults saveString:newName
                               forKey:@"CurrentCrimeList"];
    
    return TRUE;
}

+ (BOOL) deleteCurrentCrimeList
{
    
    CrimeList *pl = [[CrimeList alloc]init];
    NSString *currentFile = pl.path;
    NSError *error = nil;
    [pl close:YES];
    if (![NSFileManager.defaultManager removeItemAtPath:currentFile error:&error])
    {
        NSLog(@"%@ file removal error", currentFile);
        return FALSE;
    }
    NSArray *lists = [CrimeList getCrimeLists];
    if (lists.count)
        [UserDefaults.defaults saveString:lists[0]
                                   forKey:@"CurrentCrimeList"];
    else
        [UserDefaults.defaults saveString:@"CrimeList1"
                                   forKey:@"CurrentCrimeList"];
    
    return TRUE;
}

+ (BOOL) setCurrentCrimeList:(NSString *)crimeList
//returns false if crimelist does not exist
{
    BOOL rtn = NO;
    
    [UserDefaults.defaults saveString:crimeList
                               forKey:@"CurrentCrimeList"];
    
    return  rtn;
}
- (id)init
{
    self = [super init];
    
    if (self)
    {
        _crimeListDir = GetCrimeListDirectory ();
        _fileName = [CrimeList getCurrentCrimeListName];
        
        
        _path = [NSString stringWithFormat:@"%@/%@.sqlite", _crimeListDir, _fileName];
        
        //int version = [self datasetVersion];
        
        if (CRAPI.sharedInstance.resetCrimeList)
        {
            NSError *error = nil;
            
            [NSFileManager.defaultManager removeItemAtPath:_path
                                                     error:&error];
            
            if (error)
                NSLog(@"%@ file removal error", _fileName);
            
            CRAPI.sharedInstance.resetCrimeList = NO;
        }
        
        [self createTables];
        
    }
    NSLog(@"Init crime list %@", _fileName);
    
    return self;
}

- (void)dealloc
{
    [self close:YES];
    NSLog(@"CrimeList Database dealloc");
}
- (BOOL)open
{
    BOOL rtn = NO;
    
    if (!_isOpen)
    {
        if (_dbIsOpen)
            NSLog(@"CrimeList already open");
        _dbIsOpen++;
        _fileName = [UserDefaults.defaults stringForKey:@"CurrentCrimeList"];
        _path = [NSString stringWithFormat:@"%@/%@.sqlite", _crimeListDir, _fileName];
        
        //        _isOpen = !SQLOK(0,sqlite3_open_v2(_path.UTF8String, &_database,SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE|SQLITE_OPEN_NOMUTEX,NULL), _database);
        _isOpen = !SQLOK(0,sqlite3_open(_path.UTF8String, &_database), _database);
        NSLog(@"CrimeList Database open");
        _fileSize = [NSFileManager.defaultManager attributesOfItemAtPath:_path error:nil].fileSize;
        rtn = YES;
    }
    
    return rtn;
}

- (void)close:(BOOL)opened
{
    if (opened && _isOpen)
    {
        NSLog(@"CrimeList Database close");
        SQLOK(0,sqlite3_close(_database),_database);
        _isOpen = NO;
        _dbIsOpen--;
        _controlNumberList = nil;
    }
}

- (BOOL)executeCmd:(char *)cmd
{
    BOOL rtn = !SQLOK(0,sqlite3_exec(_database, cmd, 0, 0, 0), _database);
    return rtn;
}

- (void)startTransaction
{
    SQLOK(0,sqlite3_exec(_database, "BEGIN", 0, 0, 0), _database);
}

- (void)commitTransaction
{
    SQLOK(0,sqlite3_exec(_database, "COMMIT", 0, 0, 0), _database);
}

- (NSArray*)availableCrimeFields
{
    NSMutableArray *fields = [[NSMutableArray alloc]init];
    for (int i = 1;i<CFT_END;i++)
    {
        NSNumber *field = [NSNumber numberWithInteger:i];
        [fields addObject:field];
    }
    return fields.copy;
}

- (NSString*) crimeFieldName:(CrimeFieldType)fieldType
{
    NSString *name = @"";
    
    switch(fieldType)
    {
        case CFT_LatLon:
        case CFT_END:
            break;
        case CFT_UCR:
            name = @"UCR";
            break;
        case CFT_CASENO:
            name = @"Case Number";
            break;
        case CFT_OffenseCodes:
            name = @"Offense Codes";
            break;
        case CFT_FromTime:
            name = @"From Time";
            break;
        case CFT_ToTime:
            name = @"To Time";
            break;
        case CFT_SearchString1:
            name = @"Search:dread";
            break;
        case CFT_SearchString2:
            name = @"Search:knife";
            break;
        case CFT_NumSuspects:
            name = @"Suspects";
            break;
        case CFT_Location:
            name = @"Location";
            break;
        default:
            break;
    }
    
    return name;
}

- (ValueTypes) getFieldValueType:(CrimeFieldType)type
{
    ValueTypes rtn = VTInteger;
    switch (type)
    {
        case CFT_LatLon:
            rtn = VTLLPoint;
            break;
        case CFT_CASENO:
        case CFT_OffenseCodes:
        case CFT_Location:
            rtn = VTString;
            break;
        case CFT_HEIGHT:
            rtn = VTDouble;
            break;
        default:
            rtn = VTInteger;
            break;
    }
    return rtn;
}

- (NSArray*) getControlNumbers
{
    if (!_controlNumberList)
        _controlNumberList = [self createControlNumbers];
    return _controlNumberList;
}

- (BOOL) createTables
{
    BOOL opened = [self open];
    
    NSString *cmd =  @"CREATE TABLE IF NOT EXISTS CrimeList (id INTEGER PRIMARY KEY,ControlNum INTEGER,FieldType INTEGER,DataVersion INTEGER,FieldValue BLOB(33554432));\
    CREATE INDEX IF NOT EXISTS CrimeList_index ON CrimeList (ControlNum ASC);";
    BOOL rtn = !SQLOK(0,sqlite3_exec(_database, cmd.UTF8String, 0, 0, 0), _database);
    
    [self close:opened];
    return rtn;
}

- (BOOL) sortOn:(CrimeFieldType)field
{
    BOOL opened = [self open];
    int ascending = 1;
    
    NSString *cmd =  [NSString stringWithFormat:@"DROP TABLE IF EXISTS SortOn;CREATE TABLE SortOn (FieldType INTEGER, Ascending INTEGER));INSERT INTO SortOn VALUES (%i,%i)",field,ascending];
    BOOL rtn = !SQLOK(0,sqlite3_exec(_database, cmd.UTF8String, 0, 0, 0), _database);
    
    [self close:opened];
    return rtn;
}
- (void) createSortedList
{
    int ascending;
    CrimeFieldType sortField = [self getSortField:&ascending];
    BOOL opened = [self open];
    _controlNumberList = nil;
   
    NSString *cmd =  @"DROP TABLE IF EXISTS SortedList;";
    BOOL rtn = !SQLOK(0,sqlite3_exec(_database, cmd.UTF8String, 0, 0, 0), _database);
    
    if (sortField != CFT_END)
    {
        NSString * type = @"INTEGER";
        cmd =  [NSString stringWithFormat:@"CREATE TABLE SortedList (Value %@ PRIMARY KEY,ControlNum INTEGER;",type];
        rtn = !SQLOK(0,sqlite3_exec(_database, cmd.UTF8String, 0, 0, 0), _database);
    }
    [self close:opened];
}
-  (CrimeFieldType) getSortField:(int *)ascending
{
    CrimeFieldType  rtn = CFT_END;
    int asc = 1;
    
    if (ascending)
        *ascending = asc;
    return rtn;
}
- (NSArray*) createControlNumbers
{
    NSMutableArray * controlNums = [[NSMutableArray alloc]init];
    BOOL opened = [self open];
    NSString *query = [NSString stringWithFormat:@"SELECT DISTINCT ControlNum FROM CrimeList"];
    CrimeFieldType sortField = [self getSortField:nil];
    if (sortField != CFT_END)
        query = [NSString stringWithFormat:@"SELECT DISTINCT ControlNum FROM SortedList"];

    sqlite3_stmt *statement = NULL;
    
    SQLOK(0,sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        int controlid = sqlite3_column_int(statement, 0);
        NSNumber * controlNum = [NSNumber numberWithInt:controlid];
        [controlNums addObject:controlNum];
    }
    
    SQLOK(0,sqlite3_finalize(statement), _database);
    [self close:opened];
    return controlNums.copy;
}

- (void) getCrimeFieldValueOfType:(CrimeFieldType)type
                   forControlNumber:(NSInteger)controlNum;
{
    NSString *value = @"";
    
    value = [self getFieldValue:controlNum
                           type:type
                            raw:NO];
    
    if (value)
    {
        [self.delegate CrimeList:self
                       returnsValue:value
                  forControlNumber:controlNum
                       andFieldType:type
                         withStatus:0];
    }
    
    
    return;
}

- (NSString *) getFieldValue:(NSInteger)controlNum
                        type:(CrimeFieldType)fieldType
                         raw:(BOOL)raw
{
    NSString *value = @"";
    NSNumber *num;
    NSString *query = [NSString stringWithFormat:@"SELECT FieldValue FROM CrimeList WHERE ControlNum = %li AND FieldType = %li",
                       (long)controlNum, (long)fieldType];
    
    BOOL opened = [self open];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(0,sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR val;
        int ival;
        double dval;
        
        switch (fieldType)
        {
            case CFT_LatLon:
            {
                LLPOINT pt = *(LLPOINT*)sqlite3_column_blob(statement, 0);
                value = [NSString stringWithFormat:@"%f %f",pt.lat,pt.lon];
            }
                break;
            case CFT_Location:
            case CFT_OffenseCodes:
            case CFT_CASENO:
                val = (LPSTR)sqlite3_column_blob(statement, 0);
                if (val)
                    value = [NSString stringWithFormat:@"%s",val];
                break;
            case CFT_HEIGHT:
                dval = *(double*)sqlite3_column_blob(statement, 0);
                num = [[NSNumber alloc] initWithDouble:dval];
                value = [CRAPI.sharedInstance.dollarFmt stringFromNumber:num];
                break;
            case CFT_SCORE:
                dval = *(double*)sqlite3_column_blob(statement, 0);
                num = [[NSNumber alloc] initWithDouble:dval];
                value = [CRAPI.sharedInstance.acreFmt stringFromNumber:num];
                break;
            case CFT_SearchString1:
            case CFT_SearchString2:
                ival = *(int*)sqlite3_column_blob(statement, 0);
                if (ival)
                    value = @"YES";
                break;
            case CFT_FromTime:
            case CFT_ToTime:
            {
                ival = *(int*)sqlite3_column_blob(statement, 0);
                if (raw)
                {
                    value = [NSString stringWithFormat:@"%i",ival];
                }
                else
                {
                    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                    value = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:ival]];
                }
                
            }
                break;
            default:
                ival = *(int*)sqlite3_column_blob(statement, 0);
                value = [NSString stringWithFormat:@"%i",ival];
                break;
        }
    }
    
    SQLOK(0,sqlite3_finalize(statement), _database);
    [self close:opened];
    
    return value;
}

- (void) deleteControlNumber:(int)controlNum
{
    BOOL opened = [self open];
    NSString *query = [NSString stringWithFormat:@"DELETE FROM CrimeList WHERE ControlNum = %i",controlNum];
    
    [self executeCmd:(LPSTR)query.UTF8String];
    
    [self close:opened];
}

- (int)nextCrimeNum
{
    int rtn = 1;
    
    NSString *query = [NSString stringWithFormat:@"SELECT max(CrimeNum) FROM CrimeList"];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(0,sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        rtn = sqlite3_column_int(statement, 0) + 1;
    }
    
    SQLOK(0,sqlite3_finalize(statement), _database);
    
    return rtn;
}

- (int)next_id
{
    int rtn = 1;
    
    NSString *query = [NSString stringWithFormat:@"SELECT max(id) FROM CrimeList"];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(0,sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        rtn = sqlite3_column_int(statement, 0) + 1;
    }
    
    SQLOK(0,sqlite3_finalize(statement), _database);
    
    return rtn;
}

- (LLPOINT)getCrimeLatLon:(NSInteger)controlNum
{
    LLPOINT pt;
    BOOL opened = [self open];
    NSString * value = [self getFieldValue:controlNum
                                      type:CFT_LatLon
                                       raw:NO];
    
    pt = LLPOINTFromString (value);
    [self close:opened];
    return pt;
}

- (void)setZoomValues:(NSInteger)controlNum forRow:(NSInteger)row
{
    BOOL opened = [self open];
/*    NSArray *fields = [self availablePropertyFields];
    NSNumber *field = fields[row];
    CrimeFieldType ifield = field.integerValue;
    NSString * PID = [self getFieldValue:propNum
                                    type:PFT_PIN];
    ConfigurationControl.sharedInstance.MapitPID = PID;
    ConfigurationControl.sharedInstance.currentPropSheetFieldType = ifield;
    ConfigurationControl.sharedInstance.MapitBoundaryOpt = [self getBoundaryTypeForField:ifield];
    NVMetroSettings.sharedInstance.currentFeatureSaved = [self setFeatureTypeForField:ifield];
    NVMetroSettings.sharedInstance.savedVisibleBounds = CRAPI.sharedInstance.lastViewBounds;
    if (ConfigurationControl.sharedInstance.MapitBoundaryOpt == MAPIT_CIRCULAR)
    {
        NSString * value = [self getFieldValue:propNum
                                          type:PFT_LatLon];
        ConfigurationControl.sharedInstance.MapitTargetCenterPoint = LLPOINTFromString (value);
        ConfigurationControl.sharedInstance.MapitCirularBoundaryRadiusInMiles = [CrimeList getRadiusForField:ifield];
    }
    else
    {
        NSString * cenBlock = [PropertyData getCensusBlockForPID:PID];
        NSString * type  = @"BLOCK";
        if (ConfigurationControl.sharedInstance.MapitBoundaryOpt == MAPIT_AREA_BLOCKGRP)
        {
            char blkGrp[20];
            strncpy (blkGrp,cenBlock.UTF8String,12);
            blkGrp[12] = 0;
            cenBlock = [NSString stringWithUTF8String:blkGrp];
            type = @"BLOCKGROUP";
        }
        ConfigurationControl.sharedInstance.MapitBoundaryRefno = [BoundaryData getBoundaryAreaRefnoForType:type andName:cenBlock];
        ConfigurationControl.sharedInstance.MapitBoundaryType = type;
    }
    */
    [self close:opened];
}

- (BOOL)addIncidentToCrimeList:(int)controlNum
{
    BOOL rtn = NO;
    BOOL opened = [self open];
    int dbid = [self next_id];
    
    CrimeData *crimeData = [[CrimeData alloc] init];
    BOOL openedCd = [crimeData open];
    int crimeVersion = [crimeData datasetVersion];
    sqlite3_stmt *statement = NULL;
    LLPOINT BasePt;
    int UCR = 0;
    int fromTime=0, toTime=0;
    LPSTR offense;
    LPSTR dept, year, cno;
    char allOffense[1024]={0};
    char address[1024];
    NSString * caseNum=@"";
    NSString * location = @"";
    BOOL first = TRUE;
    
    /*    NSString * query = [NSString stringWithFormat:@"SELECT X,Y,Offense,UCR,FromDate,ToDate, CityCode, CaseYear, CaseNbr, HouseNbr, HouseModifier,StreetName,StreetType,StreetDirection,IntersectionStreetName,IntersectionStreetType,IntersectionStreetDirection,Apartment FROM OFFENSEXY WHERE ControlNbr = %i",controlNum];*/
        NSString * query = [NSString stringWithFormat:@"SELECT X,Y,Offense,UCR,FromDate,ToDate, CityCode, CaseYear, CaseNbr, Location FROM OFFENSEXY WHERE ControlNbr = %i",controlNum];
    //NSString * query = [NSString stringWithFormat:@"SELECT * FROM OFFENSEXY WHERE ControlNbr = %i",controlNum];
    SQLOK(0,sqlite3_prepare_v2(crimeData.database, query.UTF8String, -1, &statement, 0), crimeData.database);
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
/*        int i=0;
        while (i < sqlite3_column_count(statement))
        {
            LPSTR name = sqlite3_column_name(statement, i);
            i++;
        }*/
        offense = (LPSTR)sqlite3_column_text(statement,2);
        if (!first)
            sprintf (strchr(allOffense,0),",%s",offense);
        else
        {
            int i = 3;
            strcpy (allOffense,offense);
            BasePt.lon = sqlite3_column_double(statement,0);
            BasePt.lat = sqlite3_column_double(statement,1);
            UCR = sqlite3_column_int(statement,i++);
            fromTime = sqlite3_column_int(statement,i++);
            toTime = sqlite3_column_int(statement,i++);
            dept = (LPSTR)sqlite3_column_text(statement,i++);
            year = (LPSTR)sqlite3_column_text(statement,i++);
            cno = (LPSTR)sqlite3_column_text(statement,i++);
            caseNum  = [NSString stringWithFormat:@"%s%s%s",dept,year,cno];
            LPSTR loc = (LPSTR)sqlite3_column_text(statement,i++);
            location = [NSString stringWithUTF8String:loc];
           /* LPSTR house = (LPSTR)sqlite3_column_text(statement,i++);
            LPSTR houseMod = (LPSTR)sqlite3_column_text(statement,i++);
            LPSTR streetName = (LPSTR)sqlite3_column_text(statement,i++);
            LPSTR streetType = (LPSTR)sqlite3_column_text(statement,i++);
            LPSTR streetDir = (LPSTR)sqlite3_column_text(statement,i++);
            LPSTR intStreetName = (LPSTR)sqlite3_column_text(statement,i++);
            LPSTR intStreetType = (LPSTR)sqlite3_column_text(statement,i++);
            LPSTR intStreetDir = (LPSTR)sqlite3_column_text(statement,i++);
            LPSTR appt = (LPSTR)sqlite3_column_text(statement,i++);
            sprintf (address,"%s %s %s %s %s %s %s %s %s",house,houseMod,streetName,streetType,streetDir,intStreetName,intStreetType,intStreetDir,appt);
            OneSpace(address);*/
            i++;
        }
        first = FALSE;
    }
    SQLOK(0,sqlite3_finalize(statement), crimeData.database);
    [crimeData close:openedCd];
    if (!first)
    {
        NSString *caseBlob = stringToBlob(caseNum);
        NSString *pointBlob = llpointsToBlob(&BasePt,1);
        NSString *ucrBlob = intToBlob(UCR);
        NSString *offenseBlob = stringToBlob([NSString stringWithUTF8String:allOffense]);
        NSString * cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,controlNum,(int)CFT_CASENO,crimeVersion,caseBlob];
        [self executeCmd:(LPSTR)cmd.UTF8String];
        cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,controlNum,(int)CFT_UCR,crimeVersion,ucrBlob];
        [self executeCmd:(LPSTR)cmd.UTF8String];
        cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,controlNum,(int)CFT_LatLon,crimeVersion,pointBlob];
        [self executeCmd:(LPSTR)cmd.UTF8String];
        cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,controlNum,(int)CFT_OffenseCodes,crimeVersion,offenseBlob];
        [self executeCmd:(LPSTR)cmd.UTF8String];
        NSString * timeBlob = intToBlob (fromTime);
        cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,controlNum,(int)CFT_FromTime,crimeVersion,timeBlob];
        [self executeCmd:(LPSTR)cmd.UTF8String];
        timeBlob = intToBlob (toTime);
        cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,controlNum,(int)CFT_ToTime,crimeVersion,timeBlob];
        [self executeCmd:(LPSTR)cmd.UTF8String];
        NSString * locationBlob = stringToBlob (location);
        cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,controlNum,(int)CFT_Location,crimeVersion,locationBlob];
        [self executeCmd:(LPSTR)cmd.UTF8String];
        
        NSString * report = [CrimeData reportForControlNumber:controlNum];
        BOOL found = stringContainsCaseInsenitiveString (report,@"dread");
        timeBlob = intToBlob (found);
        cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,controlNum,(int)CFT_SearchString1,crimeVersion,timeBlob];
        [self executeCmd:(LPSTR)cmd.UTF8String];
        found = stringContainsCaseInsenitiveString (report,@"knife");
        timeBlob = intToBlob (found);
        cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,controlNum,(int)CFT_SearchString2,crimeVersion,timeBlob];
        [self executeCmd:(LPSTR)cmd.UTF8String];
        int nSuspect = numberOfOccurencesOfStringInString(report, @" S- ");
        NSString *nsBlob = intToBlob (nSuspect);
        cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,controlNum,(int)CFT_NumSuspects,crimeVersion,nsBlob];
        [self executeCmd:(LPSTR)cmd.UTF8String];
        rtn = YES;
    }

    [self close:opened];
    return rtn;
}
- (void) GSSiPopoverViewdidCancel:(GSSiPopoverView *)popoverView
{
    
}


@end

NSString* CrimeListFieldDescription (NSInteger fieldNumber)
{
    NSString *file;
    
    NSString *name = [NSString stringWithFormat:@"CrimeListField_%li",(long)fieldNumber];
    file = [NSBundle.mainBundle pathForResource:name ofType:@"pdf"];
    
    if (![NSFileManager.defaultManager fileExistsAtPath:file])
        file = [NSBundle.mainBundle pathForResource:@"CrimeListField_default" ofType:@"pdf"];
    return file;
}

