//  PropertyList.m
//  GMMobile

#import "PropertyList.h"
#import "PropertyData.h"
#import "BoundaryData.h"
#import "Destinations.h"
#import "ConfigurationControl.h"
#import "NVMetroSettings.h"
#import "CCodeLibrary/MathUtil.h"
#import "RiteHomeCompute.h"

//#define CURRENT_VERSION 28

@interface PropertyList ()

@property RiteHomeCompute *rhCompute;

@property NSString *plName, *plPath, *plDirectory;
@property BOOL isOpen;
@property unsigned long long fileSize;
@property int dbIsOpen;
@property NSString *usedesc;
@property double totEMV;
@property int dbid;
@property int PropNum;
@property int PropVersion;

@end

@implementation PropertyList

- (void)logError:(int)sqlReturn
          method:(sqlite3nv *)database
{
    NSLog(@"%@", [NSString stringWithFormat:@"SQLite Error %i = %i:%s",
                  sqlReturn, sqlite3_errcode(database->db), sqlite3_errmsg(database->db)]);
}

NSString * GetPropListDirectory (void)
{
    NSString * documentsDirectory = CRAPI.sharedInstance.sharedOutputDirectory;
    NSString * propListDir = [NSString stringWithFormat:@"%@/PropertyLists",documentsDirectory];
    if (CRAPI.sharedInstance.resetPropList)
    {
        NSError *error = nil;
        
        [NSFileManager.defaultManager removeItemAtPath:propListDir
                                                 error:&error];
        
        if (error)
            NSLog(@"%@ file removal error", propListDir);
        NSString *plName = @"";
        [UserDefaults.defaults saveString:plName
                                   forKey:@"CurrentPropertyList"];
        
        CRAPI.sharedInstance.resetPropList = NO;
    }
    [NSFileManager.defaultManager createDirectoryAtPath:propListDir
                            withIntermediateDirectories:YES
                                             attributes:nil
                                                  error:nil];
    
    return propListDir;
}

+ (NSArray *) getPropertyLists
{
    NSString *dir = GetPropListDirectory();
    NSMutableArray *array = [[NSMutableArray alloc]init];
    for (NSString *fileName in [NSFileManager.defaultManager contentsOfDirectoryAtPath:dir
                                                                                 error:nil])
    {
        [array addObject:fileName];
    }
    return array;
}

+ (void) createNewPropertyList
{
    NSString *baseName = @"PropertyList";
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        baseName = @"PropList";
    
    int n = 1;
    NSArray * lists = [PropertyList getPropertyLists];
    n = (int)lists.count + 1;
    NSString *newName = [NSString stringWithFormat:@"%@%i", baseName, n];
    
    while (nameInList (newName,lists))
    {
        n++;
        newName = [NSString stringWithFormat:@"%@%i", baseName, n];
    }
    
    [UserDefaults.defaults saveString:newName
                               forKey:@"CurrentPropertyList"];
    
}

+ (NSString*) getCurrentPropertyListName
{
    NSString *name = [UserDefaults.defaults stringForKey:@"CurrentPropertyList"];
    return name;
}

+ (BOOL) renameCurrentPropertyList:(NSString *)newName
{
    PropertyList *pl = [[PropertyList alloc]init];
    NSString *currentDir = pl.plDirectory;
    NSString *newFile = [NSString stringWithFormat:@"%@/%@", pl.propListDir, newName];
    
    [pl close:YES];
    NSError * err = NULL;
    BOOL result = [NSFileManager.defaultManager  moveItemAtPath:currentDir
                                                         toPath:newFile
                                                          error:&err];
    if(!result)
    {
        NSLog(@"Error: %@", err);
        return FALSE;
    }
    [UserDefaults.defaults saveString:newName
                               forKey:@"CurrentPropertyList"];
    
    return TRUE;
}

+ (BOOL) deleteCurrentPropertyList
{
    PropertyList *pl = [[PropertyList alloc]init];
    [pl open];
    NSString *currentDir = [pl getCurrentPropListDir];
    [pl close:YES];
    NSError *error = nil;
    if (![NSFileManager.defaultManager removeItemAtPath:currentDir error:&error])
    {
        NSLog(@"%@ file removal error", currentDir);
        return FALSE;
    }
    NSArray *lists = [PropertyList getPropertyLists];
    if (lists.count)
        [UserDefaults.defaults saveString:lists[0]
                                   forKey:@"CurrentPropertyList"];
    else
        [UserDefaults.defaults saveString:@""
                                   forKey:@"CurrentPropertyList"];
    
    return TRUE;
}

+ (BOOL) setCurrentPropertyList:(NSString *)propList
//returns false if proplist does not exist
{
    BOOL rtn = NO;
    
    [UserDefaults.defaults saveString:propList
                               forKey:@"CurrentPropertyList"];
    
    return  rtn;
}
- (id)init
{
    self = [super init];
    
    if (self)
        NSLog(@"Init property list");
    
    return self;
}

- (void)dealloc
{
    [self close:YES];
    NSLog(@"PropertyList Database dealloc");
}

- (NSString*) getCurrentPropListDir
{
    _propListDir = GetPropListDirectory ();
    _plName = [UserDefaults.defaults stringForKey:@"CurrentPropertyList"];
    
    if (!_plName || !*_plName.UTF8String)
    {
        _plName = @"PropList1";
        [UserDefaults.defaults saveString:_plName
                                   forKey:@"CurrentPropertyList"];
    }
    
    NSString * dir = [NSString stringWithFormat:@"%@/%@", _propListDir, _plName];
    [NSFileManager.defaultManager createDirectoryAtPath:dir
                            withIntermediateDirectories:YES
                                             attributes:nil
                                                  error:nil];
    
    //int version = [self datasetVersion];
    
    return dir;
}

- (BOOL)open
{
    BOOL rtn = NO;
    
    if (!_isOpen)
    {
        if (_dbIsOpen)
            NSLog(@"PropertyList already open");
        _dbIsOpen++;
        _plDirectory = [self getCurrentPropListDir];
        _plPath = [NSString stringWithFormat:@"%@/PropertyData.slt", _plDirectory];
        
        //        _isOpen = !SQLOK(__FILE__,__LINE__,SQLite_Open_v2(_path.UTF8String, &_database,SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE|SQLITE_OPEN_NOMUTEX,NULL), _database);
        _isOpen = !SQLOK(__FILE__,__LINE__,SQLite_Open(_plPath.UTF8String, &_database), _database);
        NSLog(@"PropertyList Database open");
        _fileSize = [NSFileManager.defaultManager attributesOfItemAtPath:_plPath error:nil].fileSize;
        if (!_fileSize)
            [self createTables];
        
        rtn = YES;
    }
    
    return rtn;
}

