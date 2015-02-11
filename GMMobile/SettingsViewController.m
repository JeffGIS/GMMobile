//  SettingsViewController.m
//  GMMobile

#import "SettingsViewController.h"
#import "PropertyData.h"
#import "GSSiTileOverlay.h"

#define GET_PROPERTY    1
#define GET_TILES       2
#define GET_PARCELS     3

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

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    PropertyData *pd = [[PropertyData alloc] init];
    [pd open];
    _databaseSize.text = [NSString stringWithFormat:@"Database Size: %lld", pd.fileSize];
    [pd close];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}
- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}
- (IBAction)deleteDatabase:(id)sender
{
    NSString *title = @"Delete Property Records Database";
    
    if (UIAlertController.class)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                               style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction *action){
                                                                 
                                                                 [alert dismissViewControllerAnimated:YES
                                                                                           completion:nil];
                                                             }];
        
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Delete Database"
                                                                style:UIAlertActionStyleDestructive
                                                              handler:^(UIAlertAction *action){
                                                                  
                                                                  [alert dismissViewControllerAnimated:YES
                                                                                            completion:nil];
                                                                  
                                                                  [self databaseDeletion];
                                                              }];
        
        [alert addAction:cancelAction];
        [alert addAction:defaultAction];
        
        [self presentViewController:alert
                           animated:YES
                         completion:nil];
    }
    
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"DeleteDatabase", nil];
        
        [alertView show];
    }
}

- (void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        [self databaseDeletion];
    }
}

- (void)databaseDeletion
{
    PropertyData *pd = [[PropertyData alloc] init];
    [pd clear];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)FTPdidComplete:(int)option withStatus:(int)status
              filePath:(NSString *)path
{
    if (status == FTPStatusOK)
    {
        switch (option)
        {
            case GET_PARCELS:
            case GET_PROPERTY:
            {
                NSString *toDirectory = [path stringByDeletingLastPathComponent];
                NSString *file;
                
                if (!DecompressGMZipFile((LPSTR)path.UTF8String, (LPSTR)toDirectory.UTF8String))
                    break;
                
                if (option == GET_PARCELS)
                {
                    file = [NSString stringWithFormat:@"%@/parcelpoly.sqltran",toDirectory];
                     _popover.title = @"Load Parcel Tables";
                }
                
                else
                {
                    file = [NSString stringWithFormat:@"%@/property.sqltran",toDirectory];
                    _popover.title = @"Load Property Tables";
                }
                
                dispatch_queue_t overallQueue = dispatch_queue_create("overallQueue",NULL);
                
                dispatch_async(overallQueue,
                ^{
                    FILE *fid = fopen(file.UTF8String, "rb");
                    LPSTR str = malloc(USHRT_MAX * 8);
                    
                    if (!str)
                    {
                        dispatch_async(dispatch_get_main_queue(),
                                       ^{
                                           _popover.title = @"Failed to get memory. Hit cancel to continue";
                                       });
                    }
                    else
                    {
                        PropertyData *pd = [[PropertyData alloc] init];
                        [pd open];
                        fseek(fid, 0, SEEK_END);
                        CGFloat totLen = ftell(fid);
                        fseek(fid, 0, SEEK_SET);
                        [pd startTransaction];
                        
                        while (fgetstring(str, (USHRT_MAX*8 - 2), fid))
                        {
                            [pd executeCmd:str];
                            
                            dispatch_async(dispatch_get_main_queue(),
                                           ^{
                                               [_popover updateProgress:ftell(fid) / totLen];
                                           });
                        }
                        
                        [pd commitTransaction];
                        [pd close];
                        fclose(fid);
                        free(str);
                        
                        dispatch_async(dispatch_get_main_queue(),
                                       ^{
                                           [_popover hide];
                                       });
                    }
                });
                }
            
                break;
                
            case GET_TILES:
            {
                [self loadTilesFromList:path
                          updatePopover:_popover];
            }
                break;
        }
    }
    else
    {
        [_popover hide];
        
        UIAlertView *getError = [[UIAlertView alloc] initWithTitle:@"Error getting parcel file"
                                                           message:@"Network communication error"
                                                          delegate:nil
                                                 cancelButtonTitle:@"Continue"
                                                 otherButtonTitles:nil];
        [getError show];
        
    }
}

