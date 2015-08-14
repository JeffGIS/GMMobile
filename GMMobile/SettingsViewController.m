//  SettingsViewController.m
//  GMMobile

#import "SettingsViewController.h"
#import "PropertyData.h"
#import "AlleyWallData.h"
#import "AppDelegate.h"

#define INPUTBUFSIZE USHRT_MAX * 32

@interface SettingsViewController ()

@property (nonatomic) NSMutableArray *allPlats;
@property (nonatomic) NSInteger nextPlat;

@property (weak, nonatomic) IBOutlet UISwitch *locSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *extSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *legdSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *digtSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *markSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *mapSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *platSwitch;

@end

@implementation SettingsViewController

- (void) dealloc
{
    NSLog (@"SettingsVC released");
}
- (void) initFromDataLoader:(GSSiPopoverView*)popover
{
    _fromDataLoader = YES;
    _popover = popover;
    _keepGoing = NO;
    _saveDelegate = popover.delegate;
    _popover.delegate = self;
    [UIApplication.sharedApplication setIdleTimerDisabled:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _popover = [[GSSiPopoverView alloc] initWithView:self.view];
    _popover.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    AppDelegate *sharedAppDelegate = UIApplication.sharedApplication.delegate;
    
    _locSwitch.on = sharedAppDelegate.mapToolbar.wantUserLocation;
    _extSwitch.on = sharedAppDelegate.mapToolbar.wantExtents;
    _legdSwitch.on = sharedAppDelegate.mapToolbar.wantLegends;
    _digtSwitch.on = sharedAppDelegate.mapToolbar.wantDigitize;
    _markSwitch.on = sharedAppDelegate.mapToolbar.wantMarkerSwitch;
    _mapSwitch.on = sharedAppDelegate.mapToolbar.wantMapType;
    _platSwitch.on = sharedAppDelegate.mapToolbar.wantPlat;
    
    PropertyData *pd = [[PropertyData alloc] init];
    [pd open];
    _databaseSize.text = [NSString stringWithFormat:@"Database Size: %lld", pd.fileSize];
    [pd close];
    [UIApplication.sharedApplication setIdleTimerDisabled:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [UIApplication.sharedApplication setIdleTimerDisabled:NO];
}

- (IBAction)deleteDatabase:(id)sender
{
    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                      delegate:self
                                                         title:@"Delete Property Records Database"
                                               buttonTextArray:@[@"Cancel", @"OK"]
                                              destructiveIndex:1];
#pragma unused(alert)
}

- (void)alertView:(NVAlertView *)alertView
didTapButtonAtIndex:(NSInteger)buttonIndex
{
    [alertView hideLargeAlertView:YES];
    
    if (buttonIndex == 1)
        [self databaseDeletion];
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

- (void)FTPdidComplete:(int)option
            withStatus:(int)status
       andStatusString:(NSString *)statusString
              filePath:(NSString *)path
{
    if (status == FTPStatusOK || status == FTPStatusFileExists)
    {
        switch (option)
        {
            case GET_STORMPLAT:
                self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                              target:self
                                                            selector:@selector(getNextPlat)
                                                            userInfo:nil
                                                             repeats:NO];
                break;
                
            case GetDatabaseSettingParcels:
            case GetDatabaseSettingProperty:
            case GetDatabaseSettingAreas:
            case GetDatabaseSettingSewer:
            case GetDatabaseSettingPlan:
            case GetDatabaseSettingAlleyWall:
            case GetDatabaseSettingCurbRamp:
            case GetDatabaseSettingCensus:
            {
                NSString *toDirectory = path.stringByDeletingLastPathComponent;
                NSString *file;
                
                if (!DecompressGMZipFile((LPSTR)path.UTF8String, (LPSTR)toDirectory.UTF8String))
                    break;
                
                switch (option)
                {
                    case GetDatabaseSettingParcels:
                    {
                        file = [NSString stringWithFormat:@"%@/parcelpoly.sqltran",toDirectory];
                        _popover.title = @"Load Parcel Tables";
                    }
                        break;
                        
                    case GetDatabaseSettingCensus:
                    {
                        file = [NSString stringWithFormat:@"%@/censusdata.sqltran",toDirectory];
                        _popover.title = @"Load Census Tables";
                    }
                        break;
                        
                    case GetDatabaseSettingAreas:
                    {
                        file = [NSString stringWithFormat:@"%@/areapoly.sqltran",toDirectory];
                        _popover.title = @"Load Area Tables";
                    }
                        break;
                        
                    case GetDatabaseSettingPlan:
                    {
                        file = [NSString stringWithFormat:@"%@/planimetric.sqltran",toDirectory];
                        _popover.title = @"Load Planimetric Tables";
                    }
                        break;
                        
                    case GetDatabaseSettingAlleyWall:
                    {
                        file = [NSString stringWithFormat:@"%@/alleywall.sqltran",toDirectory];
                        _popover.title = @"Load AlleyWall Tables";
                    }
                        break;
                        
                    case GetDatabaseSettingCurbRamp:
                    {
                        file = [NSString stringWithFormat:@"%@/CurbRamp.sqltran",toDirectory];
                        _popover.title = @"Load Curb Ramp Tables";
                    }
                        break;
                        
                    case GetDatabaseSettingSewer:
                    {
                        file = [NSString stringWithFormat:@"%@/sewer.sqltran",toDirectory];
                        _popover.title = @"Load Sewer Tables";
                    }
                        break;
                        
                    case GetDatabaseSettingProperty:
                    {
                        file = [NSString stringWithFormat:@"%@/property.sqltran",toDirectory];
                        _popover.title = @"Load Property Tables";
                    }
                        break;
                }
                
                dispatch_queue_t overallQueue = dispatch_queue_create("overallQueue",NULL);
                
                dispatch_async(overallQueue,
                ^{
                    FILE *fid = fopen(file.UTF8String, "rb");
                    LPSTR str = malloc(INPUTBUFSIZE);
                    int status = 0;
                    
                    if (!str)
                    {
                        dispatch_async(dispatch_get_main_queue(),
                                       ^{
                                           _popover.title = @"Failed to get memory. Hit cancel to continue";
                                       });
                    }
                    
                    else
                    {
                        _keepGoing = YES;
                        PropertyData *pd;
                        SewerData *sd;
                        AlleyWallData *awd;
                        CurbRampData *crd;
                        
                        if (option == GetDatabaseSettingSewer)
                        {
                            sd = [[SewerData alloc] init];
                            [sd open];
                        }
                        
                        else if (option == GetDatabaseSettingAlleyWall)
                        {
                            awd = [[AlleyWallData alloc] init];
                            [awd open];
                        }
                        else if (option == GetDatabaseSettingCurbRamp)
                        {
                            crd = [CurbRampData databaseForGeoid:CRAPI.sharedInstance.currentGeoid];
                            [crd createIntersectionsTable];
                            [crd open];
                        }
                        
                        else
                        {
                            pd = [[PropertyData alloc] init];
                            [pd open];
                        }
                        
                        fseek(fid, 0, SEEK_END);
                        CGFloat totLen = ftell(fid);
                        fseek(fid, 0, SEEK_SET);
                        
                        if (option == GetDatabaseSettingSewer)
                            [sd startTransaction];
                        
                        else if (option == GetDatabaseSettingAlleyWall)
                            [awd startTransaction];
                        
                        else if (option == GetDatabaseSettingCurbRamp)
                            [crd startTransaction];
                        
                        else
                            [pd startTransaction];
                        
                        while (_keepGoing && fgetstring(str, (INPUTBUFSIZE - 2), fid))
                        {
                            if (option == GetDatabaseSettingSewer)
                                [sd executeCmd:str];
                            
                            else if (option == GetDatabaseSettingCurbRamp)
                                [crd executeCmd:str
                                   sendToServer:NO
                                  useUniqueFile:NO];
                            
                            else if (option == GetDatabaseSettingAlleyWall)
                            {
                                [awd executeCmd:str
                                   sendToServer:NO
                                  useUniqueFile:NO];
                            }
                            
                            else
                                [pd executeCmd:str];
                            
                            dispatch_async(dispatch_get_main_queue(),
                                           ^{
                                               [_popover updateProgress:ftell(fid) / totLen];
                                           });
                        }
                        
                        if (option == GetDatabaseSettingSewer)
                            [sd commitTransaction];
                        
                        else if (option == GetDatabaseSettingAlleyWall)
                            [awd commitTransaction];
                        
                        else if (option == GetDatabaseSettingCurbRamp)
                            [crd commitTransaction];
                        
                        else
                            [pd commitTransaction];
                        
                        if (option == GetDatabaseSettingParcels)
                        {
                            dispatch_async(dispatch_get_main_queue(),
                                           ^{
                                               _popover.title = @"Create Parcel Index";
                                           });
                            
                            [pd startTransaction];
                            [pd executeCmd:"CREATE INDEX IF NOT EXISTS PARCELPOLY_pinindex ON PARCELPOLY ('PID' ASC)"];
                            [pd commitTransaction];
                        }
                        
                        if (option == GetDatabaseSettingSewer)
                            [sd close];
                        
                        if (option == GetDatabaseSettingCurbRamp)
                            [crd close];
                        
                        else if (option == GetDatabaseSettingAlleyWall)
                        {
                            NSString *deviceName = UIDevice.currentDevice.name;
                            BOOL sendToServer = NO;
                            
                            if ([deviceName isEqualToString:@"GSSi-001"])
                                sendToServer = YES;
                            
                            [awd createNewTable:sendToServer];
                            [awd transferExistingTableIntoNewTable:sendToServer];
                            [awd close];
                        }
                        else
                            [pd close];
                        
                        fclose(fid);
                        free(str);
                        
                        dispatch_async(dispatch_get_main_queue(),
                                       ^{
                                           [_popover hide];
                                           
                                           NSFileManager *fileManager = NSFileManager.defaultManager;
                                           NSError *error;
                                           
                                           if (![fileManager removeItemAtPath:path
                                                                        error:&error])
                                           {
                                               NSLog(@"Could not delete %@:%@", path, error.localizedDescription);
                                           }
                                           
                                           if (![fileManager removeItemAtPath:file
                                                                        error:&error])
                                           {
                                               NSLog(@"Could not delete %@:%@", file, error.localizedDescription);
                                           }
                                       });
                    }
                    
                    if (_fromDataLoader)
                    {
                        if (!_keepGoing)
                            status = DLSTATUS_USER_CANCELLED;
                        
                        if (_delegate)
                        {
                            if (!status)
                                [_delegate SettingsViewControllerSuccess];
                            
                            else
                                [_delegate SettingsViewControllerFailed:status];
                        }
                        [UIApplication.sharedApplication setIdleTimerDisabled:NO];

                    }
                });
            }
                break;
                
            case GetDatabaseSettingTiles:
            {
                //[self loadTilesFromList:path
                          //updatePopover:_popover];
            }
                break;
        }
    }
    
    else
    {
        if (option == GET_STORMPLAT)
        {
            self.timer = [NSTimer scheduledTimerWithTimeInterval:0.15
                                                          target:self
                                                        selector:@selector(getNextPlat)
                                                        userInfo:nil
                                                         repeats:NO];
        }
        
        else
        {
            [_popover hide];
            
            if (_fromDataLoader)
                [_delegate SettingsViewControllerFailed:DLSTATUS_USER_CANCELLED];
            
            else
            {
                NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                                  delegate:self
                                                                     title:@"Error getting parcel file. Network communication error."
                                                           buttonTextArray:@[@"OK"]
                                                          destructiveIndex:0];
#pragma unused(alert)
            }
        }
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
    pull.option = GetDatabaseSettingTiles;
    
    [_popover showAfter:0.5
              withTitle:@"Get Tilelist File"];
    
    [pull getFile:fileName
    fromDirectory:@"GMMobile"
           toFile:fileName
      toDirectory:documentsDirectory
    refreshOption:FTPDataPullRefreshOptionCheckFileSize];
    
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
    pull.option = GetDatabaseSettingProperty;
    
    [_popover showAfter:0.5
              withTitle:@"Get Property File"];
    
    [pull getFile:fileName
    fromDirectory:@"GMMobile"
           toFile:fileName
      toDirectory:documentsDirectory
    refreshOption:FTPDataPullRefreshOptionCheckFileSize];
    
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
    pull.option = GetDatabaseSettingParcels;
    
    [_popover showAfter:0.5
              withTitle:@"Get Parcel File"];
    
    [pull getFile:fileName
    fromDirectory:@"GMMobile"
           toFile:fileName
      toDirectory:documentsDirectory
    refreshOption:FTPDataPullRefreshOptionCheckFileSize];
}

- (IBAction)loadCensus:(id)sender
{
    NSString *documentsDirectory = UserDefaults.defaults.localFilePath;
    NSString *fileName = @"censusdata.gcf";
    
    
    FTPDataPull *pull = FTPDataPull.pull;
    pull.delegate = self;
    pull.popover = _popover;
    pull.useOnlyPrimaryFTP = NO;
    pull.option = GetDatabaseSettingCensus;
    
    [_popover showAfter:0.5
              withTitle:@"Get Census File"];
    
    [pull getFile:fileName
    fromDirectory:@"GMMobile"
           toFile:fileName
      toDirectory:documentsDirectory
    refreshOption:FTPDataPullRefreshOptionCheckFileSize];
}

- (IBAction)loadAreas:(id)sender
{
    NSString *documentsDirectory = UserDefaults.defaults.localFilePath;
    NSString *fileName = @"MPLS_areas.gcf";
    
    if (CRAPI.sharedInstance.project == PROJECT_METROGIS)
        fileName = @"MetroGIS_areas.gcf";
    
    FTPDataPull *pull = FTPDataPull.pull;
    pull.delegate = self;
    pull.popover = _popover;
    pull.useOnlyPrimaryFTP = NO;
    pull.option = GetDatabaseSettingAreas;
    
    [_popover showAfter:0.5
              withTitle:@"Get Area File"];
    
    [pull getFile:fileName
    fromDirectory:@"GMMobile"
           toFile:fileName
      toDirectory:documentsDirectory
    refreshOption:FTPDataPullRefreshOptionCheckFileSize];
}

- (IBAction)loadPlan:(id)sender
{
    NSString *documentsDirectory = UserDefaults.defaults.localFilePath;
    NSString *fileName = @"MPLS_PlanimetricData.gcf";
    //NSString *fileName = @"MPLS_PlanimetricPointData.gcf";
    //NSString *fileName = @"MPLS_AlleyWall.gcf";
    
    
    FTPDataPull *pull = FTPDataPull.pull;
    pull.delegate = self;
    pull.popover = _popover;
    pull.useOnlyPrimaryFTP = NO;
    pull.option = GetDatabaseSettingPlan;
    
    [_popover showAfter:0.5
              withTitle:@"Get Planimetric File"];
    
    [pull getFile:fileName
    fromDirectory:@"GMMobile"
           toFile:fileName
      toDirectory:documentsDirectory
    refreshOption:FTPDataPullRefreshOptionCheckFileSize];
}

- (IBAction)loadAlleyWall:(id)sender
{
    NSString *documentsDirectory = UserDefaults.defaults.localFilePath;
    NSString *fileName = @"MPLS_AlleyWall.gcf";
    
    
    FTPDataPull *pull = FTPDataPull.pull;
    pull.delegate = self;
    pull.popover = _popover;
    pull.useOnlyPrimaryFTP = NO;
    pull.option = GetDatabaseSettingAlleyWall;
    
    [_popover showAfter:0.5
              withTitle:@"Get AlleyWall File"];
    
    [pull getFile:fileName
    fromDirectory:@"GMMobile"
           toFile:fileName
      toDirectory:documentsDirectory
    refreshOption:FTPDataPullRefreshOptionCheckFileSize];
}

- (IBAction)loadCurbRamps:(id)sender
{
    NSString *documentsDirectory = UserDefaults.defaults.localFilePath;
    NSString *fileName = @"MPLS_CurbRamp.gcf";
    
    FTPDataPull *pull = FTPDataPull.pull;
    pull.delegate = self;
    pull.popover = _popover;
    pull.useOnlyPrimaryFTP = NO;
    pull.option = GetDatabaseSettingCurbRamp;
    
    [_popover showAfter:0.5
              withTitle:@"Get Curb Ramp File"];
    
    [pull getFile:fileName
    fromDirectory:@"GMMobile"
           toFile:fileName
      toDirectory:documentsDirectory
    refreshOption:FTPDataPullRefreshOptionCheckFileSize];
}

- (IBAction)loadSewer:(id)sender
{
    NSString *documentsDirectory = UserDefaults.defaults.localFilePath;
    NSString *fileName = @"MPLS_sewer.gcf";
    
    FTPDataPull *pull = FTPDataPull.pull;
    pull.delegate = self;
    pull.popover = _popover;
    pull.useOnlyPrimaryFTP = NO;
    pull.option = GetDatabaseSettingSewer;
    
    [_popover showAfter:0.5
              withTitle:@"Get Sewer File"];
    
    [pull getFile:fileName
    fromDirectory:@"GMMobile"
           toFile:fileName
      toDirectory:documentsDirectory
    refreshOption:FTPDataPullRefreshOptionCheckFileSize];
}

- (BOOL)getNextPlat
{
    if (_nextPlat >= _allPlats.count)
    {
        [_popover hide];
        return NO;
    }
    
    NSString *platID = _allPlats[_nextPlat++];
    SewerData *sd = [[SewerData alloc] init];
    
    [sd loadPlat:platID
          ofType:@"storm"
    usingPopover:_popover
     andDelegate:self];
    
    return YES;
}

- (IBAction)loadPlats:(id)sender
{
    SewerData *sd = [[SewerData alloc] init];
    _allPlats = [sd getAllStormPlats];
    _nextPlat = 0;
    [self getNextPlat];
}

/*
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
*/

- (void)GSSiPopoverViewdidCancel:(GSSiPopoverView *)popoverView
{
    [_popover hide];
    if (_keepGoing)
        _keepGoing = NO;
    else if (_delegate)
        [_delegate SettingsViewControllerFailed:DLSTATUS_USER_CANCELLED];
        
}

- (IBAction)showEmail:(id)sender
{
    NSString *fileName1;
    //NSString *fileName2;
    //Email Subject
    NSString *emailTitle = @"Data extract file from NewVision Mobile";
    //Email Content
    NSString *messageBody = @"iOS programming is so fun!";
    //To address
    NSArray *toRecipents = [NSArray arrayWithObject:@"jeffgis@aol.com"];
    
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    
    //NSString *documentsDirectory = UserDefaults.defaults.localFilePath;
    //fileName1 = [NSString stringWithFormat:@"%@/UseCodeExtract.csv", documentsDirectory];
    
    //PropertyData *pd = [[PropertyData alloc] init];
    //[pd getDistinctUseCodes:fileName1];
    fileName1 = CRAPI.sharedInstance.extractFile;
    NSData *data = [NSData dataWithContentsOfFile:fileName1];

    mc.subject = emailTitle;
    mc.toRecipients = toRecipents;
    
    [mc setMessageBody:messageBody
                isHTML:NO];
    
/*    [mc addAttachmentData:data
                 mimeType:@"text/csv"
                 fileName:fileName1.lastPathComponent];*/
    
    [mc addAttachmentData:data
                 mimeType:@"image/png"
                 fileName:fileName1.lastPathComponent];
    
    //Present mail view controller on screen
    [self presentViewController:mc
                       animated:YES
                     completion:NULL];
    
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
            
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
            
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
            
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
            
        default:
            break;
    }
    
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES
                             completion:NULL];
}