- (void)close:(BOOL)opened
{
    if (opened && _isOpen)
    {
        NSLog(@"PropertyList Database close");
        SQLOK(__FILE__,__LINE__,SQLite_Close(&_database),_database);
        _isOpen = NO;
        _dbIsOpen--;
    }
}

- (BOOL) createTables
{
    BOOL opened = [self open];
    
    NSString *cmd =  @"CREATE TABLE IF NOT EXISTS PropertyList (id INTEGER PRIMARY KEY,PropNum INTEGER,FieldType INTEGER,DataVersion INTEGER,FieldValue BLOB(33554432));\
    CREATE INDEX IF NOT EXISTS PropertyList_index ON PropertyList (PropNum ASC, FieldType ASC);\
    CREATE TABLE IF NOT EXISTS PropertyVideo (videoID INTEGER PRIMARY KEY,PropNum INTEGER,Title CHAR(256), Type INT, Cost REAL, Notes CHAR(4096), VideoFileName CHAR(256), StartTime FLOAT, EndTime FLOAT);";
    BOOL rtn = !SQLOK(__FILE__,__LINE__,SQLiteExec(_database, cmd.UTF8String, 0, 0, 0), _database);
    
    cmd =  @"CREATE TABLE IF NOT EXISTS AreasWithinDistance (PropNum INTEGER,AreaType INT,AreaID INT,Distance INT,SQMetersInCircle FLOAT,PercentOfCircle FLOAT);\
    CREATE INDEX IF NOT EXISTS AreasWithinDistance_index ON AreasWithinDistance (PropNum ASC, AreaType ASC);";
    rtn = !SQLOK(__FILE__,__LINE__,SQLiteExec(_database, cmd.UTF8String, 0, 0, 0), _database);
    
    [self close:opened];
    return rtn;
}

- (int)nextVideoID
{
    int rtn = 1;
    
    NSString *query = [NSString stringWithFormat:@"SELECT max(videoID) FROM PropertyVideo"];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(__FILE__,__LINE__,SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        rtn = sqlite3_column_int(statement, 0) + 1;
    }
    
    SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), _database);
    
    return rtn;
}

- (NSString *)getVideoDirectory:(int)propNum
{
    NSString * pldir = [self getCurrentPropListDir];
    NSString *dir = [NSString stringWithFormat:@"%@/Prop%i_video",pldir,propNum];
    [NSFileManager.defaultManager createDirectoryAtPath:dir
                            withIntermediateDirectories:YES
                                             attributes:nil
                                                  error:nil];
    
    return dir;
}

- (BOOL)addVideoClip:(RHClip *)clip
{
    BOOL opened = [self open];
    int clipID = clip.clipID;
    
    if (!clipID)
        clipID = [self nextVideoID];
    
    NSString *cmd = [NSString stringWithFormat:@"INSERT OR REPLACE INTO PropertyVideo VALUES (%i,%i,'%@',%i, %f, '%@','%@',%f,%f);",
                     clipID, clip.propNum, clip.title, (int)clip.quality, clip.cost, clip.notes, clip.videoFileName,
                     clip.startTime,clip.endTime];
    
    BOOL rtn = [self executeCmd:(LPSTR)cmd.UTF8String];
    [self close:opened];
    return rtn;
}

-(NSArray *) getVideoClipsForProperty:(int)propNum
{
    NSMutableArray *rtn = NSMutableArray.array;
    BOOL opened = [self open];
    NSString *query = [NSString stringWithFormat:@"SELECT videoID, Title, Type, Cost, Notes, VideoFileName, StartTime, EndTime FROM PropertyVideo WHERE PropNum = %i",propNum];
    sqlite3_stmt *statement = NULL;
    
    SQLOK(__FILE__,__LINE__,SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        int i = 0;
        RHClip * clip = RHClip.new;
        clip.propNum = propNum;
        clip.clipID = sqlite3_column_int(statement, i++);
        LPCSTR val = (LPCSTR)sqlite3_column_text (statement, i++);
        clip.title = [NSString stringWithUTF8String:val];
        clip.quality = sqlite3_column_int(statement, i++);
        clip.cost = sqlite3_column_double(statement, i++);
        val = (LPCSTR)sqlite3_column_text (statement, i++);
        clip.notes = [NSString stringWithUTF8String:val];
        val = (LPCSTR)sqlite3_column_text (statement, i++);
        clip.videoFileName = [NSString stringWithUTF8String:val];
        clip.startTime = sqlite3_column_double(statement, i++);
        clip.endTime = sqlite3_column_double(statement, i++);
        [rtn addObject:clip];
    }
    
    SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), _database);
    [self close:opened];
    return rtn.copy;
}
/*
 - (int)datasetVersion
 {
 int rtn = -1;
 BOOL opened = [self open];
 
 if (_isOpen && _fileSize > 0)
 {
 NSString *query = [NSString stringWithFormat:@"SELECT Version FROM PropertyList_VERSION"];
 
 sqlite3_stmt *statement = NULL;
 
 SQLOK(__FILE__,__LINE__,SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database);
 
 if (sqlite3_step(statement) == SQLITE_ROW)
 {
 rtn = sqlite3_column_int(statement, 0);
 }
 
 SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), _database);
 }
 
 [self close:opened];
 return rtn;
 }
 */

- (BOOL)executeCmd:(const char *)cmd
{
    BOOL rtn = !SQLOK(__FILE__,__LINE__,SQLiteExec(_database, cmd, 0, 0, 0), _database);
    return rtn;
}

- (void)startTransaction
{
    SQLOK(__FILE__,__LINE__,SQLiteExec(_database, "BEGIN", 0, 0, 0), _database);
}

- (void)commitTransaction
{
    SQLOK(__FILE__,__LINE__,SQLiteExec(_database, "COMMIT", 0, 0, 0), _database);
}

+ (NSArray*)availablePropertyFields
{
    NSMutableArray *fields = [[NSMutableArray alloc]init];
    for (int i = 2;i<PFT_END;i++)
    {
        NSNumber *field = [NSNumber numberWithInteger:i];
        [fields addObject:field];
    }
    return fields.copy;
}

