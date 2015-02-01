//  SettingsViewController.m
//  GMMobile

#import "SettingsViewController.h"
#import "PropertyData.h"
#import "GSSiTileOverlay.h"

#define GET_PROPERTY    1
#define GET_TILES       2

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
    pull.option = GET_PROPERTY;

    [_popover showAfter:0.5
              withTitle:@"Get Property File"];

    [pull getFile:fileName
    fromDirectory:@"GMMobile"
           toFile:fileName
      toDirectory:documentsDirectory
     forceRefresh:YES];

}
- (void)FTPdidComplete:(int)option withStatus:(int)status
              filePath:(NSString *)path
{
    
    if (status == FTPStatusOK)
    {
        switch (option)
        {
            case GET_PROPERTY:
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
                break;
            case GET_TILES:
            {
                [self loadTilesFromList:path updatePopover:_popover];
            }
                break;
        }
    }
}

- (IBAction)preloadTiles:(id)sender
{
 //   PropertyData *pd = [[PropertyData alloc] init];
 //   [pd loadParcelPolygons:@""];
    NSString *gmm = @"http://74.42.137.128/icons/MPLS/{z}/{y}/{x}.png";
    MKTileOverlayPath path;
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
-(BOOL)loadTilesFromList:(NSString*)fileList updatePopover:(GSSiPopoverView*)popover
{
    BOOL rtn=FALSE;
    unsigned long long fileSize = [NSFileManager.defaultManager
                                   attributesOfItemAtPath:fileList
                                   error:nil].fileSize;
    _popover = popover;
    popover.delegate = self;
    popover.title = @"Load All Tiles";
    _condition = [[NSCondition alloc]init];
    
    dispatch_queue_t overallQueue = dispatch_queue_create("overallQueue",NULL);
    dispatch_queue_t tileQueue = dispatch_queue_create("tileQueue",NULL);
  
    dispatch_async(overallQueue,
                   ^{
                       FILE *fid = fopen (fileList.UTF8String,"rb");
                       char line[34];
                       char * ploc;
                       int  numRequests=0;
                       _keepGoing = YES;
                       while (_keepGoing && fgetstring(line,32, fid))
                       {
                           MKTileOverlayPath top;
                           top.contentScaleFactor = 1;
                           [_condition lock];
                           while (numRequests > _nComplete + _nFailed + 4)
                               [_condition wait];
                           [_condition unlock];
                           top.z = atoi (line);
                           ploc = strchr (line,'\\')+1;
                           top.y = atoi(ploc);
                           ploc = strchr (ploc,'\\')+1;
                           top.x = atoi(ploc);
                           numRequests++;
                           dispatch_async(tileQueue,
                                          ^{
                                              NSString *gmm = @"http://74.42.137.128/icons/MPLS/{z}/{y}/{x}.png";
                                              GSSiTileOverlay *to = [[GSSiTileOverlay alloc] initWithURLTemplate:gmm];
                                              to.canReplaceMapContent = YES;
                                              to.minimumZ = 12;
                                              to.maximumZ = 19;
                                              to.type = @"GMM";
                                              [to cacheTileAtPath:top condition:_condition complete:&_nComplete failed:&_nFailed];
                           
                                              dispatch_async(dispatch_get_main_queue(),
                                                             ^{
                                                                 [popover updateProgress:(float)ftell(fid)/fileSize];
                                                             });
                                          });
                      }
                       fclose (fid);
                       [popover hide];
                   });
    
    return rtn;
}
-(void)GSSiPopoverViewdidCancel:(GSSiPopoverView *)popoverView
{
    _keepGoing = NO;
    [_popover hide];
}


@end