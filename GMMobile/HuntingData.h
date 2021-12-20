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
@property (nonatomic, copy) NSString *datasetVersion;
@property (nonatomic, copy) NSString *NWIVersion;
@property int zoom;
@property ItemProcessingPassTypes pass;
@property int numPass;
@property INT64 totRecords;
@property MNMXCORD NWIBounds;
@property MNMXCORD RoadsBounds;
@property double huntingFactor;
@property double NWIFactor;
@property FILE *fidNWIBin;
- (BOOL)open;
- (void)close:(BOOL)opened;

@end
