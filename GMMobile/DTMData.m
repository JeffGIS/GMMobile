//
//  DTMData.m
//  NVMobile
//
//  Created by Jeff Smith on 1/4/23.
//  Copyright © 2023 GSSi. All rights reserved.
//

#import "DTMData.h"
@interface DTMData ()

@property (nonatomic, copy) NSString *documentsDirectory;
@property (nonatomic, copy) NSString *backedUpDirectory;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *pathDTM;
@property (nonatomic, copy) NSString *pathDTM_IN1;
@property NSInteger fileSize;
@property NSInteger fileSizeDTM;
@property NSInteger fileSizeDTM_IN1;
@end

@implementation DTMData

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _documentsDirectory = UserDefaults.defaults.nonBackedUpFilePath;
        _backedUpDirectory = UserDefaults.defaults.localFilePath;
        _pathDTM = [_documentsDirectory stringByAppendingString:@"/DTM/MNDTM1.dtm"];
        _pathDTM_IN1 = [_documentsDirectory stringByAppendingString:@"/DTM/MNDTM1.in1"];
        

        NSLog(@"DTM Database init");
    }
    
    return self;
}

- (void)dealloc
{
    [self close:TRUE];
    NSLog(@"DTM Database dealloc");
}

- (BOOL)open
{
    BOOL rtn = FALSE;
    if (!_isOpen)
    {
        BOOL delete = NO;
        if (delete)
            [NSFileManager.defaultManager removeItemAtPath:_pathDTM
                                                     error:nil];
        
        NSLog(@"DTM Database open");
        
        int fileSize = (NSInteger)[NSFileManager.defaultManager attributesOfItemAtPath:_pathDTM
                                                                                 error:nil].fileSize;
        int fileSizeIN1 = (NSInteger)[NSFileManager.defaultManager attributesOfItemAtPath:_pathDTM_IN1
                                                                                    error:nil].fileSize;
        if (fileSize > 0 && fileSizeIN1 > 0)
        {
            _fidDTM = fopen (_pathDTM.UTF8String,"rb");
            _fidDTM_IN1 = fopen (_pathDTM_IN1.UTF8String,"rb");
            _haveDTM = YES;
            rtn = YES;
            _isOpen = YES;
        }
    }
    return rtn;
}
- (void)close:(BOOL)opened
{
    if (opened && _isOpen)
    {
        fclose(_fidDTM);
        fclose(_fidDTM_IN1);
        NSLog(@"DTM Database close");
        _isOpen = NO;
    }
}


@end
