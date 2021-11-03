//
//  HuntingData.h
//  NVMobile
//
//  Created by Jeff Smith on 10/28/21.
//  Copyright © 2021 GSSi. All rights reserved.
//

#ifndef HuntingData_h
#define HuntingData_h

#endif /* HuntingData_h */
#import "CCodeLibrary/SQLiteLib.h"
#import "CCodeLibrary/CCodeLibrary.h"
#import "Themes.h"
#import "NVMetroSettings.h"

@interface HuntingData : NSObject
@property int processingID;
@property sqlite3nv *database;
@property (atomic) BOOL isOpen;
@property (nonatomic, copy) NSString *documentsDirectory;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *path;
@property NSInteger fileSize;
@property (nonatomic, copy) NSString *datasetVersion;
@property int zoom;
@property ItemProcessingPassTypes pass;
@property int numPass;
@property INT64 totRecords;

- (BOOL)open;
- (void)close:(BOOL)opened;

@end
