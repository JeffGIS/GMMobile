//  SettingsViewController.m
//  GMMobile

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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
<<<<<<< HEAD
    // Dispose of any resources that can be recreated.
}

- (IBAction)loadDatabase:(id)sender {
=======
}

- (IBAction)loadDatabase:(id)sender
{
>>>>>>> bb8336f7f303d7cdb4966aeb1ca8d40c50e48d26
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
- (IBAction)preloadTiles:(id)sender
{
    
}

-(void)GSSiPopoverViewdidCancel:(GSSiPopoverView *)popoverView
{
    [_popover hide];
}

@end
