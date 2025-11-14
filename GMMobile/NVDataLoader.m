//  NVDataLoader.m
//  GMMobile

#import "NVDataLoader.h"
#import "PropertyData.h"
#import "BoundaryData.h"
#import "HuntingData.h"
#import "DTMData.h"
#import "ShapeFileDisplay.h"


@implementation NVDataLoader

- (void) dealloc
{
    NSLog (@"Dataloader released");
    [UIApplication.sharedApplication setIdleTimerDisabled:NO];
}

- (void)loadNVData:(HardCodedConfigs)appID
           popover:(GSSiPopoverView *)popover
{
    [UIApplication.sharedApplication setIdleTimerDisabled:YES];
    _popover = popover;
    _popover.hideAtCancel = NO;
    _saveDelegate = popover.delegate;
    _popover.delegate = self;
    _dbList = [ConfigurationControl.sharedInstance getDatasetsForApp:appID];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                                  target:self
                                                selector:@selector(checkNextDataset:)
                                                userInfo:nil
                                                 repeats:NO];
}

- (void) GSSiPopoverViewdidCancel:(GSSiPopoverView *)popoverView
{
    [_popover hide];
    _popover.delegate = _saveDelegate;
    
    if (_delegate)
        [_delegate NVDataLoaderFailed:NVDL_USERCANCELLED];
}

- (void) SettingsViewControllerSuccess
{

    [_dbList removeObjectAtIndex:0];
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       [_popover hide];

    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.15
                                                  target:self
                                                selector:@selector(checkNextDataset:)
                                                userInfo:nil
                                                 repeats:NO];
                   });
}

- (void) SettingsViewControllerFailed:(int)status
{
    [_delegate NVDataLoaderFailed:status];
}

- (void)checkNextDataset:(NSTimer *)timer
{
    FTPDataType dataSetID = 0;
    [self.timer invalidate];
Top:
    if (!_dbList.count)
    {
        _svc.popover = nil;
        _svc.delegate = nil;
        _svc = nil;
        self.timer = nil;
        self.dbList = nil;
        [_delegate NVDataLoaderSuccess];
        CRAPI.sharedInstance.keepProcessing = 1;
        return;
    }
    
    NSNumber *dsid = _dbList[0];
    dataSetID = (FTPDataType)dsid.integerValue;
    
    if ([self haveDataset:dataSetID])
    {
        [_dbList removeObjectAtIndex:0];
        goto Top;
    }
        
    [self getNextDataset:dataSetID];
}

- (void)getNextDataset:(FTPDataType)dataSetID
{
    CRAPI.sharedInstance.keepProcessing = -1;
    [self.timer invalidate];
    
    if (!_svc)
    {
        _svc = [[SettingsViewController alloc] init];
        _svc.delegate = self;
        [_svc initFromDataLoader:_popover];
    }
    
    SEL sel = nil;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    
    switch (dataSetID)
    {
        case GetDatabaseSettingParcels:
            sel = @selector(loadParcels:);
            break;
            
        case GetDatabaseSettingProperty:
            sel = @selector(loadDatabase:);
            break;
            
        case GetDatabaseSettingSewer:
            sel = @selector(loadSewer:);
            break;
            
        case GetDatabaseSettingAlleyWall:
            sel = @selector(loadAlleyWall:);
            break;
            
        case GetDatabaseSettingCurbRamp:
            sel = @selector(loadCurbRamps:);
            break;
            
        case GetDatabaseSettingPlan:
            sel = @selector(loadPlan:);
            break;
            
        case GetDatabaseSettingCensus:
            sel = @selector(loadCensus:);
            break;
            
        case GetDatabaseSettingAreas:
            sel = @selector(loadAreas:);
            break;
            
        case GetDatabaseSettingNVMetro:
            sel = @selector(loadNVMetro:);
            break;
            
        case GetDatabaseSettingMapleGrove:
            sel = @selector(loadMapleGrove:);
            break;
            
        case GetDatabaseSettingHunting:
            sel = @selector(loadHunting:);
            break;
            
        case GetDatabaseSettingDTM:
            sel = @selector(loadDTM:);
            break;
            
        case GetDatabaseSettingNWI:
            sel = @selector(loadNWIData:);
            break;
            
        case GetDatabaseSettingForest:
            sel = @selector(loadFORESTData:);
            break;
            
        case GetDatabaseSettingCrimes:
            sel = @selector(loadCrimeData:);
            break;

        default:
            break;
    }
    
#pragma clang diagnostic pop
    if (sel)
    {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                                      target:_svc
                                                    selector:sel
                                                    userInfo:nil
                                                     repeats:NO];
    }
}