- (IBAction)launchMaintenanceModule:(id)sender
{
    NSString *CRISDetailURL = @"PedRampDetail://";
    
    [SharedDefaults.defaults saveString:@"GMMobile"
                                 forKey:@"SourceApplication"];
    
    [SharedDefaults.defaults saveInteger:85
                                  forKey:@"DetailCurrentIntersection"];
    
    if ([UIApplication.sharedApplication canOpenURL:[NSURL URLWithString:CRISDetailURL]])
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:CRISDetailURL]];
    
    else
    {
        NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                          delegate:self
                                                             title:@"GMMobile cannot launch CRIS Detail"
                                                   buttonTextArray:@[@"OK"]
                                                  destructiveIndex:0];
#pragma unused(alert)
    }
}

- (IBAction)showBumpDetector:(id)sender
{
    GSSiBumpDetector *bumpDetector = [GSSiBumpDetector showBumpDetectorWithView:self.view
                                                                   coundownTime:8
                                                                          title:@"This is the title parameter"
                                                                       delegate:self];
#pragma unused(bumpDetector)
}

- (void)bumpDetector:(GSSiBumpDetector *)bumpDetector
didReturnTimeInterval:(NSString *)timeInterval
{
    [bumpDetector hideBumpDetector:YES];
    
    NSString *title = [NSString stringWithFormat:@"Collision Detection\nElapsed Time\n%@ seconds", timeInterval];
    
    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                      delegate:self
                                                         title:title
                                               buttonTextArray:@[@"OK"]
                                              destructiveIndex:0];
