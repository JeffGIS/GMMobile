//  CreateBatchCrimeMaps.h
//  NVMobile

@import Foundation;
#import "CCodeLibrary/CCodeLibrary.h"

@interface CreateBatchCrimeMaps : NSObject

- (void)createImages:(NSString *)batchName
             popover:(GSSiPopoverView *)popover;

@end
