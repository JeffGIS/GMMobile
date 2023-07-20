//
//  DTMData.h
//  NVMobile
//
//  Created by Jeff Smith on 1/4/23.
//  Copyright © 2023 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCodeLibrary/CCodeLibrary.h"



HANDLE DTMOpen (LPSTR FileNameIN, double NULLElv,LPsqlite3nv database,FILE* fidBin,LPSHORT pSurfType,LPMNMXCORD pWindowBounds);
void DTMClose (LPHANDLE pHandle);
double NGIELV (DPOINT Point,HANDLE hSurf,short DesiredUnits);
double NGIELV_bci (DPOINT Point,HANDLE hSurf,short DesiredUnits);


NS_ASSUME_NONNULL_BEGIN

@interface DTMData : NSObject
@property int processingID;
@property sqlite3nv *database;
@property (atomic) BOOL isOpen;
@property MNMXCORD DTMBounds;
@property FILE *fidDTM;
@property FILE *fidDTM_BIN;
@property HANDLE hDTM;
@property double NullElv;
@property short surfType;
@property int version;
- (BOOL)open:(LPMNMXCORD) pBounds;
- (void)close:(BOOL)opened;
-(double)getElevation:(LLPOINT *)llpoint;


@end

NS_ASSUME_NONNULL_END
