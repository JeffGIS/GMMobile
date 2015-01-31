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
    
    if (status == FTPStatusOK)
    {
        PropertyData *pd = [[PropertyData alloc] init];
        [pd clear];
        _popover.title = @"Load Property File";
        dispatch_queue_t overallQueue = dispatch_queue_create("overallQueue",NULL);
        
        dispatch_async(overallQueue,
        ^{
            FILE *fid = fopen (path.UTF8String, "rb");
            LPSTR str = malloc(USHRT_MAX);
            fseek(fid, 0, SEEK_END);
            CGFloat totLen = ftell (fid);
            fseek(fid, 0, SEEK_SET);
            [pd startTransaction];
            
            while (fgetstring(str, (USHRT_MAX - 2), fid))
            {
                [pd executeCmd:str];
                dispatch_async(dispatch_get_main_queue(),
                ^{
                    [_popover updateProgress:ftell(fid)/totLen];
                });
            }
            
            [pd commitTransaction];
            fclose(fid);
            free(str);
            [_popover hide];
       });
    }
}

- (IBAction)preloadTiles:(id)sender
{
    PropertyData *pd = [[PropertyData alloc] init];
    [pd loadParcelPolygons:@""];
 
}

-(void)GSSiPopoverViewdidCancel:(GSSiPopoverView *)popoverView
{
    [_popover hide];
}

@end