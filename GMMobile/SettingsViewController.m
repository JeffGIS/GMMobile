//  SettingsViewController.m
//  GMMobile

#import "SettingsViewController.h"
#import "PropertyData.h"
#import "SewerData.h"
#import "GSSiTileOverlay.h"

#define GET_PROPERTY 1
#define GET_TILES 2
#define GET_PARCELS 3
#define GET_AREAS 4
#define GET_SEWER 5
#define GET_PLAN 6

#define INPUTBUFSIZE USHRT_MAX * 32

@interface SettingsViewController ()

@property (nonatomic) GSSiPopoverView *popover;
@property (nonatomic) GSSiAlertController *gssiAlert;

@end

@implementation SettingsViewController
{
    NSMutableArray* _allPlats;
    int _nextPlat;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _popover = [[GSSiPopoverView alloc] initWithView:self.view];
    _popover.delegate = self;

    _gssiAlert = [[GSSiAlertController alloc] initWithViewController:self];
    _gssiAlert.delegate = self;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    PropertyData *pd = [[PropertyData alloc] init];
    [pd open];
    _databaseSize.text = [NSString stringWithFormat:@"Database Size: %lld", pd.fileSize];
    [pd close];
    [UIApplication.sharedApplication setIdleTimerDisabled:YES];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [UIApplication.sharedApplication setIdleTimerDisabled:NO];
}

- (IBAction)deleteDatabase:(id)sender
{
    [_gssiAlert showAlertWithTitle:@"Delete Property Records Database"
                           message:nil
                 cancelButtonTitle:@"Cancel"
                 otherButtonTitles:@[@"OK"]
         destructiveButtonPosition:1];
}

