//
//  NVDataLoader.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 5/29/15.
//  Copyright (c) 2015 GSSi. All rights reserved.
//

#import "NVDataLoader.h"

@implementation NVDataLoader
- (void) loadNVData:(HardCodedConfigs)appID
            popover:(GSSiPopoverView*)popover
{
    _popover = popover;
    _saveDelegate = popover.delegate;
    _popover.delegate = self;
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
@end