+ (NSString *)propertyFieldName:(PropFieldType)fieldType
{
    NSString *name = @"";
    
    switch (fieldType)
    {
        case PFT_LatLon:
        case PFT_END:
            break;
        case PFT_UserID:
            name = @"Name";
            break;
        case PFT_PIN:
            name = @"Unique Parcel ID (PIN)";
            break;
        case PFT_Address:
            name = @"Address";
            break;
        case PFT_Owner:
            name = @"Owner";
            break;
        case PFT_TaxPayer:
            name = @"Taxpayer";
            break;
        case PFT_ACRES:
            name = @"Acres";
            break;
        case PFT_Links:
            name = @"Links";
            break;
        case PFT_EMV_TOTAL:
            name = @"Total EMV";
            break;
        case PFT_EMV_BUILDING:
            name = @"Building EMV";
            break;
        case PFT_EMV_LAND:
            name = @"Land EMV";
            break;
        case PFT_EMV_LAND_PER_ACRE:
            name = @"EMV Land per Acre";
            break;
        case PFT_TOTAL_TAX:
            name = @"Total Tax";
            break;
        case PFT_SPEC_ASSESSMENT:
            name = @"Special Assessment";
            break;
        case PFT_RankEMV_block:
            name = @"EMV Rank (Block)";
            break;
        case PFT_RankEMV_blockgroup:
            name = @"EMV Rank (Block Group)";
            break;
        case PFT_PctOpenSpace_halfMile:
            name = @"PCT Open space (Half Mile)";
            break;
        case PFT_PctOpenSpace_Mile:
            name = @"PCT Open space (Mile)";
            break;
        case PFT_PctIndustrial_halfMile:
            name = @"PCT Industrial (Half Mile)";
            break;
        case PFT_PctIndustrial_Mile:
            name = @"PCT Industrial (Mile)";
            break;
        case PFT_Stability5yr_block:
            name = @"Stability (5 year Block)";
            break;
        case PFT_Stability5yr_blockgroup:
            name = @"Stability (5 year Block Group)";
            break;
        case PFT_Stability15yr_block:
            name = @"Stability (15 year Block)";
            break;
        case PFT_Stability15yr_blockgroup:
            name = @"Stability (15 year Block Group)";
            break;
        case PFT_Stability5yr_Mile:
            name = @"Stability (5 year Mile)";
            break;
        case PFT_Stability5yr_halfMile:
            name = @"Stability (5 year Half Mile)";
            break;
        case PFT_Stability15yr_Mile:
            name = @"Stability (15 year Mile)";
            break;
        case PFT_Stability15yr_halfMile:
            name = @"Stability (15 year Half Mile)";
            break;
        case PFT_DistanceToDestinations:
            name = @"Distance to Destinations (Miles per Month)";
            break;
        case PFT_TimeToDestinations:
            name = @"Time to Destinations (Hours per Month)";
            break;
        case PFT_PctHomestead_block:
            name = @"PCT Homestead (Block)";
            break;
        case PFT_PctHomestead_blockgroup:
            name = @"PCT Homestead (Block Group)";
            break;
        case PFT_PctHomeOwn_block:
            name = @"PCT Home Ownership (Block)";
            break;
        case PFT_PctHomeOwn_blockgroup:
            name = @"PCT Home Ownership (Block Group)";
            break;
        case PFT_MedianAgePop_block:
            name = @"Median Age Population (Block)";
            break;
        case PFT_MedianAgePop_blockgroup:
            name = @"Median Age Population (Block Group)";
            break;
        case PFT_MedianBuiltYear_block:
            name = @"Median Year Built (Block)";
            break;
        case PFT_MedianBuiltYear_blockgroup:
            name = @"Median Year Built (Block Group)";
            break;
        case PFT_PctChildren_block:
            name = @"PCT Children (Block)";
            break;
        case PFT_PctChildren_blockgroup:
            name = @"PCT Children (Block Group)";
            break;
        case PFT_MedianAgeChildren_block:
            name = @"Median Child Age (Block)";
            break;
        case PFT_MedianAgeChildren_blockgroup:
            name = @"Median Child Age (Block Group)";
            break;
        case PFT_MedianAgeAdults_block:
            name = @"Median Adult Age (Block)";
            break;
        case PFT_MedianAgeAdults_blockgroup:
            name = @"Median Adult Age (Block Group)";
            break;
        case PFT_PctSenior_block:
            name = @"PCT Seniors (Block)";
            break;
        case PFT_PctSenior_blockgroup:
            name = @"PCT Seniors (Block Group)";
            break;
        case PFT_PctResidential_halfMile:
            name = @"PCT Residential (Half Mile)";
            break;
        case PFT_PctResidential_Mile:
            name = @"PCT Residential (Mile)";
            break;
        case PFT_PctCommercial_halfMile:
            name = @"PCT Commercial (Half Mile)";
            break;
        case PFT_PctCommercial_Mile:
            name = @"PCT Commercial (Mile)";
            break;
        case PFT_PctOpenSpace_qtrMile:
            name = @"PCT Open Space (Qtr Mile)";
            break;
        case PFT_Stability5yr_qtrMile:
            name = @"Stability (5 year Qtr Mile)";
            break;
        case PFT_PctCommercial_qtrMile:
            name = @"PCT Commercial (Qtr Mile)";
            break;
        case PFT_PctIndustrial_qtrMile:
            name = @"PCT Industrial (Qtr Mile)";
            break;
        case PFT_Stability15yr_qtrMile:
            name = @"Stability (15 year Qtr Mile)";
            break;
        case PFT_PctResidential_qtrMile:
            name = @"PCT Residential (Qtr Mile)";
            break;
        case PFT_YearBuilt:
            name = @"Year Built";
            break;
        case PFT_LastSaleDate:
            name = @"Last Sale Date";
            break;
        case PFT_LastSalePrice:
            name = @"Last Sale Price";
            break;
        case PFT_ProsAndCons:
            name = @"Pros And Cons";
            break;
        case PFT_Ave_EMV_block:
            name = @"Average EMV (Block)";
            break;
        case PFT_Ave_EMV_blockgroup:
            name = @"Average EMV (Block Group)";
            break;
        case PFT_Ave_EMV_eighthMile:
            name = @"Average EMV (Eighth Mile)";
            break;
        case PFT_Ave_EMV_qtrMile:
            name = @"Average EMV (Qtr Mile)";
            break;
            
        default:break;
    }
    
    return name;
}
+ (BOOL)propertyAllowsWeight:(PropFieldType)fieldType
{
    BOOL rtn = TRUE;
    
    switch (fieldType)
    {
        case PFT_LatLon:
        case PFT_END:
        case PFT_UserID:
        case PFT_PIN:
        case PFT_Address:
        case PFT_Owner:
        case PFT_TaxPayer:
        case PFT_Links:
            rtn = FALSE;
            break;
        default:
            break;
    }
    
    return rtn;
}

NSString* propertyListFieldDescription (NSInteger fieldNumber)
{
    NSString *file;
    
    NSString *name = [NSString stringWithFormat:@"PropListField_%li",(long)fieldNumber];
    file = [NSBundle.mainBundle pathForResource:name ofType:@"pdf"];
    
    if (![NSFileManager.defaultManager fileExistsAtPath:file])
        file = [NSBundle.mainBundle pathForResource:@"PropListField_default" ofType:@"pdf"];
    return file;
}