#pragma unused(alert)
}

- (void)bumpDetectorDidCancel:(GSSiBumpDetector *)bumpDetector;
{
    [bumpDetector hideBumpDetector:YES];
}

- (IBAction)showSpreadsheetView:(id)sender
{
    SpreadsheetView *spreadsheetView = [SpreadsheetView spreadsheetViewWithRows:24
                                                                        columns:8
                                                                           view:self.view];
    
    [self.view addSubview:spreadsheetView];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    for (SpreadsheetView *spreadsheetView in self.view.subviews)
    {
        if ([spreadsheetView isKindOfClass:SpreadsheetView.class])
        {
            [spreadsheetView willRotateWithDuration:duration
                                       tabBarHeight:self.tabBarController.tabBar.frame.size.height];
        }
        
    }
    for (GSSiBumpDetector *bumpDetector in self.view.subviews)
    {
        if ([bumpDetector isKindOfClass:GSSiBumpDetector.class])
        {
            [bumpDetector willRotateWithDuration:duration
                          toInterfaceOrientation:toInterfaceOrientation
                                    tabBarHeight:self.tabBarController.tabBar.frame.size.height];
        }
    }
}

- (IBAction)toggleUserLocationButton:(UISwitch *)sender
{
    AppDelegate *sharedAppDelegate = UIApplication.sharedApplication.delegate;
    
    [sharedAppDelegate.mapToolbar setConfigurationProperty:MapToolbarPropertyWantUserLocation
                                                     value:sender.on];
}

