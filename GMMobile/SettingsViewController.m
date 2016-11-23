//  SettingsViewController.m
//  GMMobile

#import "SettingsViewController.h"
#import "PropertyData.h"
#import "BoundaryData.h"
#import "AppDelegate.h"

#define INPUTBUFSIZE USHRT_MAX * 32
#define USE_TEST_SERVER NO

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
@property (weak, nonatomic) IBOutlet UILabel *databaseSize;
@property FTPDataPush *push;

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
    
    _locSwitch.on = CRAPI.sharedInstance.mapToolbar.wantUserLocation;
    _extSwitch.on = CRAPI.sharedInstance.mapToolbar.wantExtents;
    _legdSwitch.on = CRAPI.sharedInstance.mapToolbar.wantLegends;
    _digtSwitch.on = CRAPI.sharedInstance.mapToolbar.wantDigitize;
    _markSwitch.on = CRAPI.sharedInstance.mapToolbar.wantGrayscale;
    _mapSwitch.on = CRAPI.sharedInstance.mapToolbar.wantMapType;
    _platSwitch.on = CRAPI.sharedInstance.mapToolbar.wantPlat;
    
    PropertyData *pd = [[PropertyData alloc] init];
    BOOL pdopened = [pd open];
    _databaseSize.text = [NSString stringWithFormat:@"DB Size: %lld", pd.fileSize];
    [pd close:pdopened];
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

- (void)FTPPushDidComplete:(FTPDataType)dataType
                withStatus:(FTPStatus)status
           andStatusString:(NSString *)statusString
                  filePath:(NSString *)path
{
    _popover.title = @"Upload Complete";
    [_popover setCancelButtonTitle:@"OK"];
    NSLog(@"FTP push completed:%@", statusString);
}