- (CPFeatures)setFeatureTypeForField:(PropFieldType) field
{
    CPFeatures rtn = NVMetroSettings.sharedInstance.currentFeature;
    NVMetroSettings.sharedInstance.currentFeature = CPFLandUse;
    
    return rtn;
}
- (int)getBoundaryTypeForField:(PropFieldType) field
{
    int type = MAPIT_CIRCULAR;
    return type;
    /*switch (field)
     {
     case PFT_Stability5yr_block:
     case PFT_Stability15yr_block:
     case PFT_PctHomestead_block:
     case PFT_PctHomeOwn_block:
     case PFT_MedianAgePop_block:
     case PFT_MedianBuiltYear_block:
     case PFT_MedianAgeAdults_block:
     case PFT_PctChildren_block:
     case PFT_PctSenior_block:
     case PFT_RankEMV_block:
     type = MAPIT_AREA_BLOCK;
     break;
     case PFT_Stability5yr_blockgroup:
     case PFT_Stability15yr_blockgroup:
     case PFT_PctHomestead_blockgroup:
     case PFT_PctHomeOwn_blockgroup:
     case PFT_MedianAgePop_blockgroup:
     case PFT_MedianBuiltYear_blockgroup:
     case PFT_MedianAgeChildren_block:
     case PFT_PctChildren_blockgroup:
     case PFT_MedianAgeChildren_blockgroup:
     case PFT_MedianAgeAdults_blockgroup:
     case PFT_PctSenior_blockgroup:
     case PFT_RankEMV_blockgroup:
     type = MAPIT_AREA_BLOCKGRP;
     break;
     
     default:
     break;
     }
     
     return type;*/
}

+ (CGFloat)getRadiusForField:(PropFieldType)field
{
    CGFloat radius = 1.0;
    
    switch (field)
    {
        case PFT_Stability5yr_Mile:
        case PFT_Stability15yr_Mile:
        case PFT_PctOpenSpace_Mile:
        case PFT_PctIndustrial_Mile:
        case PFT_PctCommercial_Mile:
        case PFT_PctResidential_Mile:
            radius = 1.0;
            break;
        case PFT_Stability5yr_halfMile:
        case PFT_Stability15yr_halfMile:
        case PFT_PctOpenSpace_halfMile:
        case PFT_PctIndustrial_halfMile:
        case PFT_PctCommercial_halfMile:
        case PFT_PctResidential_halfMile:
            radius = 0.5;
            break;
        default:
            break;
    }
    
    return radius;
}

+ (PropBaseType)getBaseTypeForField:(PropFieldType) field
{
    PropBaseType bt=0;
    
    switch (field)
    {
        case PFT_Stability5yr_Mile:
        case PFT_Stability5yr_halfMile:
        case PFT_Stability15yr_Mile:
        case PFT_Stability15yr_halfMile:
            bt = PBT_Stability;
            break;
        case PFT_PctOpenSpace_Mile:
        case PFT_PctOpenSpace_halfMile:
            bt = PBT_OpenSpace;
            break;
        case PFT_PctIndustrial_Mile:
        case PFT_PctIndustrial_halfMile:
            bt = PBT_Industrial;
            break;
        case PFT_PctResidential_Mile:
        case PFT_PctResidential_halfMile:
            bt = PBT_Residential;
            break;
        case PFT_PctCommercial_Mile:
        case PFT_PctCommercial_halfMile:
            bt = PBT_Commercial;
            break;
        default:
            break;
    }
    
    return bt;
}

- (ValueTypes) getFieldValueType:(PropFieldType)type
{
    ValueTypes rtn = VTInteger;
    switch (type)
    {
        case PFT_LatLon:
            rtn = VTLLPoint;
            break;
        case PFT_UserID:
        case PFT_PIN:
        case PFT_Address:
        case PFT_Owner:
        case PFT_TaxPayer:
        case PFT_Links:
        case PFT_LastSaleDate:
            rtn = VTString;
            break;
        case PFT_ACRES:
            rtn = VTAcres;
            break;
        case PFT_EMV_TOTAL:
        case PFT_EMV_BUILDING:
        case PFT_EMV_LAND:
        case PFT_EMV_LAND_PER_ACRE:
        case PFT_TOTAL_TAX:
        case PFT_SPEC_ASSESSMENT:
        case PFT_LastSalePrice:
            rtn = VTDollars;
            break;
        default:
            rtn = VTInteger;
            break;
    }
    return rtn;
}

- (NSArray*) getPropertyNumbers
{
    NSMutableArray * propNums = [[NSMutableArray alloc]init];
    BOOL opened = [self open];
    NSString *query = [NSString stringWithFormat:@"SELECT DISTINCT PropNum FROM PropertyList"];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(__FILE__,__LINE__,SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        int propid = sqlite3_column_int(statement, 0);
        NSNumber * propNum = [NSNumber numberWithInt:propid];
        [propNums addObject:propNum];
    }
    
    SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), _database);
    [self close:opened];
    _numPropertiesInList = (int)propNums.count;
    return propNums.copy;
}

- (NSString *) getPIDforPropnum:(int)propNum
{
    NSString *PID = @"";
    NSString *query = [NSString stringWithFormat:@"SELECT FieldValue FROM PropertyList WHERE FieldType = %li AND Propnum = %i", (long)PFT_PIN,propNum];
    
    BOOL opened = [self open];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(__FILE__,__LINE__,SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR val;
        
        val = (LPSTR)sqlite3_column_blob(statement, 0);
        if (val)
        {
            PID = [NSString stringWithFormat:@"%s",val];
        }
    }
    
    SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), _database);
    [self close:opened];

    return PID;
}

- (NSArray*) getPIDS
{
    NSMutableArray * pids = [[NSMutableArray alloc]init];
    NSString *query = [NSString stringWithFormat:@"SELECT FieldValue FROM PropertyList WHERE FieldType = %li", (long)PFT_PIN];
    
    BOOL opened = [self open];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(__FILE__,__LINE__,SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR val;
        
        val = (LPSTR)sqlite3_column_blob(statement, 0);
        if (val)
        {
            NSString * value = [NSString stringWithFormat:@"%s",val];
            [pids addObject:value];
        }
    }
    
    SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), _database);
    [self close:opened];
    
    return pids.copy;
}

- (void) deleteProperty:(NSInteger)propNum
{
    NSString *query = [NSString stringWithFormat:@"DELETE FROM PropertyList WHERE Propnum = %li",(long)propNum];
    
    [self executeCmd:query.UTF8String];
}

- (void) getPropertyFieldValueOfType:(PropFieldType)type
                   forPropertyNumber:(NSInteger)propNum;
{
    NSString *value = @"";
    
    if (type == PFT_TimeToDestinations)
    {
        Destinations *dest = Destinations.new;
        
        CGFloat val = [dest totalValueForProperty:propNum ofType:type];
        value = [NSString stringWithFormat:@"%.1f", val/60.0];
    }
    
    else if (type == PFT_DistanceToDestinations)
    {
        Destinations *dest = Destinations.new;
        
        CGFloat val = [dest totalValueForProperty:propNum ofType:type];
        value = [NSString stringWithFormat:@"%.1f", val];
    }
    
    else
        value = [self getFieldValue:propNum type:type];
    
    if (value)
    {
        [self.delegate PropertyList:self
                       returnsValue:value
                  forPropertyNumber:propNum
                       andFieldType:type
                         withStatus:0];
    }
    
    else
    {
        switch (type)
        {
            case PFT_PctOpenSpace_halfMile:
                break;
            default:
                break;
        }
    }
    
    return;
}

