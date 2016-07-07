//
//  UploadDirectory.m
//  NVMobile
//
//  Created by Jeff Smith on 7/6/16.
//  Copyright © 2016 GSSi. All rights reserved.
//

#import "UploadDirectory.h"
#import "CCodeLibrary/CRAPI.h"
#import "CCodeLibrary/FileLister.h"
#import "CCodeLibrary/MathUtil.h"
#import "CCodeLibrary/StringFunctions.h"
#import <Foundation/Foundation.h>

@interface UploadDirectory ()

@end

@implementation UploadDirectory

- (void)viewDidLoad
{
    [super viewDidLoad];
    _popover = [[GSSiPopoverView alloc] initWithView:self.view];
    _popover.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void) addDir:(NSString*)path
        toArray:(NSMutableArray*)array
          under:(NSString*)under
{
    NSString * newDir = [NSString stringWithFormat:@"/%@%@",under,path];
    NSString * curDir = [newDir stringByDeletingLastPathComponent];
    
    while (![curDir isEqualToString:@"/"])
    {
        NSString *dir2 = textAfter (curDir,@"/");
        for (NSString * dir in array)
        {
            if ([dir isEqualToString:dir2])
                goto NextDir;
        }
        [array addObject:dir2];
    NextDir:
        curDir = [curDir stringByDeletingLastPathComponent];
    }
    return;
}
- (void)sortByLength:(NSMutableArray *)array
{
    [array sortUsingComparator: ^(id obj1, id obj2)
     {
         NSString * s1 = obj1;
         NSString * s2 = obj2;
         
         if (s1.length > s2.length)
             return (NSComparisonResult)NSOrderedDescending;
         
         if (s1.length < s2.length)
             return (NSComparisonResult)NSOrderedAscending;
         
         return (NSComparisonResult)NSOrderedSame;
     }];
}

- (NSArray*) getSubdirFromFileList:(NSString*)file
                          addUnder:(NSString*)under
{
    NSMutableArray * array = [NSMutableArray new];
    FILE *fid = fopen(file.UTF8String, "rb");
    NSInteger totLen = FileLength(fid);
    LPSTR str = malloc(4096);
    _keepGoing = TRUE;
    while (_keepGoing && fgetstring(str, (4090 - 2), fid))
    {
        NSString * path = textBeforeTab ([NSString stringWithUTF8String:str]);
        NSString * path2 = [NSString stringWithFormat:@"/%@",path];
        [self addDir:path2
             toArray:array
               under:under];
    }
    fclose(fid);
    free(str);
    [self sortByLength:array];
    return array;
}
- (IBAction)startTransfer:(id)sender {
    _dirToUpload = @"AlleyWalls";
    _startButton.enabled = NO;
    _returnButton.enabled = NO;
    NSString * dir2 =[NSString stringWithFormat:@"%i/%@",CRAPI.sharedInstance.GSSiPadNumber,_dirToUpload];
    
    _fromDir = [CRAPI.sharedInstance sharedOutputDirectory:_dirToUpload];
    _fromDir = textUpTo (_fromDir,@"AlleyWalls");
    
    _fileListFile = [NSString stringWithFormat:@"%@/filelist.txt",NSTemporaryDirectory()];
    
    _nFiles = [FileLister listFilesInDirectory:_fromDir
                                      outputTo:_fileListFile
                                     totalSize:&_totSize];
    NSArray * directories = [self getSubdirFromFileList:_fileListFile
                                          addUnder:dir2];
    
    _ftpcd = [FTPDirectoryCreate createDirectories:directories
                                       inFTPDomain:@"gssiserver3.com"
                                         directory:@"NVMobile/UploadedDirectories"
                                          username:@"GSSiProfessionalServer"                                 password: @"GSSi"
                                              port:@"21"
                                          delegate:self];
}

- (void)FTPDirectoryCreateDidCompleteWithStatus:(FTPStatus)status
                                   statusString:(NSString *)statusString
                                      directory:(NSString *)directory
{
    _currentFile = 0;
    if (status == FTPStatusOK)
    {
        [self uploadNextFile];
    }
    else
    {
        [NSFileManager.defaultManager removeItemAtPath:_fileListFile
                                                 error:nil];
        _popover.title = [NSString stringWithFormat:@"Unable to create directories\n%@",statusString];
        [_popover setCancelButtonTitle:@"OK"];
        [_popover show];
    }
}

- (void) doUploadNextFile:(NSTimer*)timer
{
    [timer invalidate];
    LPSTR str = malloc(4096);
    FILE *fid = fopen(_fileListFile.UTF8String, "rb");
    fseek (fid,_currentFile,SEEK_SET);
    BOOL haveFile = NO;
    NSString * path = @"";
    if (_keepGoing && fgetstring(str, (4090 - 2), fid))
    {
        _currentFile = ftell (fid);
        haveFile = YES;
        path = textBeforeTab ([NSString stringWithUTF8String:str]);
    }
    fclose(fid);
    free(str);
    if (haveFile)
    {
        _push = [FTPDataPush push];
        _push.delegate = self;
        _push.popover = _popover;
        
        NSString *toDir = [NSString stringWithFormat:@"NVMobile/UploadedDirectories/%i/%@/%@",CRAPI.sharedInstance.GSSiPadNumber,_dirToUpload,path];
        toDir = [toDir stringByDeletingLastPathComponent];
        NSString * sendToServerFile = [NSString stringWithFormat:@"%@/%@",_fromDir,path];
        NSString *file = [sendToServerFile lastPathComponent];
        NSString *fromDir = [sendToServerFile stringByDeletingLastPathComponent];
        
        [_popover showAfter:0.1
                  withTitle:path];
        
        [_push sendFile:file
          fromDirectory:fromDir
                 toFile:file
            toDirectory:toDir
         deleteWhenDone:NO];
    }
    else
    {
        _popover.cancelButtonTitle = @"OK";
        [_popover showAfter:0.1
                  withTitle:[NSString stringWithFormat:@"Upload Complete"]];
    }


}
- (void) uploadNextFile
{
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                              target:self
                                            selector:@selector(doUploadNextFile:)
                                            userInfo:nil
                                             repeats:NO];
}

- (void)FTPPushDidComplete:(FTPDataType)dataType
                withStatus:(FTPStatus)status
           andStatusString:(NSString *)statusString
                  filePath:(NSString *)pathint
{
    if (status == FTPStatusOK)
        [self uploadNextFile];
    else
        [_popover showAfter:0.1
                  withTitle:[NSString stringWithFormat:@"Upload Error\n%@",statusString]];
    
}
- (void)GSSiPopoverViewdidCancel:(GSSiPopoverView *)popoverView
{
    _keepGoing = NO;
    [NSFileManager.defaultManager removeItemAtPath:_fileListFile
                                             error:nil];
    _startButton.enabled = YES;
    _returnButton.enabled = YES;
}


- (IBAction)return:(id)sender {
    [self dismissViewControllerAnimated:YES
                             completion:nil];

}
@end