- (void)FTPdidComplete:(FTPDataType)dataType
            withStatus:(FTPStatus)status
       andStatusString:(NSString *)statusString
              filePath:(NSString *)path
{
    if (status == FTPStatusOK || status == FTPStatusFileExists)
    {
        switch (dataType)
        {
            case FTPDataPlat:
                self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                              target:self
                                                            selector:@selector(getNextPlat)
                                                            userInfo:nil
                                                             repeats:NO];
                break;
                
            case GetDatabaseSettingAlleyWallNew:
                break;
            case GetDatabaseSettingProperty:
            case GetDatabaseSettingParcels:
            case GetDatabaseSettingAreas:
            case GetDatabaseSettingSewer:
            case GetDatabaseSettingPlan:
            case GetDatabaseSettingAlleyWall:
            case GetDatabaseSettingCurbRamp:
            case GetDatabaseSettingCensus:
            case GetDatabaseSettingCrimes:
            case GetDatabaseSettingMapleGrove:
            case GetDatabaseSettingNVMetro:
            {
                dispatch_queue_t overallQueue = dispatch_queue_create("overallQueue",NULL);
                
                dispatch_async(overallQueue,
                               ^{
                                   NSString *toDirectory = path.stringByDeletingLastPathComponent;
                                   toDirectory = CRAPI.sharedInstance.sharedFilePath;
                                   if (dataType == GetDatabaseSettingMapleGrove)
                                       toDirectory = [toDirectory stringByAppendingString:@"/MapleGrove"];
                                   NSString *file=nil;
                                   NSString *newTitle = @"Load Data";
                                   CompressDecompress *cdc = [[CompressDecompress alloc]init];
                                   cdc.popover = _popover;
                                   dispatch_async(dispatch_get_main_queue(),
                                                  ^{
                                                      _popover.title = @"Decompressing Database";
                                                  });
                                   if ([cdc DecompressGMZipFile:(LPSTR)path.UTF8String
                                                    toDirectory:(LPSTR)toDirectory.UTF8String])
                                   {
                                       switch (dataType)
                                       {
                                           case GetDatabaseSettingNVMetro:
                                           {
                                               dispatch_async(dispatch_get_main_queue(),
                                                              ^{
                                                                  [_popover hide];
                                                              });
                                               NSFileManager *fileManager = NSFileManager.defaultManager;
                                               NSError *error;
                                               
                                               if (![fileManager removeItemAtPath:path
                                                                            error:&error])
                                               {
                                                   NSLog(@"Could not delete %@:%@", path, error.localizedDescription);
                                               }
                                               goto Exit;
                                           }
                                               break;
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
                                           case GetDatabaseSettingCrimes:
                                           {
                                               file = [NSString stringWithFormat:@"%@/crimes_latlon.sqltran",toDirectory];
                                               _popover.title = @"Load Crime Tables";
                                           }
                                               break;
                                           case GetDatabaseSettingMapleGrove:
                                           {
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
                                                              });
                                               
                                               _keepGoing = YES;
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
                                               newTitle = @"Load Sewer Tables";
                                           }
                                               break;
                                               
                                           case GetDatabaseSettingProperty:
                                           {
                                               file = [NSString stringWithFormat:@"%@/property.sqltran",toDirectory];
                                               _popover.title = @"Load Property Tables";
                                           }
                                               break;
                                               
                                           default:
                                               break;
                                       }
                                       
                                       int status = 0;
                                       if (dataType != GetDatabaseSettingMapleGrove)
                                       {
                                       FILE *fid = fopen(file.UTF8String, "rb");
                                       if (fid)
                                       {
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
                                               _keepGoing = YES;
                                               dispatch_async(dispatch_get_main_queue(),
                                                              ^{
                                                                  _popover.title = newTitle;
                                                              });
                                               PropertyData *pd;
                                               SewerData *sd;
                                               AlleyWallData *awd;
                                               CurbRampData *crd;
                                               CrimeData *crimed;
                                               BoundaryData *bd;
                                               BOOL opened = NO;
                                               
                                               if (dataType == GetDatabaseSettingSewer)
                                               {
                                                   sd = [[SewerData alloc] init];
                                                   [sd open];
                                               }
                                               else if (dataType == GetDatabaseSettingAreas)
                                               {
                                                   bd = [[BoundaryData alloc] init];
                                                   opened = [bd open];
                                               }
                                               else if (dataType == GetDatabaseSettingAlleyWall)
                                               {
                                                   awd = [[AlleyWallData alloc] init];
                                                   [awd clear];
                                                   [awd open];
                                               }
                                               else if (dataType == GetDatabaseSettingCrimes)
                                               {
                                                   crimed = [[CrimeData alloc] init];
                                                   [crimed clear];
                                                   [crimed open];
                                               }
                                               else if (dataType == GetDatabaseSettingCurbRamp)
                                               {
                                                   crd = [CurbRampData databaseForGeoid:CRAPI.sharedInstance.currentGeoid
                                                                                 create:NO];
                                                   [crd createIntersectionsTable:YES];
                                                   [crd open];
                                               }
                                               
                                               else
                                               {
                                                   pd = [[PropertyData alloc] init];
                                                   opened = [pd open];
                                               }
                                               
                                               CGFloat totLen = FileLength (fid);
                                               if (dataType == GetDatabaseSettingSewer)
                                                   [sd startTransaction];
                                               
                                               else if (dataType == GetDatabaseSettingAreas)
                                                   [bd startTransaction];
                                               
                                               else if (dataType == GetDatabaseSettingAlleyWall)
                                                   [awd startTransaction];
                                               
                                               else if (dataType == GetDatabaseSettingCurbRamp)
                                                   [crd startTransaction];
                                               
                                               else if (dataType == GetDatabaseSettingCrimes)
                                                   [crimed startTransaction];
                                               
                                               else
                                                   [pd startTransaction];
                                               
                                               while (_keepGoing && fgetstring(str, (INPUTBUFSIZE - 2), fid))
                                               {
                                                   if (dataType == GetDatabaseSettingSewer)
                                                       [sd executeCmd:str];
                                                   
                                                   else if (dataType == GetDatabaseSettingAreas)
                                                       [bd executeCmd:str];
                                                   
                                                   else if (dataType == GetDatabaseSettingCrimes)
                                                   {
                                                       [crimed getIdForUpdate:str
                                                                       remove:YES];
                                                       [crimed executeCmd:str];
                                                   }
                                                   
                                                   else if (dataType == GetDatabaseSettingCurbRamp)
                                                   {
                                                       NSString * cmd = [NSString stringWithUTF8String:str];
                                                       cmd = [cmd stringByReplacingOccurrencesOfString:@"AssignedTo=" withString:@"AssignedToDetail="];
                                                       [crd executeCmd:(LPSTR)cmd.UTF8String
                                                          sendToServer:NO
                                                                  from:1675];
                                                   }
                                                   else if (dataType == GetDatabaseSettingAlleyWall)
                                                   {
                                                       [awd executeCmd:str
                                                          sendToServer:_sendAlleyToServer];
                                                   }
                                                   
                                                   else
                                                       [pd executeCmd:str];
                                                   
                                                   dispatch_async(dispatch_get_main_queue(),
                                                                  ^{
                                                                      [_popover updateProgress:ftell(fid) / totLen];
                                                                  });
                                               }
                                               
                                               if (dataType == GetDatabaseSettingSewer)
                                                   [sd commitTransaction];
                                               
                                               else if (dataType == GetDatabaseSettingAreas)
                                                   [bd commitTransaction];
                                               
                                               else if (dataType == GetDatabaseSettingAlleyWall)
                                                   [awd commitTransaction];
                                               
                                               else if (dataType == GetDatabaseSettingCrimes)
                                                   [crimed commitTransaction];
                                               
                                               else if (dataType == GetDatabaseSettingCurbRamp)
                                                   [crd commitTransaction];
                                               
                                               else
                                                   [pd commitTransaction];
                                               
                                               /* if (dataType == GetDatabaseSettingParcels)
                                                {
                                                dispatch_async(dispatch_get_main_queue(),
                                                ^{
                                                _popover.title = @"Create Parcel Index";
                                                });
                                                
                                                [pd startTransaction];
                                                [pd executeCmd:"CREATE INDEX IF NOT EXISTS PARCELPOLY_pinindex ON PARCELPOLY ('PID' ASC)"];
                                                [pd commitTransaction];
                                                }*/
                                               
                                               if (dataType == GetDatabaseSettingSewer)
                                                   [sd close];
                                               
                                               if (dataType == GetDatabaseSettingAreas)
                                                   [bd close:opened];
                                               
                                               if (dataType == GetDatabaseSettingCrimes)
                                                   [crimed close];
                                               
                                               if (dataType == GetDatabaseSettingCurbRamp)
                                                   [crd close:YES];
                                               
                                               else if (dataType == GetDatabaseSettingAlleyWall)
                                               {
                                                   NSString *deviceName = UIDevice.currentDevice.name;
                                                   
                                                   [awd createNewTable:_sendAlleyToServer];
                                                   [awd transferExistingTableIntoNewTable:_sendAlleyToServer];
                                                   [awd close:YES];
                                               }
                                               else
                                                   [pd close:opened];
                                               
                                               fclose(fid);
                                               free(str);
                                           }
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
                                           
                                       else
                                       {
                                           dispatch_async(dispatch_get_main_queue(),
                                                          ^{
                                                              _popover.title = @"Invalid file";
                                                          });
                                       }
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
                                           
                                           
                                       }
                                   }
                               Exit:;
                               });
            }
                break;
                
            case GetDatabaseSettingTiles:
            {
                //[self loadTilesFromList:path
                //updatePopover:_popover];
            }
                break;
                
            default:
                break;
        }
    }
    
    else
    {
        if (dataType == FTPDataPlat)
        {
            self.timer = [NSTimer scheduledTimerWithTimeInterval:0.15
                                                          target:self
                                                        selector:@selector(getNextPlat)
                                                        userInfo:nil
                                                         repeats:NO];
        }
        
        else
        {
            
            if (_fromDataLoader)
            {
                [_delegate SettingsViewControllerFailed:DLSTATUS_USER_CANCELLED];
                _popover.title = [_popover.title stringByAppendingFormat:@"\n%@",statusString];
            }
            else
            {
                [_popover hide];
                NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                                  delegate:self
                                                                     title:statusString
                                                           buttonTextArray:@[@"OK"]
                                                          destructiveIndex:0];
#pragma unused(alert)
            }
        }
    }
