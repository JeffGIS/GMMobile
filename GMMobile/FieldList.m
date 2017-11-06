//
//  FieldList.m
//  NVMobile
//
//  Created by JEFFREY E SMITH on 11/6/17.
//  Copyright © 2017 GSSi. All rights reserved.
//

#import "FieldList.h"

@implementation FieldListRecord
@end

@interface FieldList ()

@property NSString *fileName, *path;
@property NSString * fieldListDir;
@property sqlite3 *database;
@property BOOL isOpen;
@property unsigned long long fileSize;
@property int dbIsOpen;
@end

@implementation FieldList

NSString * GetFieldListDirectory (void)
{
    NSString * documentsDirectory = CRAPI.sharedInstance.documentsDirectory;
    NSString * propListDir = [NSString stringWithFormat:@"%@/FieldLists",documentsDirectory];
    [NSFileManager.defaultManager createDirectoryAtPath:propListDir
                            withIntermediateDirectories:YES
                                             attributes:nil
                                                  error:nil];
    
    return propListDir;
}

+ (NSArray *) getFieldLists
{
    NSString *dir = GetFieldListDirectory();
    NSMutableArray *array = [[NSMutableArray alloc]init];
    for (NSString *fileName in [NSFileManager.defaultManager contentsOfDirectoryAtPath:dir
                                                                                 error:nil])
    {
        NSString *leafName = textBefore (fileName.lastPathComponent,@".");
        [array addObject:leafName];
    }
    return array;
}

+ (void) createNewFieldList
{
    NSString *baseName = @"FieldList";
    
    int n = 1;
    NSArray * lists = [FieldList getFieldLists];
    n = (int)lists.count + 1;
    NSString *newName = [NSString stringWithFormat:@"%@%i", baseName, n];
    
    while (nameInList (newName,lists))
    {
        n++;
        newName = [NSString stringWithFormat:@"%@%i", baseName, n];
    }
    
    [UserDefaults.defaults saveString:newName
                               forKey:@"CurrentFieldList"];
    
}

+ (NSString*) getCurrentFieldListName
{
    NSString *name = [UserDefaults.defaults stringForKey:@"CurrentFieldList"];
    return name;
}

+ (BOOL) renameCurrentFieldList:(NSString *)newName
{
    FieldList *fl = [[FieldList alloc]init];
    NSString *currentFile = fl.path;
    NSString *newFile = [NSString stringWithFormat:@"%@/%@.sqlite", fl.fieldListDir, newName];
    
    [fl close:YES];
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
                               forKey:@"CurrentFieldList"];
    
    return TRUE;
}

+ (BOOL) deleteCurrentFieldList
{
    
    FieldList *fl = [[FieldList alloc]init];
    NSString *currentFile = fl.path;
    NSError *error = nil;
    [fl close:YES];
    if (![NSFileManager.defaultManager removeItemAtPath:currentFile error:&error])
    {
        NSLog(@"%@ file removal error", currentFile);
        return FALSE;
    }
    NSArray *lists = [FieldList getFieldLists];
    if (lists.count)
        [UserDefaults.defaults saveString:lists[0]
                                   forKey:@"CurrentFieldList"];
    else
        [UserDefaults.defaults saveString:@"FieldList1"
                                   forKey:@"CurrentFieldList"];
    
    return TRUE;
}

+ (BOOL) setCurrentFieldList:(NSString *)fieldList
//returns false if fieldlist does not exist
{
    BOOL rtn = NO;
    
    [UserDefaults.defaults saveString:fieldList
                               forKey:@"CurrentFieldList"];
    
    return  rtn;
}
- (id)init
{
    self = [super init];
    
    if (self)
    {
        _fieldListDir = GetFieldListDirectory ();
        _fileName = [UserDefaults.defaults stringForKey:@"CurrentFieldList"];
        
        if (!_fileName)
        {
            _fileName = @"FieldList1";
            [UserDefaults.defaults saveString:_fileName
                                       forKey:@"CurrentFieldList"];
        }
        
        _path = [NSString stringWithFormat:@"%@/%@.sqlite", _fieldListDir, _fileName];
        
        //int version = [self datasetVersion];
        
        if (CRAPI.sharedInstance.resetFieldList)
        {
            NSError *error = nil;
            
            [NSFileManager.defaultManager removeItemAtPath:_path
                                                     error:&error];
            
            if (error)
                NSLog(@"%@ file removal error", _fileName);
            
            CRAPI.sharedInstance.resetFieldList = NO;
        }
        
        [self createTables];
        
    }
    NSLog(@"Init property list %@", _fileName);
    
    return self;
}

- (void)dealloc
{
    [self close:YES];
    NSLog(@"FieldList Database dealloc");
}
- (BOOL)open
{
    BOOL rtn = NO;
    
    if (!_isOpen)
    {
        if (_dbIsOpen)
            NSLog(@"FieldList already open");
        _dbIsOpen++;
        _fileName = [UserDefaults.defaults stringForKey:@"CurrentFieldList"];
        _path = [NSString stringWithFormat:@"%@/%@.sqlite", _fieldListDir, _fileName];
        _isOpen = !SQLOK(__FILE__,__LINE__,sqlite3_open(_path.UTF8String, &_database), _database);
        _fileSize = [NSFileManager.defaultManager attributesOfItemAtPath:_path error:nil].fileSize;
        if (!_fileSize)
            [self initializeList];
        NSLog(@"Fieldlist open");
       rtn = YES;
    }
    
    return rtn;
}