- (int)getNearestProperty:(LLPOINT *)ll
         distanceInMeters:(double*)dist
{
    int rtn = 0;
    double minDist = DBL_MAX;
    DPOINT pt = {ll->lon,ll->lat};
    BOOL opened = [self open];
    NSArray *list = [self getPropertyNumbers];
    for (NSNumber *propNum in list)
    {
        int propnum = (int)propNum.integerValue;
        LLPOINT llp = [self getPropertyLatLon:propnum];
        DPOINT pt2 = {llp.lon,llp.lat};
        double d = ArcDistance(pt,pt2);
        
        if (d < minDist)
        {
            minDist = d;
            rtn = propnum;
        }
    }
    [self close:opened];
    *dist = minDist;
    return rtn;
}


- (BOOL)parcelInPropertyList:(NSString *)PIN
{
    BOOL rtn = FALSE;
    NSString *value = @"";
    NSString *query = [NSString stringWithFormat:@"SELECT FieldValue FROM PropertyList WHERE FieldType = %li", (long)PFT_PIN];
    
    BOOL opened = [self open];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(__FILE__,__LINE__,SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR val;
        
        val = (LPSTR)sqlite3_column_blob(statement, 0);
        if (val)
        {
            value = [NSString stringWithFormat:@"%s",val];
            if ([PIN isEqualToString:value])
            {
                rtn = TRUE;
                break;
            }
        }
    }
    
    SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), _database);
    [self close:opened];
    
    return rtn;
}


- (NSString *) getFieldValue:(NSInteger)propNum
                        type:(PropFieldType)fieldType
{
    NSString *value = @"";
    NSNumber *num;
    NSString *query = [NSString stringWithFormat:@"SELECT FieldValue FROM PropertyList WHERE PropNum = %li AND FieldType = %li",
                       (long)propNum, (long)fieldType];
    
    BOOL opened = [self open];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(__FILE__,__LINE__,SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR val;
        int ival;
        double dval;
        ValueTypes vt = [self getFieldValueType:fieldType];
        switch (vt)
        {
            case VTLLPoint:
            {
                LLPOINT pt = *(LLPOINT*)sqlite3_column_blob(statement, 0);
                value = [NSString stringWithFormat:@"%f %f",pt.lat,pt.lon];
            }
                break;
            case VTString:
                val = (LPSTR)sqlite3_column_blob(statement, 0);
                if (val)
                {
                    value = [NSString stringWithFormat:@"%s",val];
                    //                    value = [value stringByReplacingOccurrencesOfString:@"\r" withString:@" "];
                    //                    value = [value stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
                }
                break;
            case VTDollars:
                dval = *(double*)sqlite3_column_blob(statement, 0);
                num = [[NSNumber alloc] initWithDouble:dval];
                value = [CRAPI.sharedInstance.dollarFmt stringFromNumber:num];
                break;
            case VTDouble:
                dval = *(double*)sqlite3_column_blob(statement, 0);
                value = [NSString stringWithFormat:@"%f",dval];
                break;
            case VTAcres:
                dval = *(double*)sqlite3_column_blob(statement, 0);
                num = [[NSNumber alloc] initWithDouble:dval];
                value = [CRAPI.sharedInstance.acreFmt stringFromNumber:num];
                break;
            case VTInteger:
            default:
                ival = *(int*)sqlite3_column_blob(statement, 0);
                value = [NSString stringWithFormat:@"%i",ival];
                break;
        }
    }
    
    SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), _database);
    [self close:opened];
    
    return value;
}

- (NSString *) getFieldTotal:(PropFieldType)fieldType
{
    NSString *value = @"";
    ValueTypes type = [self getFieldValueType:fieldType];
    
    switch (type)
    {
        case VTDouble:
        case VTAcres:
        case VTDollars:
        {
            double totval = 0;
            NSNumber *num;
            int nval = 0;
            NSString *query = [NSString stringWithFormat:@"SELECT FieldValue FROM PropertyList WHERE FieldType = %li",(long)fieldType];
            
            BOOL opened = [self open];
            
            sqlite3_stmt *statement = NULL;
            
            SQLOK(__FILE__,__LINE__,SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database);
            
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                double dval = *(double*)sqlite3_column_blob(statement, 0);
                totval += dval;
                nval++;
            }
            SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), _database);
            [self close:opened];
            switch (type)
            {
                case VTDollars:
                    num = [[NSNumber alloc] initWithDouble:totval];
                    value = [CRAPI.sharedInstance.dollarFmt stringFromNumber:num];
                    break;
                case VTAcres:
                    num = [[NSNumber alloc] initWithDouble:totval];
                    value = [CRAPI.sharedInstance.acreFmt stringFromNumber:num];
                    break;
                default:
                    break;
            }
        }
    }
    return value;
}

- (NSString *) getFieldAverage:(PropFieldType)fieldType
{
    NSString *value = @"";
    ValueTypes type = [self getFieldValueType:fieldType];
    
    switch (type)
    {
        default:
            break;
            
        case VTDouble:
        case VTAcres:
        case VTDollars:
        {
            double totval = 0;
            int nval = 0;
            NSNumber *num;
            NSString *query = [NSString stringWithFormat:@"SELECT FieldValue FROM PropertyList WHERE FieldType = %li",(long)fieldType];
            
            BOOL opened = [self open];
            
            sqlite3_stmt *statement = NULL;
            
            SQLOK(__FILE__,__LINE__,SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database);
            
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                double dval = *(double*)sqlite3_column_blob(statement, 0);
                totval += dval;
                nval++;
            }
            SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), _database);
            [self close:opened];
            if (nval > 0)
            {
                totval /= nval;
                switch (type)
                {
                    case VTDollars:
                        num = [[NSNumber alloc] initWithDouble:totval];
                        value = [CRAPI.sharedInstance.dollarFmt stringFromNumber:num];
                        break;
                    case VTAcres:
                        num = [[NSNumber alloc] initWithDouble:totval];
                        value = [CRAPI.sharedInstance.acreFmt stringFromNumber:num];
                        break;
                    default:
                        break;
                }
            }
        }
    }
    return value;
}

- (int)nextPropNum
{
    int rtn = 1;
    
    NSString *query = [NSString stringWithFormat:@"SELECT max(PropNum) FROM PropertyList"];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(__FILE__,__LINE__,SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        rtn = sqlite3_column_int(statement, 0) + 1;
    }
    
    SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), _database);
    
    return rtn;
}

