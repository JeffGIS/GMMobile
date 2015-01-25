//
//  SettingsViewController.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 1/25/15.
//  Copyright (c) 2015 GSSi. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()
{
    GSSiPopoverView *_popover;
}

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _popover = [[GSSiPopoverView alloc] initWithView:self.view];
    _popover.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)loadDatabase:(id)sender {
    NSString *documentsDirectory = UserDefaults.defaults.localFilePath;
    
    NSString *fileName = @"Property.sqlite";
    
    FTPDataPull *pull = FTPDataPull.pull;
    pull.delegate = self;
    pull.popover = _popover;
    pull.useOnlyPrimaryFTP = NO;

    [_popover showAfter:0.5
                  withTitle:@"Get Property File"];

    [pull getFile:fileName
    fromDirectory:@"GMMobile"
           toFile:fileName
      toDirectory:documentsDirectory
     forceRefresh:YES];

}
- (void)FTPdidComplete:(int)status
              filePath:(NSString *)path
{
    [_popover hide];
    if (status == FTPStatusOK)
    {
    }
}
- (IBAction)preloadTiles:(id)sender {
}
@end
