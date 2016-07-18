//  UploadDirectory.m
//  NVMobile

#import "UploadDirectory.h"
#import "CCodeLibrary/CRAPI.h"
#import "CCodeLibrary/FileLister.h"
#import "CCodeLibrary/MathUtil.h"
#import "CCodeLibrary/CCodeLibrary.h"
#import "CCodeLibrary/NVPopoverTableView.h"

@interface UploadDirectory () <NVPopoverTableViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *currentDirectoryLabel;

@end

@implementation UploadDirectory

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _popover = [[GSSiPopoverView alloc] initWithView:self.view];
    _popover.delegate = self;
    NSString *documentsDirectory = UserDefaults.defaults.localFilePath;
    _fileListFile = [NSString stringWithFormat:@"%@/filelist.txt", documentsDirectory];
    _lastFileFile = [NSString stringWithFormat:@"%@/lastfile.txt", documentsDirectory];
    _dirToUpload = @"AlleyWalls";
    _fromDir = [CRAPI.sharedInstance sharedOutputDirectory:_dirToUpload];
    _fromDir = textUpTo (_fromDir,@"AlleyWalls");
    _currentDirectoryLabel.text = _fromDir;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [UIApplication.sharedApplication setIdleTimerDisabled:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [UIApplication.sharedApplication setIdleTimerDisabled:NO];
}

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
    LPSTR str = malloc(4096);
    while (fgetstring(str, (4090 - 2), fid))
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
    _startButton.enabled = NO;
    _returnButton.enabled = NO;
    NSString * dir2 =[NSString stringWithFormat:@"%i/%@",CRAPI.sharedInstance.GSSiPadNumber,_dirToUpload];
    
    _nFiles = [FileLister listFilesInDirectory:_fromDir
                                      outputTo:_fileListFile
                                     totalSize:&_totSize];
    NSArray * directories = [self getSubdirFromFileList:_fileListFile
                                          addUnder:dir2];
    
    _ftpcd = [FTPDirectoryCreate createDirectories:directories
                                       inFTPDomain:@"gssiserver3.com"
                                         directory:@"NVMobile/UploadedDirectories"
                                          username:@"GSSiProfessionalServer"
                                          password: @"GSSi"
                                              port:@"21"
                                          delegate:self];
}

- (void)FTPDirectoryCreateDidCompleteWithStatus:(FTPStatus)status
                                   statusString:(NSString *)statusString
                                      directory:(NSString *)directory
{
    _currentFile = 0;
    [self saveCurrentFile];
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
    if (!fid)
        return;
    NSInteger totLen = FileLength(fid);
    fseek (fid,_currentFile,SEEK_SET);
    if (totLen > 0)
    {
        int pctDone = (int)(100 * _currentFile)/totLen;
        _messageLabel.text = [NSString stringWithFormat:@"%i percent complete",pctDone];
    }
    BOOL haveFile = NO;
    NSString * path = @"";
    if (fgetstring(str, (4090 - 2), fid))
    {
        _nextFile = ftell (fid);
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
        [NSFileManager.defaultManager removeItemAtPath:_fileListFile
                                                 error:nil];
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
    {
        _currentFile = _nextFile;
        [self saveCurrentFile];
        [self uploadNextFile];
    }
    else
        [_popover showAfter:0.1
                  withTitle:[NSString stringWithFormat:@"Upload Error\n%@",statusString]];
    
}
- (void)GSSiPopoverViewdidCancel:(GSSiPopoverView *)popoverView
{
    _startButton.enabled = YES;
    _returnButton.enabled = YES;
}


- (IBAction)return:(id)sender {
    [self dismissViewControllerAnimated:YES
                             completion:nil];

}

- (void) saveCurrentFile
{
    NSString *str = [NSString stringWithFormat:@"%li",(long)_currentFile];
    [str writeToFile:_lastFileFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
}
- (IBAction)restart:(id)sender {
    FILE *fid = fopen(_lastFileFile.UTF8String, "rb");
    LPSTR str = malloc(4096);
    _currentFile = -1;
    if (fgetstring(str, (4090 - 2), fid))
    {
        _currentFile = atol (str);
    }
    fclose(fid);
    free(str);
    if (_currentFile > -1)
        [self uploadNextFile];
}

- (IBAction)skipAndRestart:(id)sender {
    BOOL haveFile = NO;
    FILE *fid = fopen(_lastFileFile.UTF8String, "rb");
    LPSTR str = malloc(4096);
    _currentFile = -1;
    _nextFile = -1;
    if (fgetstring(str, (4090 - 2), fid))
    {
        _currentFile = atol (str);
    }
    fclose(fid);
    if (_currentFile > -1)
    {
        fid = fopen(_fileListFile.UTF8String, "rb");
        fseek (fid,_currentFile,SEEK_SET);
        if (fgetstring(str, (4090 - 2), fid))
        {
            _nextFile = ftell (fid);
            haveFile = YES;
        }
        fclose(fid);
    }
    free(str);
    if (_nextFile > -1)
    {
        _currentFile = _nextFile;
        [self uploadNextFile];
    }
    
}

- (IBAction)pickDirectory:(id)sender
{
    NSArray *directories = [CRAPI.sharedInstance.docManager directoriesInDirectory:CRAPI.sharedInstance.sharedOutputDirectory].copy;
    
    NVPopoverTableView *tableView = [NVPopoverTableView showPopoverTableViewInView:self.view
                                                                          delegate:self
                                                                             title:@"Directory List"
                                                                         textArray:directories
                                                                     includeCancel:YES];
#pragma unused(tableView)
}

- (void)popoverTableViewDidCancel:(NVPopoverTableView *)popoverTableView
{
    [popoverTableView hide:YES];
}

- (void)popoverTableView:(NVPopoverTableView *)popoverTableView
    didSelectRowWithText:(NSString *)text
                 atIndex:(NSInteger)index
{
    [popoverTableView hide:YES];
    
    _dirToUpload = text;
    _fromDir = [CRAPI.sharedInstance sharedOutputDirectory:_dirToUpload];
    _fromDir = textUpTo(_fromDir, text);
    _currentDirectoryLabel.text = _fromDir;
}

@end