- (IBAction)toggleExtentsButton:(UISwitch *)sender
{
    AppDelegate *sharedAppDelegate = UIApplication.sharedApplication.delegate;
    
    [sharedAppDelegate.mapToolbar setConfigurationProperty:MapToolbarPropertyWantExtents
                                                     value:sender.on];
}

- (IBAction)toggleLegendsButton:(UISwitch *)sender
{
    AppDelegate *sharedAppDelegate = UIApplication.sharedApplication.delegate;
    
    [sharedAppDelegate.mapToolbar setConfigurationProperty:MapToolbarPropertyWantLegends
                                                     value:sender.on];
}

- (IBAction)toggleDigitizeButton:(UISwitch *)sender
{
    AppDelegate *sharedAppDelegate = UIApplication.sharedApplication.delegate;
    
    [sharedAppDelegate.mapToolbar setConfigurationProperty:MapToolbarPropertyWantDigitize
                                                     value:sender.on];
}

- (IBAction)toggleMarkerSwitch:(UISwitch *)sender
{
    AppDelegate *sharedAppDelegate = UIApplication.sharedApplication.delegate;
    
    [sharedAppDelegate.mapToolbar setConfigurationProperty:MapToolbarPropertyWantMarkerSwitch
                                                     value:sender.on];
}

