//
//  NVDataLoader.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 5/29/15.
//  Copyright (c) 2015 GSSi. All rights reserved.
//

#import "NVDataLoader.h"
#import "AlleyWallData.h"
#import "SewerData.h"
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
    ConfigurationControl *cfc = [[ConfigurationControl alloc] init];
    _dbList = [cfc getDatasetsForApp:appID];
    
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
    {
        [_delegate NVDataLoaderFailed:NVDL_USERCANCELLED];
    }
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

- (void) checkNextDataset:(NSTimer *)timer
{
    int dataSetID;
    [self.timer invalidate];
Top:
    if (![_dbList count])
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
    dataSetID = (int)[dsid integerValue];
    
    if ([self haveDataset:dataSetID])
    {
        [_dbList removeObjectAtIndex:0];
        goto Top;
    }
        
    [self getNextDataset:dataSetID];
}

- (void) getNextDataset:(int)dataSetID
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
        case GET_PARCELS:
            sel = @selector(loadParcels:);
            break;
            
        case GET_PROPERTY:
            sel = @selector(loadDatabase:);
            break;
            
        case GET_SEWER:
            sel = @selector(loadSewer:);
            break;
            
        case GET_ALLEYWALL:
            sel = @selector(loadAlleyWall:);
            break;
            
        case GET_PLAN:
            sel = @selector(loadPlan:);
            break;
            
        case GET_CENSUS:
            sel = @selector(loadCensus:);
            break;
            
        case GET_AREAS:
            sel = @selector(loadAreas:);
            break;
    }
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                                  target:_svc
                                                selector:sel
                                                userInfo:nil
                                                 repeats:NO];
    
    
}

- (BOOL)haveDataset:(int)dataSetID
{
    BOOL rtn = NO;
    
    switch (dataSetID)
    {
        case GET_PARCELS:
        {
            PropertyData *pd = [[PropertyData alloc] init];
            
            if (pd.parcelDatasetVersion >= 0)
                rtn = YES;
        }
            break;
            
        case GET_PROPERTY:
        {
            PropertyData *pd = [[PropertyData alloc] init];
            
            if (pd.propertyDatasetVersion >= 0)
                rtn = YES;
        }
            break;
            
        case GET_AREAS:
        {
            PropertyData *pd = [[PropertyData alloc] init];
            
            if (pd.areasDatasetVersion >= 0)
                rtn = YES;
        }
            break;
            
        case GET_SEWER:
        {
            SewerData *sd = [[SewerData alloc] init];
            if (sd.datasetVersion >= 0)
                rtn = YES;
        }
            break;
            
        case GET_ALLEYWALL:
        {
            AlleyWallData *awd = [[AlleyWallData alloc] init];
            
            if (awd.datasetVersion >= 0)
                rtn = YES;
        }
            break;
            
        case GET_CENSUS:
        {
            PropertyData *pd = [[PropertyData alloc] init];
            
            if (pd.censusDatasetVersion >= 0)
                rtn = YES;
        }
            break;
            
        case GET_PLAN:
        {
            PropertyData *pd = [[PropertyData alloc] init];
            
            if (pd.planDatasetVersion >= 0)
                rtn = YES;
        }
            break;
    }
    
    return rtn;
}

@end