- (void)gssiAlert:(GSSiAlertController *)gssiAlert
clickedButtonAtIndex:(NSInteger)buttonIndex
{
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

- (void)FTPdidComplete:(int)option withStatus:(int)status
              filePath:(NSString *)path
{
    if (status == FTPStatusOK)
    {
        switch (option)
        {
            case GET_SANPLAT:
                self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                              target:self
                                                            selector:@selector(getNextPlat)                                                            userInfo:nil
                                                             repeats:NO];
                break;
            case GET_PARCELS:
            case GET_PROPERTY:
            case GET_AREAS:
            case GET_SEWER:
            case GET_PLAN:
            {
                NSString *toDirectory = [path stringByDeletingLastPathComponent];
                NSString *file;
                
                if (!DecompressGMZipFile((LPSTR)path.UTF8String, (LPSTR)toDirectory.UTF8String))
                    break;
                
                switch (option)
                {
                    case GET_PARCELS:
                    {
                        file = [NSString stringWithFormat:@"%@/parcelpoly.sqltran",toDirectory];
                        _popover.title = @"Load Parcel Tables";
                    }
                        break;
                        
                    case GET_AREAS:
                    {
                        file = [NSString stringWithFormat:@"%@/areapoly.sqltran",toDirectory];
                        _popover.title = @"Load Area Tables";
                    }
                        break;
                        
                    case GET_PLAN:
                    {
                        //planimetric
                        //planimetricp
                        //alleywall
                        file = [NSString stringWithFormat:@"%@/planimetric.sqltran",toDirectory];
                        _popover.title = @"Load Planimetric Tables";
                    }
                        break;
                        
                    case GET_SEWER:
                    {
                        file = [NSString stringWithFormat:@"%@/sewerdata.sqltran",toDirectory];
                        _popover.title = @"Load Sewer Tables";
                    }
                        break;
                        
                    case GET_PROPERTY:
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
                    
                    if (!str)
                    {
                        dispatch_async(dispatch_get_main_queue(),
                                       ^{
                                           _popover.title = @"Failed to get memory. Hit cancel to continue";
                                       });
                    }
                    else
                    {
                        PropertyData *pd;
                        SewerData *sd;
                        
                        if (option == GET_SEWER)
                        {
                            sd = [[SewerData alloc]init];
                            [sd open];
                        }
                        else
                        {
                            pd = [[PropertyData alloc] init];
                            [pd open];
                        }
                        fseek(fid, 0, SEEK_END);
                        CGFloat totLen = ftell(fid);
                        fseek(fid, 0, SEEK_SET);
                        if (option == GET_SEWER)
                            [sd startTransaction];
                        else
                            [pd startTransaction];
                        
                        while (fgetstring(str, (INPUTBUFSIZE - 2), fid))
                        {
                            if (option == GET_SEWER)
                                [sd executeCmd:str];
                            else
                                [pd executeCmd:str];
                            
                            dispatch_async(dispatch_get_main_queue(),
                                           ^{
                                               [_popover updateProgress:ftell(fid) / totLen];
                                           });
                        }
                        
                        if (option == GET_SEWER)
                            [sd commitTransaction];
                        else
                            [pd commitTransaction];
                        if (option == GET_PARCELS)
                        {
                            dispatch_async(dispatch_get_main_queue(),
                                           ^{
                                               _popover.title = @"Create Parcel Index";
                                           });
                            [pd startTransaction];
                            [pd executeCmd:"CREATE INDEX IF NOT EXISTS PARCELPOLY_pinindex ON PARCELPOLY ('PID' ASC)"];
                            [pd commitTransaction];
                        }
                        if (option == GET_SEWER)
                            [sd close];
                        else
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
        if (option == GET_SANPLAT)
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
            
            [_gssiAlert showAlertWithTitle:@"Error getting parcel file"
                                   message:@"Network communication error"
                         cancelButtonTitle:@"Continue"
                         otherButtonTitles:nil
                 destructiveButtonPosition:0];
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
    pull.option = GET_AREAS;
    
    [_popover showAfter:0.5
              withTitle:@"Get Area File"];
    
    [pull getFile:fileName
    fromDirectory:@"GMMobile"
           toFile:fileName
      toDirectory:documentsDirectory
     forceRefresh:YES];
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
    pull.option = GET_PLAN;
    
    [_popover showAfter:0.5
              withTitle:@"Get Planimetric File"];
    
    [pull getFile:fileName
    fromDirectory:@"GMMobile"
           toFile:fileName
      toDirectory:documentsDirectory
     forceRefresh:YES];
}

- (IBAction)loadSewer:(id)sender {
    NSString *documentsDirectory = UserDefaults.defaults.localFilePath;
    NSString *fileName = @"MPLS_sewers.gcf";
    
    FTPDataPull *pull = FTPDataPull.pull;
    pull.delegate = self;
    pull.popover = _popover;
    pull.useOnlyPrimaryFTP = NO;
    pull.option = GET_SEWER;
    
    [_popover showAfter:0.5
              withTitle:@"Get Area File"];
    
    [pull getFile:fileName
    fromDirectory:@"GMMobile"
           toFile:fileName
      toDirectory:documentsDirectory
     forceRefresh:YES];
}

- (BOOL) getNextPlat
{
    if (_nextPlat >= [_allPlats count])
    {
        [_popover hide];
        return FALSE;
    }
    NSString *platID = _allPlats[_nextPlat++];
    SewerData* sd = [[SewerData alloc]init];
    [sd loadPlat:platID usingPopover:_popover andDelegate:self];
    return TRUE;
}

- (IBAction)loadPlats:(id)sender
{
    SewerData* sd = [[SewerData alloc]init];
    _allPlats = [sd getAllSanPlats];
    _nextPlat = 0;
    [self getNextPlat];
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

- (IBAction)showEmail:(id)sender
{
    NSString* fileName1, *fileName2;
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
    NSData * data = [NSData dataWithContentsOfFile:fileName1];

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

- (void) mailComposeController:(MFMailComposeViewController *)controller
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

@end