- (IBAction)toggleMapTypeSC:(UISwitch *)sender
{
    AppDelegate *sharedAppDelegate = UIApplication.sharedApplication.delegate;
    
    [sharedAppDelegate.mapToolbar setConfigurationProperty:MapToolbarPropertyWantMapType
                                                     value:sender.on];
}

- (IBAction)togglePlatSC:(UISwitch *)sender
{
    AppDelegate *sharedAppDelegate = UIApplication.sharedApplication.delegate;
    
    [sharedAppDelegate.mapToolbar setConfigurationProperty:MapToolbarPropertyWantPlat
                                                     value:sender.on];
}

- (IBAction)showHeadingVC:(id)sender
{
    NVHeadingViewController *headingVC = [NVHeadingViewController showHeadingViewControllerWithDelegate:self
                                                                                        stabilityFactor:4.0
                                                                                            numReadings:250];
#pragma unused(headingVC)
}

- (void)headingViewController:(NVHeadingViewController *)headingViewController
             didReturnHeading:(CGFloat)heading
{
    [headingViewController dismissViewControllerAnimated:YES
                                              completion:nil];
    
    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                      delegate:self
                                                         title:[NSString stringWithFormat:@"Average Heading: %.1f", heading]
                                               buttonTextArray:@[@"OK"]
                                              destructiveIndex:0];
