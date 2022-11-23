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

@interface UserWaypoint : NSObject
@property (nonatomic) int refno;
@property (nonatomic) LLPOINT latlon;
@property (nonatomic) NSString * name;
@property (nonatomic) NSString *type;
@property (nonatomic) NSString *desc;
@property int time;
@property int displayOnCompass;
@property CGFloat headingInDeg;
@end

@interface HuntingData : NSObject
@property int processingID;
@property sqlite3nv *database;
@property (atomic) BOOL isOpen;
@property (nonatomic, copy) NSString *datasetVersion;
@property (nonatomic, copy) NSString *NWIVersion;
@property (nonatomic, copy) NSString *ForestVersion;
@property (nonatomic, copy) NSString *FEESURFVersion;
@property int zoom;
@property ItemProcessingPassTypes pass;
@property int numPass;
@property INT64 totRecords;
@property MNMXCORD NWIBounds;
@property MNMXCORD ForestBounds;
@property MNMXCORD FEESURFBounds;
@property MNMXCORD RoadsBounds;
@property double huntingFactor;
@property double NWIFactor;
@property double ForestFactor;
@property double FEESURFFactor;
@property FILE *fidNWIBin;
@property FILE *fidForestBin;
@property FILE *fidFEESURFBin;
- (BOOL)open;
- (void)close:(BOOL)opened;
-(BOOL)addWaypoint:(NSString*)name
              type:(NSString *)type
            latlon:(LLPOINT)ll
       description:(NSString *)desc
  displayOnCompass:(BOOL)displayOnCompass;
-(NSArray *)getWaypoints;
-(int) deleteAllWaypoints;
-(int) deleteWaypointsOfType:(NSString*)type;

@end
