//
//  DTMData.h
//  NVMobile
//
//  Created by Jeff Smith on 1/4/23.
//  Copyright © 2023 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCodeLibrary/CCodeLibrary.h"

NS_ASSUME_NONNULL_BEGIN

@interface DTMData : NSObject
@property int processingID;
@property sqlite3nv *database;
@property (atomic) BOOL isOpen;
@property MNMXCORD DTMBounds;
@property FILE *fidDTM;
@property FILE *fidDTM_IN1;
@property BOOL haveDTM;
- (BOOL)open;
- (void)close:(BOOL)opened;

@end

NS_ASSUME_NONNULL_END