- (int)next_id
{
    int rtn = 1;
    
    NSString *query = [NSString stringWithFormat:@"SELECT max(id) FROM PropertyList"];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(__FILE__,__LINE__,SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        rtn = sqlite3_column_int(statement, 0) + 1;
    }
    
    SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), _database);
    
    return rtn;
}

-(NSString *) stringToBlob:(NSString*)str
{
    if (!str)
        str = @"";
    NSString * blob=@"";
    NSInteger sln = str.length;
    NSInteger lblb = 0;
    if (sln)
    {
        LPSTR blb = malloc (sln*2+4);
        LPSTR cstr = (LPSTR)str.UTF8String;
        for (NSInteger i = 0;i<sln;i++)
        {
            sprintf (&blb[lblb],"%2.2x",cstr[i]);
            lblb += 2;
        }
        blb[lblb] = 0;
        blob = [NSString stringWithUTF8String:blb];
        free (blb);
    }
    return blob;
}

-(NSString *) llpointsToBlob:(LLPOINT*)pPoints
                   numPoints:(NSInteger)nPnts
{
    NSString * blob=@"";
    NSInteger lBlob = 0;
    LPSTR pBlob = malloc(nPnts * sizeof(DPOINT)*2 +4);
    for (NSInteger i = 0; i < nPnts; i++)
    {
        NSInteger  j;
        LPBYTE pInts = (LPBYTE)&pPoints[i];
        //unsigned char c;
        for (j = 0; j < sizeof(DPOINT); j++, pInts++, lBlob += 2)
        {
            //c = *pInts;
            sprintf(&pBlob[lBlob], "%2.2x", *pInts);
        }
    }
    pBlob[lBlob] = 0;
    blob = [NSString stringWithUTF8String:pBlob];
    free (pBlob);
    return blob;
}
-(NSString *) doubleToBlob:(double)val
{
    NSString * blob=@"";
    NSInteger lBlob = 0;
    LPSTR pBlob = malloc(sizeof(double)*2+4);
    NSInteger  j;
    LPBYTE pInts = (LPBYTE)&val;
    //unsigned char c;
    for (j = 0; j < sizeof(double); j++, pInts++, lBlob += 2)
    {
        //c = *pInts;
        sprintf(&pBlob[lBlob], "%2.2x", *pInts);
    }
    pBlob[lBlob] = 0;
    blob = [NSString stringWithUTF8String:pBlob];
    free (pBlob);
    return blob;
}
-(NSString *) floatToBlob:(float)val
{
    NSString * blob=@"";
    NSInteger lBlob = 0;
    LPSTR pBlob = malloc(sizeof(float)*2+4);
    NSInteger  j;
    LPBYTE pInts = (LPBYTE)&val;
    //unsigned char c;
    for (j = 0; j < sizeof(float); j++, pInts++, lBlob += 2)
    {
        //c = *pInts;
        sprintf(&pBlob[lBlob], "%2.2x", *pInts);
    }
    pBlob[lBlob] = 0;
    blob = [NSString stringWithUTF8String:pBlob];
    free (pBlob);
    return blob;
}
-(NSString *) intToBlob:(int)val
{
    NSString * blob=@"";
    NSInteger lBlob = 0;
    LPSTR pBlob = malloc(sizeof(int)*2+4);
    NSInteger  j;
    LPBYTE pInts = (LPBYTE)&val;
    //unsigned char c;
    for (j = 0; j < sizeof(int); j++, pInts++, lBlob += 2)
    {
        //c = *pInts;
        sprintf(&pBlob[lBlob], "%2.2x", *pInts);
    }
    pBlob[lBlob] = 0;
    blob = [NSString stringWithUTF8String:pBlob];
    free (pBlob);
    return blob;
}

- (void)updatePropertyUserID:(NSInteger)propNum
                      userID:(NSString*)userID
{
    BOOL opened = [self open];
    [self startTransaction];
    NSString *PIDBlob = [self stringToBlob:userID];
    NSString * cmd = [NSString stringWithFormat:@"UPDATE PropertyList SET FieldValue = X'%@' WHERE PropNum = %li AND FieldType = %li",
                      PIDBlob,(long)propNum, (long)PFT_UserID];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    [self commitTransaction];
    [self close:opened];
}

- (LLPOINT)getPropertyLatLon:(NSInteger)propNum
{
    LLPOINT pt;
    BOOL opened = [self open];
    NSString * value = [self getFieldValue:propNum
                                      type:PFT_LatLon];
    
    pt = LLPOINTFromString (value);
    [self close:opened];
    return pt;
}

- (void)setZoomValues:(NSInteger)propNum
           withOption:(NSInteger)option
{
    BOOL opened = [self open];
    if (propNum == -1)
    {
        NSString * value = [self getFieldValue:propNum
                                          type:PFT_LatLon];
        PropertyData *pd = PropertyData.new;
        NSArray * pids = [self getPIDS];
        MNMXCORD fullBounds;
        DBoundsInit(&fullBounds);
        for (NSString *PID in pids)
        {
            MNMXCORD bounds = [pd getBoundsForPID:PID];
            AddMinMaxD (&fullBounds, &bounds);
        }
        NVMetroSettings.sharedInstance.savedVisibleBounds = fullBounds;
        LLPOINT center;
        center.lat = (fullBounds.ymn + fullBounds.ymx) / 2;
        center.lon = (fullBounds.xmn + fullBounds.xmx) / 2;
        ConfigurationControl.sharedInstance.MapitTargetCenterPoint = center;
        LLPOINT p1, p2;
        p1.lat = fullBounds.ymn;
        p1.lon = fullBounds.xmn;
        p2.lat = fullBounds.ymx;
        p2.lon = fullBounds.xmx;
        double dist = ArcDistanceLL(p1,p2) * 1.2;
        double radius = dist / METERS_PER_MILE;
        ConfigurationControl.sharedInstance.MapitCirularBoundaryRadiusInMiles = radius;
        [self close:opened];
        return;
    }
    NSString * PID = [self getFieldValue:propNum
                                    type:PFT_PIN];
    if (option == -1)
    {
        NSString * value = [self getFieldValue:propNum
                                          type:PFT_LatLon];
        ConfigurationControl.sharedInstance.MapitTargetCenterPoint = LLPOINTFromString (value);
        PropertyData *pd = PropertyData.new;
        MNMXCORD bounds = [pd getBoundsForPID:PID];
        NVMetroSettings.sharedInstance.savedVisibleBounds = bounds;
        LLPOINT p1, p2;
        p1.lat = bounds.ymn;
        p1.lon = bounds.xmn;
        p2.lat = bounds.ymx;
        p2.lon = bounds.xmx;
        double dist = ArcDistanceLL(p1,p2) * 1.5;
        double radius = dist / METERS_PER_MILE;
        ConfigurationControl.sharedInstance.MapitCirularBoundaryRadiusInMiles = radius;
        [self close:opened];
        return;
    }
    NSArray *fields = [PropertyList availablePropertyFields];
    if (option < fields.count)
    {
        NSNumber *field = fields[option];
        PropFieldType ifield = field.integerValue;
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
            ConfigurationControl.sharedInstance.MapitCirularBoundaryRadiusInMiles = [PropertyList getRadiusForField:ifield];
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
    }
    [self close:opened];
}

