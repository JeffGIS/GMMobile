//  NVDataLoader.m
//  GMMobile

#import "NVDataLoader.h"
#import "AlleyWallData.h"
#import "PropertyData.h"
#import "AlleyWallData.h"

@implementation NVDataLoader

- (void) dealloc
{
    NSLog (@"Dataloader released");
}

- (void)loadNVData:(HardCodedConfigs)appID
           popover:(GSSiPopoverView *)popover
{
    _popover = popover;
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
    [_popover hide];

    [_dbList removeObjectAtIndex:0];
    dispatch_async(dispatch_get_main_queue(),
                   ^{
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
    GetDatabaseSetting dataSetID = GetDatabaseSettingDefault;
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
        return;
    }
    
    NSNumber *dsid = _dbList[0];
    dataSetID = dsid.integerValue;
    
    if ([self haveDataset:dataSetID])
    {
        [_dbList removeObjectAtIndex:0];
        goto Top;
    }
        
    [self getNextDataset:dataSetID];
}

- (void)getNextDataset:(GetDatabaseSetting)dataSetID
{
    [self.timer invalidate];
    
    if (!_svc)
    {
        _svc = [[SettingsViewController alloc] init];
        _svc.delegate = self;
        [_svc initFromDataLoader:_popover];
    }
    
    SEL sel = nil;
    
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
            
        default:
            break;
    }
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                                  target:_svc
                                                selector:sel
                                                userInfo:nil
                                                 repeats:NO];
    
    
}

- (BOOL)haveDataset:(GetDatabaseSetting)dataSetID
{
    BOOL rtn = NO;
    
    switch (dataSetID)
    {
        case GetDatabaseSettingParcels:
        {
            PropertyData *pd = [[PropertyData alloc] init];
            
            if (pd.parcelDatasetVersion >= 0)
                rtn = YES;
        }
            break;
            
        case GetDatabaseSettingProperty:
        {
            PropertyData *pd = [[PropertyData alloc] init];
            
            if (pd.propertyDatasetVersion >= 0)
                rtn = YES;
        }
            break;
            
        case GetDatabaseSettingAreas:
        {
            PropertyData *pd = [[PropertyData alloc] init];
            
            if (pd.areasDatasetVersion >= 0)
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
            
            if (awd.datasetVersion >= 1)
                rtn = YES;
        }
            break;
            
        case GetDatabaseSettingCurbRamp:
        {
            CurbRampData *crd = [CurbRampData databaseForGeoid:CRAPI.sharedInstance.currentGeoid];
            
            if (crd.datasetVersion >= 1)
                rtn = YES;
        }
            break;
            
        case GetDatabaseSettingCensus:
        {
            PropertyData *pd = [[PropertyData alloc] init];
            
            if (pd.censusDatasetVersion >= 0)
                rtn = YES;
        }
            break;
            
        case GetDatabaseSettingPlan:
        {
            PropertyData *pd = [[PropertyData alloc] init];
            
            if (pd.planDatasetVersion >= 0)
                rtn = YES;
        }
            break;
            
        default:
            break;
    }
    
    return rtn;
}

@end