- (BOOL)haveDataset:(FTPDataType)dataSetID
{
    BOOL rtn = NO;
    
    switch (dataSetID)
    {
        case GetDatabaseSettingNVMetro:
        case GetDatabaseSettingParcels:
        {
            PropertyData *pd = [[PropertyData alloc] init];
            
            if (pd.parcelDatasetVersion >= 17)
                rtn = YES;
        }
            break;
            
        case GetDatabaseSettingCrimes:
        {
            CrimeData *cd = [[CrimeData alloc] init];
            
            if (cd.datasetVersion >= 2)
                rtn = YES;
        }
            break;
            
        case GetDatabaseSettingProperty:
        {
            PropertyData *pd = [[PropertyData alloc] init];
            
            if (pd.propertyDatasetVersion >= -1)
                rtn = YES;
        }
            break;
            
        case GetDatabaseSettingAreas:
        {
            BoundaryData *bd = [[BoundaryData alloc] init];
            
            if (bd.datasetVersion >= 2)
                rtn = YES;
        }
            break;
            
        case GetDatabaseSettingSewer:
        {
            SewerData *sd = [[SewerData alloc] init];
            if (sd.datasetVersion >= 0)
                rtn = YES;
        }
            break;
            
        case GetDatabaseSettingAlleyWall:
        {
            AlleyWallData *awd = [[AlleyWallData alloc] init];
            
            if (awd.datasetVersion >= 3)
                rtn = YES;
        }
            break;
            
        case GetDatabaseSettingCurbRamp:
        {
            CurbRampData *crd = [CurbRampData databaseForGeoid:CRAPI.sharedInstance.currentGeoid
                                                        create:NO];
            
            if (crd.datasetVersion >= 1)
                rtn = YES;
        }
            break;
            
        case GetDatabaseSettingCensus:
        {
            PropertyData *pd = [[PropertyData alloc] init];
            
            if (pd.censusDatasetVersion >= 2)
                rtn = YES;
        }
            break;
            
        case GetDatabaseSettingPlan:
        {
            PropertyData *pd = [[PropertyData alloc] init];
            
           // if (pd.planDatasetVersion > -1)
                rtn = YES;
        }
            break;
            
        case GetDatabaseSettingMapleGrove:
        {
            NSString *fileName = @"swPressurePipe.shp";
            NSString *documentsDirectory = UserDefaults.defaults.sharedFilePath;
            NSString *outputDirectory = [NSString stringWithFormat:@"%@/MapleGrove", documentsDirectory];
            
            NSString *shapeFile = [NSString stringWithFormat:@"%@/%@", outputDirectory,fileName];
            ShapeFileDisplay *sfd = [ShapeFileDisplay createWithFile:shapeFile.UTF8String];
            if (sfd)
                rtn = YES;
            
        }
            break;
            
        case GetDatabaseSettingHunting:
        {
            HuntingData *hd = [[HuntingData alloc] init];
            
            if (hd.datasetVersion.integerValue > 7)
                rtn = YES;
        }
            break;
            
        case GetDatabaseSettingDTM:
        {
            DTMData *dtm = [[DTMData alloc] init];
            BOOL opened = [dtm open:0];
            if (dtm.version >= 8)
                rtn = YES;
            [dtm close:opened];
        }
            break;
            
        case GetDatabaseSettingNWI:
        {
            HuntingData *hd = [[HuntingData alloc] init];
            
            if (hd.NWIVersion.integerValue >= 10)
                rtn = YES;
        }
            break;
        case GetDatabaseSettingForest:
        {
            HuntingData *hd = [[HuntingData alloc] init];
            
            if (hd.ForestVersion.integerValue >= 3)
                rtn = YES;
        }
            break;
        case GetDatabaseSettingFEESURF:
            rtn = YES;
            break;
        default:
            break;
    }
    
    return rtn;
}

@end