- (void) addString:(NSString*)value
          withCode:(int)code
{
    NSString * dataBlob = [self stringToBlob:value];
    NSString *cmd = [NSString stringWithFormat:@"INSERT INTO PropertyList VALUES (%i,%i,%i,%i,X'%@');",_dbid++,_PropNum,code,_PropVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    
}
- (void) addDouble:(double)value
          withCode:(int)code
{
    NSString * dataBlob = [self doubleToBlob:value];
    NSString *cmd = [NSString stringWithFormat:@"INSERT INTO PropertyList VALUES (%i,%i,%i,%i,X'%@');",_dbid++,_PropNum,code,_PropVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
}
- (void) addInt:(int)value
       withCode:(int)code
{
    NSString * dataBlob = [self intToBlob:value];
    NSString *cmd = [NSString stringWithFormat:@"INSERT INTO PropertyList VALUES (%i,%i,%i,%i,X'%@');",_dbid++,_PropNum,code,_PropVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
}
- (void) addLLPoints:(LLPOINT*)pidPoint
           numPoints:(int)np
            withCode:(int)code
{
    NSString *dataBlob = [self llpointsToBlob:pidPoint
                                    numPoints:np];
    NSString *cmd = [NSString stringWithFormat:@"INSERT INTO PropertyList VALUES (%i,%i,%i,%i,X'%@');",_dbid++,_PropNum,code,_PropVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
}

- (BOOL)addParcelToPropertyList:(NSString *)PID
                        popover:(GSSiPopoverView *)popover
{
    BOOL rtn = NO;
    
    _popover = popover;
    PropertyData *propData = [[PropertyData alloc] init];
    LLPOINT pidPoint = [propData getPointForPID:PID];
    
    //add address to Proplist
    NSString *houseAndUnit = @"";
    NSString *streetName = @"";
    NSString *city = @"";
    NSString *cenblock = @"";
    NSString *owner = @"";
    NSString *taxpayer = @"";
    double landEMV = 0;
    double bldgEMV = 0;
    double totTax = 0;
    double specAssmt = 0;
    double acres = 0;
    double saleValue = 0;
    NSString * usedesc;
    NSString * saleDate;
    
    [propData getAddressForPID:PID
               houseNumAndUnit:&houseAndUnit
                    streetName:&streetName
                          city:&city
                     ownerName:&owner
                  taxpayerName:&taxpayer
                   censusBlock:&cenblock
                       useDesc:&usedesc
                      saleDate:&saleDate
                     saleValue:&saleValue
                        totEMV:&_totEMV
                       landEMV:&landEMV
                       bldgEMV:&bldgEMV
                        totTAX:&totTax
                       specAss:&specAssmt
                         acres:&acres];
    
    char cenBlock[20];
    strcpy (cenBlock, cenblock.UTF8String);
    cenBlock[12] = 0;
    _usedesc = usedesc;
    _rhCompute = RiteHomeCompute.new;
    _rhCompute.propData = propData;
    _rhCompute.propList = self;
    DATA_FROM_PARCELS *values_blockgroup = DATA_FROM_PARCELS.new;
    DATA_FROM_PARCELS *values_block = DATA_FROM_PARCELS.new;
    
    [_rhCompute computeValuesFromParcelsInCensus:values_blockgroup
                                    inCensusArea:(LPSTR)cenBlock
                                          totEMV:(int)_totEMV
                                         useDesc:(LPSTR)_usedesc.UTF8String];
    
    
    [_rhCompute computeValuesFromParcelsInCensus:values_block
                                    inCensusArea:(LPSTR)cenblock.UTF8String
                                          totEMV:(int)_totEMV
                                         useDesc:(LPSTR)_usedesc.UTF8String];
    
    BOOL opened = [self open];
    [self startTransaction];
    
    _dbid = [self next_id];
    _PropNum = [self nextPropNum];
    _PropVersion = [propData propertyDatasetVersion];
    NSString *dataBlob;
    NSString *address = [NSString stringWithFormat:@"%@ %@\n%@",houseAndUnit,streetName,city];
    
    [self addLLPoints:&pidPoint numPoints:1 withCode:PFT_LatLon];
    
    [self addString:PID       withCode:PFT_PIN];
    [self addString:PID       withCode:PFT_UserID];
    [self addString:address   withCode:PFT_Address];
    [self addDouble:_totEMV   withCode:PFT_EMV_TOTAL];
    [self addDouble:landEMV   withCode:PFT_EMV_LAND];
    [self addDouble:bldgEMV   withCode:PFT_EMV_BUILDING];
    [self addDouble:totTax    withCode:PFT_TOTAL_TAX];
    [self addDouble:specAssmt withCode:PFT_SPEC_ASSESSMENT];
    [self addDouble:acres     withCode:PFT_ACRES];
    if (acres > 0)
    {
        double landPerAcre = landEMV/acres;
        [self addDouble:landPerAcre withCode:PFT_EMV_LAND_PER_ACRE];
    }
    [self addString:owner     withCode:PFT_Owner];
    [self addString:taxpayer  withCode:PFT_TaxPayer];
    [self addString:saleDate  withCode:PFT_LastSaleDate];
    [self addDouble:saleValue withCode:PFT_LastSalePrice];
    
    [self addInt:values_block.rankTotEMV      withCode:PFT_RankEMV_block];
    [self addInt:values_block.pctHomestead    withCode:PFT_PctHomestead_block];
    [self addInt:values_block.medianBuiltYear withCode:PFT_MedianBuiltYear_block];
    [self addInt:values_block.stability_5yr   withCode:PFT_Stability5yr_block];
    [self addInt:values_block.stability_15yr  withCode:PFT_Stability15yr_block];
    
    [self addInt:values_blockgroup.rankTotEMV      withCode:PFT_RankEMV_blockgroup];
    [self addInt:values_blockgroup.pctHomestead    withCode:PFT_PctHomestead_blockgroup];
    [self addInt:values_blockgroup.medianBuiltYear withCode:PFT_MedianBuiltYear_blockgroup];
    [self addInt:values_blockgroup.stability_5yr   withCode:PFT_Stability5yr_blockgroup];
    [self addInt:values_blockgroup.stability_15yr  withCode:PFT_Stability15yr_blockgroup];
    
    rtn = YES;
    
    dispatch_queue_t getSlowValueQue = dispatch_queue_create("getSlowValuesQueue",NULL);
    
    dispatch_async(getSlowValueQue,
                   ^{
                       GetSlowValues *sv = [[GetSlowValues alloc]init];
                       [sv computeSlowValues:_PropNum
                                        dbid:_dbid
                                    delegate:self
                                     popover:_popover
                                aroundLatLon:pidPoint
                                     useDesc:(LPSTR)usedesc.UTF8String];
                   });
    
    //[self close:opened];
    return rtn;
}

- (BOOL)executePropListCommand:(NSString *)cmd
{
    BOOL rtn = [self executeCmd:(LPSTR)cmd.UTF8String];
    return rtn;
}
- (void)getSlowValuesDidComplete:(int)propNum
                     totComputes:(float)totComputes
                     numComputes:(float)nComputes
{
    BOOL opened = [self open];
    if (!opened)
    {
        DATA_FROM_PARCELS *values_eighthMile = DATA_FROM_PARCELS.new;
        DATA_FROM_PARCELS *values_quarterMile = DATA_FROM_PARCELS.new;
        DATA_FROM_PARCELS *values_halfMile = DATA_FROM_PARCELS.new;
        DATA_FROM_BLOCKS *values_block_eighthMile = DATA_FROM_BLOCKS.new;
        DATA_FROM_BLOCKS *values_block_quarterMile = DATA_FROM_BLOCKS.new;
        DATA_FROM_BLOCKS *values_block_halfMile = DATA_FROM_BLOCKS.new;
        DATA_FROM_LANDUSE *values_landUse_eighthMile = DATA_FROM_LANDUSE.new;
        DATA_FROM_LANDUSE *values_landUse_quarterMile = DATA_FROM_LANDUSE.new;
        DATA_FROM_LANDUSE *values_landUse_halfMile = DATA_FROM_LANDUSE.new;
        
        [_rhCompute computeValuesFromParcelsInCircle:values_eighthMile
                                         forProperty:propNum
                                            inCircle:1
                                              totEMV:(int)_totEMV
                                             useDesc:(LPSTR)_usedesc.UTF8String];
        nComputes++;
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [_popover updateProgress:nComputes/totComputes];
                       });
        [_rhCompute computeValuesFromParcelsInCircle:values_quarterMile
                                         forProperty:propNum
                                            inCircle:2
                                              totEMV:(int)_totEMV
                                             useDesc:(LPSTR)_usedesc.UTF8String];
        
        nComputes++;
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [_popover updateProgress:nComputes/totComputes];
                       });
        [_rhCompute computeValuesFromParcelsInCircle:values_halfMile
                                         forProperty:propNum
                                            inCircle:3
                                              totEMV:(int)_totEMV
                                             useDesc:(LPSTR)_usedesc.UTF8String];
        
        nComputes++;
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [_popover updateProgress:nComputes/totComputes];
                       });
        
        [_rhCompute computeValuesFromBlocksInCircle:values_block_eighthMile
                                        forProperty:propNum
                                           inCircle:1];
        
        nComputes++;
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [_popover updateProgress:nComputes/totComputes];
                       });
        
        [_rhCompute computeValuesFromBlocksInCircle:values_block_quarterMile
                                        forProperty:propNum
                                           inCircle:2];
        
        nComputes++;
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [_popover updateProgress:nComputes/totComputes];
                       });
        
        [_rhCompute computeValuesFromBlocksInCircle:values_block_halfMile
                                        forProperty:propNum
                                           inCircle:3];
        
        nComputes++;
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [_popover updateProgress:nComputes/totComputes];
                       });
        
        [_rhCompute computeValuesFromLandUseInCircle:values_landUse_eighthMile
                                         forProperty:propNum
                                            inCircle:1];
        
        nComputes++;
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [_popover updateProgress:nComputes/totComputes];
                       });
        
        [_rhCompute computeValuesFromLandUseInCircle:values_landUse_quarterMile
                                         forProperty:propNum
                                            inCircle:2];
        
        nComputes++;
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [_popover updateProgress:nComputes/totComputes];
                       });
        
        [_rhCompute computeValuesFromLandUseInCircle:values_landUse_halfMile
                                         forProperty:propNum
                                            inCircle:3];
        
        nComputes++;
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [_popover updateProgress:nComputes/totComputes];
                       });
        
        int dbid = [self next_id];
        NSString *dataBlob = [self intToBlob:values_quarterMile.stability_5yr];
        NSString *cmd = [NSString stringWithFormat:@"INSERT INTO PropertyList VALUES (%i,%i,%i,%i,X'%@');",dbid++,propNum,(int)PFT_Stability5yr_qtrMile,_propVersion,dataBlob];
        [self executeCmd:(LPSTR)cmd.UTF8String];
        [self commitTransaction];
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [_popover updateProgress:1.0];
                           [_popover hide];
                       });
        
    }
    [self close:opened];
}

