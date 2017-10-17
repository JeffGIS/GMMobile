//
//  CreateBatchCrimeMaps.h
//  NVMobile
//
//  Created by Jeff Smith on 10/15/17.
//  Copyright © 2017 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCodeLibrary/CCodeLibrary.h"

@interface CreateBatchCrimeMaps : NSObject

- (void)createImages:(NSString *)batchName
             popover:(GSSiPopoverView*)popover;

@end