- (IBAction)preloadTiles:(id)sender
{
    NSString *documentsDirectory = UserDefaults.defaults.localFilePath;
    NSString *fileName = @"PropTileList.txt";
    
    FTPDataPull *pull = FTPDataPull.pull;
    pull.delegate = self;
    pull.popover = _popover;
    pull.useOnlyPrimaryFTP = NO;
    pull.option = GET_TILES;
    
    [_popover showAfter:0.5
              withTitle:@"Get Tilelist File"];
    
    [pull getFile:fileName
    fromDirectory:@"GMMobile"
           toFile:fileName
      toDirectory:documentsDirectory
     forceRefresh:NO];
    
}

- (IBAction)loadDatabase:(id)sender
{
    NSString *documentsDirectory = UserDefaults.defaults.localFilePath;
    NSString *fileName = @"MPLS_propfiles.gcf";
    
    if (CRAPI.sharedInstance.project == PROJECT_METROGIS)
        fileName = @"MetroGIS_propfiles.gcf";
    
    FTPDataPull *pull = FTPDataPull.pull;
    pull.delegate = self;
    pull.popover = _popover;
    pull.useOnlyPrimaryFTP = NO;
    pull.option = GET_PROPERTY;
    
    [_popover showAfter:0.5
              withTitle:@"Get Property File"];
    
    [pull getFile:fileName
    fromDirectory:@"GMMobile"
           toFile:fileName
      toDirectory:documentsDirectory
     forceRefresh:YES];
    
}

- (IBAction)loadParcels:(id)sender
{
    NSString *documentsDirectory = UserDefaults.defaults.localFilePath;
    NSString *fileName = @"MPLS_parcels.gcf";
    
    if (CRAPI.sharedInstance.project == PROJECT_METROGIS)
        fileName = @"MetroGIS_parcels.gcf";
    
    FTPDataPull *pull = FTPDataPull.pull;
    pull.delegate = self;
    pull.popover = _popover;
    pull.useOnlyPrimaryFTP = NO;
    pull.option = GET_PARCELS;
    
    [_popover showAfter:0.5
              withTitle:@"Get Parcel File"];
    
    [pull getFile:fileName
    fromDirectory:@"GMMobile"
           toFile:fileName
      toDirectory:documentsDirectory
     forceRefresh:YES];
}

- (BOOL)loadTilesFromList:(NSString*)fileList
           updatePopover:(GSSiPopoverView*)popover
{
    BOOL rtn = NO;
    unsigned long long fileSize = [NSFileManager.defaultManager attributesOfItemAtPath:fileList
                                                                                 error:nil].fileSize;
    
    _popover = popover;
    popover.delegate = self;
    popover.title = @"Load All Tiles";
    _condition = [[NSCondition alloc] init];
    
    dispatch_queue_t overallQueue = dispatch_queue_create("overallQueue", NULL);
  
    dispatch_async(overallQueue,
                   ^{
                       FILE *fid = fopen(fileList.UTF8String, "rb");
                       char line[34];
                       char *ploc;
                       int  numRequests = 0;
                       _keepGoing = YES;
                       
                       while (_keepGoing && fgetstring(line, 32, fid))
                       {
                           MKTileOverlayPath top;
                           top.contentScaleFactor = 1;
                           [_condition lock];
                           
                           while (numRequests > _nComplete + _nFailed + 4)
                               [_condition wait];
                           
                           [_condition unlock];
                           top.z = atoi(line);
                           ploc = strchr(line, '\\') + 1;
                           top.y = atoi(ploc);
                           ploc = strchr(ploc, '\\') + 1;
                           top.x = atoi(ploc);
                           numRequests++;
                           
                           dispatch_queue_t tileQueue = dispatch_queue_create("tileQueue", DISPATCH_QUEUE_CONCURRENT);
                           dispatch_async(tileQueue,
                                          ^{
                                              NSString *gmm = @"http://74.42.137.128/icons/MPLS/{z}/{y}/{x}.png";
                                              GSSiTileOverlay *to = [[GSSiTileOverlay alloc] initWithURLTemplate:gmm];
                                              to.canReplaceMapContent = YES;
                                              to.minimumZ = 12;
                                              to.maximumZ = 19;
                                              to.type = @"GMM";
                                              
                                              [to cacheTileAtPath:top
                                                        condition:_condition
                                                         complete:&_nComplete
                                                           failed:&_nFailed];
                                              
                                              dispatch_async(dispatch_get_main_queue(),
                                                             ^{
                                                                 [popover updateProgress:(CGFloat)ftell(fid) / fileSize];
                                                             });
                                          });
                      }
                       
                       fclose(fid);
                       [popover hide];
                   });
    
    return rtn;
}

- (void)GSSiPopoverViewdidCancel:(GSSiPopoverView *)popoverView
{
    _keepGoing = NO;
    [_popover hide];
}

@end