- (void)close:(BOOL)opened
{
    if (opened && _isOpen)
    {
        NSLog(@"FieldList Database close");
        SQLOK(__FILE__,__LINE__,sqlite3_close(_database),_database);
        _isOpen = NO;
        _dbIsOpen--;
    }
}

- (void) initializeList
{
    [self createTables];
    NSArray *fields = [PropertyList availablePropertyFields];
    
    for (NSNumber *field in fields)
    {
        int ifield = (int)field.integerValue;
        NSString *cmd = @"";
        if (ifield == 2)
            cmd = [NSString stringWithFormat:@"INSERT INTO FieldList VALUES (%i, 1, 0);",ifield];
        else
            cmd = [NSString stringWithFormat:@"INSERT INTO FieldList VALUES (%i, 0, 0);",ifield];
        [self executeCmd:(LPSTR)cmd.UTF8String];
    }
}
- (BOOL) createTables
{
    BOOL opened = [self open];
    
    NSString *cmd =  @"CREATE TABLE IF NOT EXISTS FieldList (FieldType INTEGER PRIMARY KEY,Sequence INTEGER, Weight INTEGER);";
    BOOL rtn = !SQLOK(__FILE__,__LINE__,SQLiteExec(_database, cmd.UTF8String, 0, 0, 0), _database);
    [self close:opened];
    return rtn;
}

- (BOOL)executeCmd:(char *)cmd
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

+ (NSArray*)getFieldListRecords
{
    NSMutableArray *records = [[NSMutableArray alloc]init];
    FieldList *fl = FieldList.new;
    
    BOOL opened = [fl open];
    NSString *query = [NSString stringWithFormat:@"SELECT FieldType, Sequence, Weight FROM FieldList WHERE Sequence > 0 ORDER BY Sequence"];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(__FILE__,__LINE__,SQLitePrepare(fl.database, query.UTF8String, -1, &statement, 0), fl.database);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        FieldListRecord *flr = FieldListRecord.new;
        
        flr.type = sqlite3_column_int(statement, 0);
        flr.name = [PropertyList propertyFieldName:flr.type];
        flr.sequence = sqlite3_column_int(statement, 1);
        flr.weight = sqlite3_column_int(statement, 2);
        [records addObject:flr];
    }
    SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), fl.database);
    
    query = [NSString stringWithFormat:@"SELECT FieldType, Sequence, Weight FROM FieldList WHERE Sequence = 0"];
    
    SQLOK(__FILE__,__LINE__,SQLitePrepare(fl.database, query.UTF8String, -1, &statement, 0), fl.database);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        FieldListRecord *flr = FieldListRecord.new;
        
        flr.type = sqlite3_column_int(statement, 0);
        flr.name = [PropertyList propertyFieldName:flr.type];
        flr.sequence = sqlite3_column_int(statement, 1);
        flr.weight = sqlite3_column_int(statement, 2);
        [records addObject:flr];
    }
    SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), fl.database);

    [fl close:opened];
    return records.copy;
}
+ (void) setWeightFor:(PropFieldType)type
                   to:(int)weight
{
    FieldList *fl = FieldList.new;

    NSString *cmd = [NSString stringWithFormat:@"UPDATE FieldList SET Weight = %i WHERE FieldType = %li;",weight,(long)type];
    BOOL opened = [fl open];
    [fl executeCmd:(LPSTR)cmd.UTF8String];
    [fl close:opened];
}

+ (int) getMaxSequence
{
    int rtn = -1;
    FieldList *fl = FieldList.new;
    BOOL opened = [fl open];
    NSString *query = [NSString stringWithFormat:@"SELECT MAX(Sequence) FROM FieldList"];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(__FILE__,__LINE__,SQLitePrepare(fl.database, query.UTF8String, -1, &statement, 0), fl.database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        rtn = sqlite3_column_int(statement, 0);
    }
    
    SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), fl.database);
    
    [fl close:opened];
    return rtn;

}
+ (void) setSequenceFor:(PropFieldType)type
                     to:(int)sequence
{
    int startSequence = 0;
    int incSequence = 1;
    
    if (sequence == 0)
    {
        sequence = [FieldList getMaxSequence] + 1;
    }
    else if (sequence < 0)
    {
        startSequence = -sequence;
        incSequence = -1;
        sequence = 0;
    }
    FieldList *fl = FieldList.new;
    NSString *cmd = @"";
    BOOL opened = [fl open];
    
    if (startSequence)
    {
        cmd = [NSString stringWithFormat:@"UPDATE FieldList SET Sequence = Sequence + %i WHERE Sequence > %i;",incSequence, sequence];
        [fl executeCmd:(LPSTR)cmd.UTF8String];
    }
    cmd = [NSString stringWithFormat:@"UPDATE FieldList SET Sequence = %i WHERE FieldType = %li;",sequence,(long)type];
    [fl executeCmd:(LPSTR)cmd.UTF8String];
    [fl close:opened];
    
}

@end
