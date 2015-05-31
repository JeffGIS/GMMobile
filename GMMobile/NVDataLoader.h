//  NVDataLoader.h
//  GMMobile

#import "CCodeLibrary/CCodeLibrary.h"
#import <Foundation/Foundation.h>
#import "SettingsViewController.h"
#import "ConfigurationControl.h"

#define NVDL_USERCANCELLED  1
#define NVDL_TRANSFERFAILED  2

@class NVDataLoader;

@protocol NVDataLoaderDelegate <NSObject>

- (void) NVDataLoaderSuccess;
- (void) NVDataLoaderFailed:(int)status;

@end

@interface NVDataLoader : NSObject <GSSiPopoverViewDelegate, SettingsViewControllerDelegate>
@property (nonatomic, weak) id <NVDataLoaderDelegate> delegate;
@property NSMutableArray *dbList;
@property id saveDelegate;
@property GSSiPopoverView *popover;
@property SettingsViewController *svc;
@property NSTimer *timer;

- (void)loadNVData:(HardCodedConfigs)appID
           popover:(GSSiPopoverView *)popover;

@end