//  UploadADAViewController.m
//  PedRampInv_Detail

#include <string.h>
#import "UploadViewController.h"
#import "AppDelegate.h"
#import <CFNetwork/CFNetwork.h>

@interface UploadViewController ()

@property (nonatomic, readonly) BOOL isSending;
@property (nonatomic, retain) NSOutputStream *networkStream;
@property (nonatomic, retain) NSInputStream *fileStream;
@property (nonatomic, readonly) uint8_t *buffer;
@property (nonatomic, assign) size_t bufferOffset;
@property (nonatomic, assign) size_t bufferLimit;
@property NSString* subdir;

@end

@implementation UploadViewController
{
    UIColor *_label1Color, *_label2Color, *_backgroundColor, *_textColor, *_darkLabel2Color, *_lightLabel2Color;
    long fileSize, totBytesWritten;
    int _numToSkip;
    NSString * _createDirectoryFile1;
    NSString * _createDirectoryFile2;
}

- (BOOL) validUploadSubDirectory:(NSString*)subdir
{
    if ([subdir isEqualToString:@"AlleyWallInventory"])
        return YES;
    return NO;
}

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil
                           bundle:nibBundleOrNil];
    
    if (self)
    {
        
    }
    
    return self;
}

- (void) listFilesToUpload
{
Top:;
    int n = 0;
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSString *firstFile;
    
    _urlText = [[NSString alloc] initWithFormat:@"www.thmgis.com/GMMobileUploads/%@/", CRAPI.sharedInstance.organizationName];
    
    _usernameText = @"waypoint";
    _passwordText = @"pointway4*";
    
    sleep(1);
    
    /*if ([NSFileManager.defaultManager fileExistsAtPath:_createDirectoryFile1])
    {
        firstFile = _createDirectoryFile1.lastPathComponent;
        n = 1;
    }
    
    else if ([NSFileManager.defaultManager fileExistsAtPath:_createDirectoryFile2])
    {
        firstFile = _createDirectoryFile2.lastPathComponent;
        n = 1;
    }
    
    else*/ for (NSString *fileName in [fileManager contentsOfDirectoryAtPath:_outputDirectory
                                                                     error:nil])
    {
        NSString *leafName = fileName.lastPathComponent;
        
        if (![leafName hasPrefix:@"Uploaded"])
        {
            NSArray * substr = [leafName componentsSeparatedByString:@"_"];
            if ([self validUploadSubDirectory:(NSString*)substr[0]])
            {
                if (n == _numToSkip)
                {
                    firstFile = fileName;
                    _subdir = (NSString*)substr[0];
                }
                n++;
            }
        }
    }
    
    _fileListRef.text = firstFile;
    _numberToUploadRef.text = [NSString stringWithFormat:@"%i Files to Upload", n];
    
    if (!firstFile)
    {
        _returnButton.hidden = NO;
        _helpButton.hidden = NO;
        _cancelButton.hidden = YES;
        
        if (_numToSkip)
            _statusLabel.text = [NSString stringWithFormat:@"%i files skipped", _numToSkip];
        
        [self setupLabels];
        return;
    }
    
    if (n > 0)
    {
        if (![self startSend:firstFile])
        {
            _numToSkip++;
            goto Top;
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _numToSkip = 0;
    
    _outputDirectory = CRAPI.sharedInstance.sharedOutputDirectory;
    _helpButton.hidden = YES;
    _returnButton.hidden = YES;
    
    [self setupDefaults];
    [self setupLabels];
    [self setupTextColor];
    
    [_progressBarRef setProgress:0];
    [_progressBarRef setProgressViewStyle:UIProgressViewStyleBar];
/*    _createDirectoryFile1 = [NSString stringWithFormat:@"%@/createDirectoryFile1.txt", _outputDirectory];
    
    [_createDirectoryFile1 writeToFile:_createDirectoryFile1
                            atomically:YES
                              encoding:NSUTF8StringEncoding
                                 error:nil];
    
    _createDirectoryFile2 = [NSString stringWithFormat:@"%@/createDirectoryFile2.txt", _outputDirectory];
    
    [_createDirectoryFile2 writeToFile:_createDirectoryFile2
                            atomically:YES
                              encoding:NSUTF8StringEncoding
                                 error:nil];*/
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self listFilesToUpload];
}

- (void)setupDefaults
{
    _backgroundColor = CRAPI.sharedInstance.defaultColors.backgroundColor;
    _label1Color = CRAPI.sharedInstance.defaultColors.enabledColor;
    _label2Color = CRAPI.sharedInstance.defaultColors.disabledColor;
    _textColor = CRAPI.sharedInstance.defaultColors.titleColor;
    _darkLabel2Color = [UserDefaults.defaults darkColorForColor:_label2Color];
    _lightLabel2Color = [UserDefaults.defaults lightColorForColor:_label2Color];
    self.view.backgroundColor = _backgroundColor;
}

- (void)setupLabels
{
    float cornerRadius = 10.0;
    
    _cancelButton.layer.cornerRadius = cornerRadius;
    _cancelButton.backgroundColor = _label1Color;
    _returnButton.layer.cornerRadius = cornerRadius;
    _returnButton.backgroundColor = _label1Color;
    
    [_cancelButton setTitleColor:_textColor
                        forState:UIControlStateNormal];
    
    [_returnButton setTitleColor:_textColor
                        forState:UIControlStateNormal];
}

- (void)setupTextColor
{
    if ([UserDefaults.defaults pickAdjustedTextColorForColor1:_backgroundColor
                                                       color2:_label2Color])
    {
        _numberToUploadRef.textColor = _lightLabel2Color;
        _fileListRef.textColor = _lightLabel2Color;
        _statusLabel.textColor = _lightLabel2Color;
    }
    
    else
    {
        _numberToUploadRef.textColor = _darkLabel2Color;
        _fileListRef.textColor = _darkLabel2Color;
        _statusLabel.textColor = _darkLabel2Color;
    }
}

- (IBAction)listDirectory:(id)sender
{
    int count;
    
    NSString *documentsDirectory = UserDefaults.defaults.localFilePath;
    //NSString *documentsDirectory = UserDefaults.defaults.sharedFilePath;
    
    NSString *dirName = [NSString stringWithFormat:@"%@/ADAFiles", documentsDirectory];
    
    NSArray *directoryContent = [NSFileManager.defaultManager contentsOfDirectoryAtPath:dirName
                                                                                  error:nil];
    
    for (count = 0; count < (int)directoryContent.count; count++)
    {
        NSLog(@"File %d: %@", (count + 1), [directoryContent objectAtIndex:count]);
    }
}

- (void)sendDidStart
{
    _statusLabel.text = [NSString stringWithFormat:@"Sending %@", _currentFile.lastPathComponent];
    _cancelButton.hidden = NO;
    [self setupLabels];
    
    [AppDelegate.sharedAppDelegate didStartNetworking];
}

- (void)updateStatus:(NSString *)statusString
{
    assert(statusString);
    _statusLabel.text = statusString;
}

- (void)sendDidStopWithStatus:(NSString *)statusString
                         code:(long)code
{
    _statusLabel.text = statusString;
    _cancelButton.hidden = YES;
    
    [AppDelegate.sharedAppDelegate didStopNetworking];
    
    if (!statusString)
    {
        NSString *newName = [NSString stringWithFormat:@"%@/Uploaded_%@",
                             _outputDirectory, _currentFile.lastPathComponent];
        
        BOOL rtn = [NSFileManager.defaultManager removeItemAtPath:newName
                                                 error:nil];
        rtn = [NSFileManager.defaultManager moveItemAtPath:_currentFile
                                                    toPath:newName
                                                     error:nil];

        [self listFilesToUpload];
    }
    
    else if (code == 200 &&
             ([_currentFile.lastPathComponent isEqualToString:@"createDirectoryFile1.txt"] ||
              [_currentFile.lastPathComponent isEqualToString:@"createDirectoryFile2.txt"]))
    {
        [NSFileManager.defaultManager removeItemAtPath:_currentFile
                                                 error:nil];
        
        [self listFilesToUpload];
    }
    
    else
    {
        _returnButton.hidden = NO;
        _helpButton.hidden = NO;
    }
    
    [self setupLabels];
}

- (uint8_t *)buffer
{
    return self->_buffer;
}

- (BOOL)isSending
{
    if (_networkStream)
        return YES;
    
    else
        return NO;
}

- (void)showError:(NSString *)theString
{
    _statusLabel.text = theString;
    _numToSkip++;
}

- (BOOL)startSend:(NSString *)filePath
{
    NSURL *url;
    CFWriteStreamRef ftpStream;
    
    NSString *fullPath = [NSString stringWithFormat:@"%@/%@",
                          _outputDirectory, filePath];
    
    NSString *myName = UIDevice.currentDevice.name;
    NSString *lastpart = filePath.lastPathComponent;
    NSString *woextn = lastpart.stringByDeletingPathExtension;
    
    unichar xd5 = 0xd5;
    NSString *mStr = [NSString stringWithFormat:@"%C", xd5];
    
    myName = [myName stringByReplacingOccurrencesOfString:@"'"
                                               withString:@""];
    
    myName = [myName stringByReplacingOccurrencesOfString:@"."
                                               withString:@""];
    
    myName = [myName stringByReplacingOccurrencesOfString:@" "
                                               withString:@""];
    
    myName = [myName stringByReplacingOccurrencesOfString:mStr
                                               withString:@""];
    
    [_progressBarRef setProgress:0];
    _currentFile = fullPath;
    
    if (![NSFileManager.defaultManager fileExistsAtPath:fullPath])
        return NO;
    
    NSDictionary *fileAttributes = [NSFileManager.defaultManager attributesOfItemAtPath:fullPath
                                                                                  error:nil];
    
    fileSize = (long)fileAttributes.fileSize;
    totBytesWritten = 0;
    
    if (fileSize == 0)
        return NO;
    
    if (!([filePath.pathExtension isEqualToString:@"png"] ||
          [filePath.pathExtension isEqualToString:@"jpg"] ||
          [filePath.pathExtension isEqualToString:@"txt"]))
    {
        return NO;
    }
    
    assert(!_networkStream);
    assert(!self.fileStream);
    
    if ([woextn isEqualToString:@"createDirectoryFile1"])
    {
        url = [NetworkManager.sharedInstance smartURLForString:[NSString stringWithFormat:@"%@/",
                                                                  [_urlText stringByDeletingLastPathComponent]]];
    }
    
    else if ([woextn isEqualToString:@"createDirectoryFile2"])
    {
        url = [NetworkManager.sharedInstance smartURLForString:[NSString stringWithFormat:@"%@/",
                                                                  _urlText]];
    }
    
    else
    {
        NSString* removeSubDir = [_subdir stringByAppendingString:@"_"];
        woextn = [woextn stringByReplacingOccurrencesOfString:removeSubDir withString:@""];
        url = [NetworkManager.sharedInstance smartURLForString:[NSString stringWithFormat:@"%@%@/%@_%@.%@",
                                                                  _urlText, _subdir,woextn, myName, filePath.pathExtension]];
    }
    
    if (!url)
    {
        _statusLabel.text = @"Invalid URL";
        return NO;
    }
    
    else
    {
        self.fileStream = [NSInputStream inputStreamWithFileAtPath:fullPath];
        
        if (!self.fileStream)
        {
            _statusLabel.text = @"Unable to open stream";
            return NO;
        }
        
        [self.fileStream open];
        
        ftpStream = CFWriteStreamCreateWithFTPURL(NULL, (__bridge CFURLRef)url);
        
        if (!ftpStream)
        {
            _statusLabel.text = @"Unable to open ftpstream";
            return NO;
        }
        
        _networkStream = (__bridge NSOutputStream *)ftpStream;
        
        if (self.usernameText.length != 0)
        {
            BOOL success = [_networkStream setProperty:_usernameText
                                                forKey:(id)kCFStreamPropertyFTPUserName];
            
            if (!success)
            {
                _statusLabel.text = @"Unable to set username";
                return NO;
            }
            
            success = [_networkStream setProperty:_passwordText
                                           forKey:(id)kCFStreamPropertyFTPPassword];
            
            if (!success)
            {
                _statusLabel.text = @"Unable to set password";
                return NO;
            }
        }
        
        _networkStream.delegate = self;
        
        [_networkStream scheduleInRunLoop:NSRunLoop.currentRunLoop
                                  forMode:NSDefaultRunLoopMode];
        
        [_networkStream open];
        CFRelease(ftpStream);
        [self sendDidStart];
    }
    return YES;
}

- (void)stopSendWithStatus:(NSString *)statusString
                      code:(long)code
{
    if (_networkStream)
    {
        [_networkStream removeFromRunLoop:NSRunLoop.currentRunLoop
                                  forMode:NSDefaultRunLoopMode];
        
        _networkStream.delegate = nil;
        [_networkStream close];
        _networkStream = nil;
    }
    
    if (self.fileStream)
    {
        [self.fileStream close];
        self.fileStream = nil;
    }
    
    [self sendDidStopWithStatus:statusString
                           code:code];
}

- (void)stream:(NSStream *)aStream
   handleEvent:(NSStreamEvent)eventCode
{
#pragma unused(aStream)
    assert(aStream == _networkStream);
    
    switch (eventCode)
    {
        case NSStreamEventOpenCompleted:
            [self updateStatus:@"Opened connection"];
            break;
            
        case NSStreamEventHasBytesAvailable:
            assert(NO);
            break;
            
        case NSStreamEventHasSpaceAvailable:
            [self updateStatus:@"Sending"];
            
            if (_bufferOffset == _bufferLimit)
            {
                NSInteger bytesRead;
                
                bytesRead = [self.fileStream read:_buffer
                                        maxLength:kSendBufferSize];
                
                if (bytesRead == -1)
                {
                    [self stopSendWithStatus:@"File read error"
                                        code:1];
                }
                
                else if (bytesRead == 0)
                    [self stopSendWithStatus:nil
                                        code:-1];
                
                else
                {
                    _bufferOffset = 0;
                    _bufferLimit  = bytesRead;
                }
            }
            
            if (_bufferOffset != _bufferLimit)
            {
                NSInteger bytesWritten = [_networkStream write:&_buffer[_bufferOffset]
                                                     maxLength:(_bufferLimit - _bufferOffset)];
                
                assert(bytesWritten);
                
                if (bytesWritten == -1)
                    [self stopSendWithStatus:@"Network write error"
                                        code:1];
                
                else
                {
                    _bufferOffset += bytesWritten;
                    totBytesWritten += bytesWritten;
                    CGFloat pct = ((double)totBytesWritten / (double)fileSize);
                    [_progressBarRef setProgress:pct];
                }
            }
            
            break;
            
        case NSStreamEventErrorOccurred:
            [self stopSendWithStatus:aStream.streamError.localizedDescription
                                code:aStream.streamError.code];
            break;
            
        case NSStreamEventEndEncountered:
            [self stopSendWithStatus:@"Event end"
                                code:200];
            
            break;
            
        default:
            assert(NO);
            break;
    }
}

- (IBAction)cancelAction:(id)sender
{
#pragma unused(sender)
    [self stopSendWithStatus:@"Cancelled"
                        code:1];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)goBack:(id)sender
{
    [self stopSendWithStatus:@"Cancelled"
                        code:1];
    
    [self.delegate uploadViewController:self
                                    return:YES];
}

@end