#pragma unused(alert)
}

- (void)headingViewControllerDidCancel:(NVHeadingViewController *)headingViewController
{
    [headingViewController dismissViewControllerAnimated:YES
                                              completion:nil];
    
    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                      delegate:self
                                                         title:@"Heading Measurement Cancelled"
                                               buttonTextArray:@[@"OK"]
                                              destructiveIndex:0];
#pragma unused(alert)
}

- (IBAction)showVideoHeadingVC:(id)sender
{
    NVVideoHeadingViewController *videoHeadingVC = [NVVideoHeadingViewController
                                                    showVideoHeadingViewControllerWithDelegate:self
                                                                               stabilityFactor:4.0
                                                                                   numReadings:250];
    #pragma unused(videoHeadingVC)
}

- (void)videoHeadingViewController:(NVVideoHeadingViewController *)headingViewController
                  didReturnHeading:(CGFloat)heading
{
    [headingViewController dismissViewControllerAnimated:YES
                                              completion:nil];
    
    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                      delegate:self
                                                         title:[NSString stringWithFormat:@"Average Heading: %.1f", heading]
                                               buttonTextArray:@[@"OK"]
                                              destructiveIndex:0];
#pragma unused(alert)
}

- (void)videoHeadingViewControllerDidCancel:(NVVideoHeadingViewController *)videoHeadingViewController
{
    [videoHeadingViewController dismissViewControllerAnimated:YES
                                                   completion:nil];
    
    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                      delegate:self
                                                         title:@"Video Heading Measurement Cancelled"
                                               buttonTextArray:@[@"OK"]
                                              destructiveIndex:0];
#pragma unused(alert)
}

- (IBAction)goBack:(id)sender
{
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

@end