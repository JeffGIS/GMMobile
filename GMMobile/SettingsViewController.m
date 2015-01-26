//  SettingsViewController.m
//  GMMobile

#import "SettingsViewController.h"
#import "PropertyData.h"

@interface SettingsViewController ()

@property (nonatomic) GSSiPopoverView *popover;

@end

@implementation SettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _popover = [[GSSiPopoverView alloc] initWithView:self.view];
    _popover.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)loadDatabase:(id)sender
{
    NSString *documentsDirectory = UserDefaults.defaults.localFilePath;
    NSString *fileName = @"Property.sqltran";
    
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
        FILE *fid = fopen (path.UTF8String, "rb");
        LPSTR str = malloc(USHRT_MAX);
        PropertyData *pd = [[PropertyData alloc] init];
        [pd clear];
        [pd startTransaction];
        
        while (fgetstring(str, (USHRT_MAX - 2), fid))
            [pd executeCmd:str];
        
        [pd commitTransaction];
        fclose(fid);
        free(str);
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