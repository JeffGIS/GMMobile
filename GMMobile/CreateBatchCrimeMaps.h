//  CreateBatchCrimeMaps.h
//  NVMobile

@import Foundation;
#import "CCodeLibrary/CCodeLibrary.h"
#import "CrimeDataDisplay.h"

@interface CreateBatchCrimeMaps : NSObject<GSSiPopoverViewDelegate>

@property CrimeDataDisplay *cd;
@property (nonatomic) dispatch_queue_t backgroundCrimeQueue;
@property GSSiPopoverView *popover;
@property NSString * pdfFile;
@property NSTimer *timer;
@property NSMutableArray *pageArray;

- (void)createImages:(NSString *)batchName
             popover:(GSSiPopoverView *)popover;

@end