/*
 Top spreadsheet fields
 ProsAndCons
 TraveLess
 Average Market Value
 Average, median Home Age
 Percent new homes (5 yr)
 Percent new homes (15 yr)
 Percent Open Space/Parks
 Percent Commercial
 Percent Industrial
 Miles of major roads
 Stability
 Homestead rate
 Homestead trend
 Age mean, median and distribution
 Income
 Percent Single Family
 Percent vote Republican
 Percent vote Democrat
 Percent with children
 Percent single parent
 Ave no of children
 Ave age of children
 School data
 */

- (void) GSSiPopoverViewdidCancel:(GSSiPopoverView *)popoverView
{
    
}

- (NSArray*) getAreaRecords:(NSInteger)propNum
{
    BOOL opened = [self open];
    NSMutableArray *array = NSMutableArray.new;
    NSString *query = [NSString stringWithFormat:@"SELECT AreaType ,AreaID, Distance, SQMetersInCircle, PercentOfCircle FROM AreasWithinDistance WHERE PropNum = %li",(long)propNum];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(__FILE__,__LINE__,SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        int i = 0;
        int areaType = sqlite3_column_int(statement, i++);
        LPSTR cval = (LPSTR)sqlite3_column_text(statement, i++);
        NSString * areaID = [NSString stringWithUTF8String:cval];
        int iDist = sqlite3_column_int(statement, i++);
        double sqrMetersInCircle = sqlite3_column_double(statement, i++);
        double percentOfCircle = sqlite3_column_double(statement, i++);
        if (areaType == MBL_Parcels)
        {
            NSString *PID = [PropertyData getPIDforPolyID:(int)areaID.integerValue];
            areaID = PID;
        }
        NSString * line = [NSString stringWithFormat:@"%i:%@ %i %f %f",areaType,areaID,iDist,sqrMetersInCircle,percentOfCircle];
        [array addObject:line];
    }
    
    SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), _database);
    [self close:opened];
    
    return array.copy;
}
@end