Exit:
    return;
}

- (IBAction)preloadTiles:(id)sender
{
    NSString *documentsDirectory = UserDefaults.defaults.localFilePath;
    NSString *fileName = @"PropTileList.txt";
    
    FTPDataPull *pull = FTPDataPull.pull;
    pull.delegate = self;
    pull.popover = _popover;
    pull.dataType = GetDatabaseSettingTiles;
    pull.useTestServer = USE_TEST_SERVER;
    
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
    [self loadNVMetro:sender];
    return;
    NSString *documentsDirectory = UserDefaults.defaults.localFilePath;
    NSString *fileName = @"MPLS_propfiles.gcf";
    
    if (CRAPI.sharedInstance.project == PROJECT_METROGIS)
        fileName = @"MetroGIS_propfiles.gcf";
    
    FTPDataPull *pull = FTPDataPull.pull;
    pull.delegate = self;
    pull.popover = _popover;
    pull.dataType = GetDatabaseSettingProperty;
    pull.useTestServer = USE_TEST_SERVER;
    
    [_popover showAfter:0.5
              withTitle:@"Get Property File"];
    
    [pull getFile:fileName
    fromDirectory:@"NVMobile"
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
    pull.dataType = GetDatabaseSettingParcels;
    pull.useTestServer = USE_TEST_SERVER;
    
    [_popover showAfter:0.5
              withTitle:@"Get Parcel File"];
    
    [pull getFile:fileName
    fromDirectory:@"NVMobile"
           toFile:fileName
      toDirectory:documentsDirectory
    refreshOption:FTPDataPullRefreshOptionCheckFileSize];
}

- (IBAction)loadCensus:(id)sender
{
    NSString *documentsDirectory = UserDefaults.defaults.localFilePath;
    NSString *fileName = @"MetroGIS_census.gcf";
    
    
    FTPDataPull *pull = FTPDataPull.pull;
    pull.delegate = self;
    pull.popover = _popover;
    pull.dataType = GetDatabaseSettingCensus;
    pull.useTestServer = USE_TEST_SERVER;
    
    [_popover showAfter:0.5
              withTitle:@"Get Census File"];
    
    [pull getFile:fileName
    fromDirectory:@"NVMobile"
           toFile:fileName
      toDirectory:documentsDirectory
    refreshOption:FTPDataPullRefreshOptionCheckFileSize];
}
- (IBAction)loadNVMetro:(id)sender
{
    NSString *documentsDirectory = UserDefaults.defaults.localFilePath;
    NSString *fileName = @"MetroGIS_database.gcf";
    
    
    FTPDataPull *pull = FTPDataPull.pull;
    pull.delegate = self;
    pull.popover = _popover;
    pull.dataType = GetDatabaseSettingNVMetro;
    pull.useTestServer = USE_TEST_SERVER;
    
    [_popover showAfter:0.5
              withTitle:@"Get Data File"];
    
    [pull getFile:fileName
    fromDirectory:@"NVMobile"
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
    pull.dataType = GetDatabaseSettingAreas;
    pull.useTestServer = USE_TEST_SERVER;
    
    [_popover showAfter:0.5
              withTitle:@"Get Area File"];
    
    [pull getFile:fileName
    fromDirectory:@"NVMobile"
           toFile:fileName
      toDirectory:documentsDirectory
    refreshOption:FTPDataPullRefreshOptionCheckFileSize];
}

- (IBAction)loadCrimeData:(id)sender
{
    NSString *documentsDirectory = UserDefaults.defaults.localFilePath;
    NSString *fileName = @"Crimes_ll.gcf";
    
    FTPDataPull *pull = FTPDataPull.pull;
    pull.delegate = self;
    pull.popover = _popover;
    pull.dataType = GetDatabaseSettingCrimes;
    pull.useTestServer = USE_TEST_SERVER;
    
    [_popover showAfter:0.5
              withTitle:@"Get Crime File"];
    
    [pull getFile:fileName
    fromDirectory:@"NVMobile"
           toFile:fileName
      toDirectory:documentsDirectory
    refreshOption:FTPDataPullRefreshOptionCheckFileSize];
}

- (IBAction)loadMapleGrove:(id)sender
{
    NSString *documentsDirectory = UserDefaults.defaults.sharedFilePath;
    NSString *fileName = @"MapleGroveShapefiles.gcf";
    NSString *outputDirectory = [NSString stringWithFormat:@"%@/MapleGrove", documentsDirectory];
    [NSFileManager.defaultManager createDirectoryAtPath:outputDirectory
                            withIntermediateDirectories:YES
                                             attributes:nil
                                                  error:nil];
    
    FTPDataPull *pull = FTPDataPull.pull;
    pull.delegate = self;
    pull.popover = _popover;
    pull.dataType = GetDatabaseSettingMapleGrove;
    pull.useTestServer = USE_TEST_SERVER;
    
    [_popover showAfter:0.5
              withTitle:@"Get Shape Files"];
    
    [pull getFile:fileName
    fromDirectory:@"NVMobile"
           toFile:fileName
      toDirectory:outputDirectory
    refreshOption:FTPDataPullRefreshOptionCheckFileSize];
}

- (IBAction)compressDatabase:(id)sender {
    PropertyData *pd = [[PropertyData alloc] init];
    BOOL pdopened = [pd open];
    [pd executeCmd:"VACUUM"];
    [pd close:pdopened];
    [pd open];
        _databaseSize.text = [NSString stringWithFormat:@"DB Size: %lld", pd.fileSize];
    [pd close:pdopened];
    [UIApplication.sharedApplication setIdleTimerDisabled:YES];
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
    pull.dataType = GetDatabaseSettingPlan;
    pull.useTestServer = USE_TEST_SERVER;
    
    [_popover showAfter:0.5
              withTitle:@"Get Planimetric File"];
    
    [pull getFile:fileName
    fromDirectory:@"NVMobile"
           toFile:fileName
      toDirectory:documentsDirectory
    refreshOption:FTPDataPullRefreshOptionCheckFileSize];
}

- (IBAction)loadAlleyWall:(id)sender
{
    NSString *documentsDirectory = UserDefaults.defaults.localFilePath;
    NSString *fileName = @"AlleyWalls.slt";
    AlleyWallData *awd = AlleyWallData.new;
    NSString * toFile = [awd databasePath];
    FTPDataPull *pull = FTPDataPull.pull;
    pull.delegate = self;
    pull.popover = _popover;
    pull.dataType = GetDatabaseSettingAlleyWallNew;
    pull.useTestServer = USE_TEST_SERVER;
    
    [_popover showAfter:0.5
              withTitle:@"Get AlleyWall File"];
    
    [pull getFile:fileName
    fromDirectory:@"NVMobile"
           toFile:[toFile lastPathComponent]
      toDirectory:[toFile stringByDeletingLastPathComponent]
    refreshOption:FTPDataPullRefreshOptionCheckFileSize];
}

- (IBAction)loadAlleyWall_old:(id)sender
{
    NSString *documentsDirectory = UserDefaults.defaults.localFilePath;
    NSString *fileName = @"MPLS_AlleyWall.gcf";
    
    [CRAPI.sharedInstance clearErrorFile];

    _sendAlleyToServer = YES;
    FTPDataPull *pull = FTPDataPull.pull;
    pull.delegate = self;
    pull.popover = _popover;
    pull.dataType = GetDatabaseSettingAlleyWall;
    pull.useTestServer = USE_TEST_SERVER;
    
    [_popover showAfter:0.5
              withTitle:@"Get AlleyWall File"];
    
    [pull getFile:fileName
    fromDirectory:@"NVMobile"
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
    pull.dataType = GetDatabaseSettingCurbRamp;
    pull.useTestServer = USE_TEST_SERVER;
    
    [_popover showAfter:0.5
              withTitle:@"Get Curb Ramp File"];
    
    [pull getFile:fileName
    fromDirectory:@"NVMobile"
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
    pull.dataType = GetDatabaseSettingSewer;
    pull.useTestServer = USE_TEST_SERVER;
    
    [_popover showAfter:0.5
              withTitle:@"Get Sewer File"];
    
    [pull getFile:fileName
    fromDirectory:@"NVMobile"
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

- (IBAction)launchMaintenanceModule:(id)sender
{
    NSString *CRISDetailURL = @"CRISDetail://";
    
    [SharedDefaults.defaults saveString:@"NVMobile"
                                 forKey:@"SourceApplication"];
    
    [SharedDefaults.defaults saveInteger:85
                                  forKey:@"DetailCurrentIntersection"];
    
    if ([UIApplication.sharedApplication canOpenURL:[NSURL URLWithString:CRISDetailURL]])
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:CRISDetailURL]];
    
    else
    {
        NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                          delegate:self
                                                             title:@"NVMobile cannot launch CRIS Detail"
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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
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
    [CRAPI.sharedInstance.mapToolbar setConfigurationProperty:MapToolbarPropertyWantUserLocation
                                                        value:sender.on];
}

- (IBAction)toggleExtentsButton:(UISwitch *)sender
{
    [CRAPI.sharedInstance.mapToolbar setConfigurationProperty:MapToolbarPropertyWantExtents
                                                        value:sender.on];
}

- (IBAction)toggleLegendsButton:(UISwitch *)sender
{
    [CRAPI.sharedInstance.mapToolbar setConfigurationProperty:MapToolbarPropertyWantLegends
                                                        value:sender.on];
}

- (IBAction)toggleDigitizeButton:(UISwitch *)sender
{
    [CRAPI.sharedInstance.mapToolbar setConfigurationProperty:MapToolbarPropertyWantDigitize
                                                        value:sender.on];
}

- (IBAction)toggleMarkerSwitch:(UISwitch *)sender
{
    [CRAPI.sharedInstance.mapToolbar setConfigurationProperty:MapToolbarPropertyWantGrayscale
                                                        value:sender.on];
}

- (IBAction)toggleMapTypeSC:(UISwitch *)sender
{
    [CRAPI.sharedInstance.mapToolbar setConfigurationProperty:MapToolbarPropertyWantMapType
                                                        value:sender.on];
}

- (IBAction)togglePlatSC:(UISwitch *)sender
{
    [CRAPI.sharedInstance.mapToolbar setConfigurationProperty:MapToolbarPropertyWantPlat
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

- (IBAction)uploadDatabases:(id)sender
{
    NSString * dir1 = [NSString stringWithFormat:@"%i",CRAPI.sharedInstance.currentManageriPad];
    NSString * dir2 =[NSString stringWithFormat:@"%i/%i",CRAPI.sharedInstance.currentManageriPad,CRAPI.sharedInstance.currentiPadWithinManager];
    NSArray *directories = @[dir1,dir2];
    
    _ftpdc = [FTPDirectoryCreate createDirectories:directories
                                       inFTPDomain:[CRAPI.sharedInstance getNVCRISServer]
                                         directory:@"NVMobile/UploadedDatabases"
                                          username:@"GSSiProfessionalServer"
                                          password:@"GSSi"
                                              port:@"21"
                                          delegate:self];
}

- (void)FTPDirectoryCreateDidCompleteWithStatus:(FTPStatus)status
                                   statusString:(NSString *)statusString
                                      directory:(NSString *)directory
{
    if (status == FTPStatusOK)
    {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                      target:self
                                                    selector:@selector(uploadDatabases2:)
                                                    userInfo:nil
                                                     repeats:NO];

    }
    else
    {
        _popover.title = [NSString stringWithFormat:@"Unable to create directories\n%@",statusString];
        [_popover setCancelButtonTitle:@"OK"];
        [_popover show];
    }
}

- (void)uploadDatabases2:(NSTimer *)timer
{
    [timer invalidate];
    _push = [FTPDataPush push];
    _push.delegate = self;
    _push.popover = _popover;
    
    //AlleyWallData *awd = [AlleyWallData new];
    CurbRampData *awd = [CurbRampData new];
   // NSString * sendToServerFile = [awd getSendToServerFile:0];
    
    NSString *toDir = [NSString stringWithFormat:@"NVMobile/UploadedDatabases/%i/%i",CRAPI.sharedInstance.currentManageriPad,CRAPI.sharedInstance.currentiPadWithinManager];
   // NSString * sendToServerFile = [awd databasePath];
    NSString * sendToServerFile = [NSString stringWithFormat:@"%@/MASTER/rampdata.txt",UserDefaults.defaults.sharedFilePath];

    NSString *file = [sendToServerFile lastPathComponent];
    NSString *fromDir = [sendToServerFile stringByDeletingLastPathComponent];
    //NSString *file = @"Crimes.sqlite";
    //NSString *fromDir = CRAPI.sharedInstance.sharedFilePath;
    //NSString *toDir = @"";
    //NSString *file = @"Property.sqlite";
    //NSString *fromDir = UserDefaults.defaults.localFilePath;
    //NSString *toDir = @"NVMobile/UploadedDatabases";
    
    [_popover showAfter:0.1
              withTitle:@"Upload Database"];
    
    if (![_push sendFile:file
      fromDirectory:fromDir
             toFile:file
        toDirectory:toDir
     deleteWhenDone:NO
     appendFileName:NO])
        _popover.title = @"File missing or empty";
}

- (IBAction)outputFile:(id)sender
{
    NSString *outFile = @"hotspottest";
    
    NSString *filepath = [NSString stringWithFormat:@"%@/%@.bin",
                           CRAPI.sharedInstance.sharedFilePath,outFile];
    
    [CRAPI.sharedInstance.docManager exportDocumentFromFilepath:filepath
                                                       delegate:self
                                                 deleteWhenDone:NO];
}


@end
