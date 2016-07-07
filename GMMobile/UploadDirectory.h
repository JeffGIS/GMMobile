//
//  UploadDirectory.h
//  NVMobile
//
//  Created by Jeff Smith on 7/6/16.
//  Copyright © 2016 GSSi. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "CCodeLibrary/CCodeLibrary.h"
#import "CCodeLibrary/FTPDirectoryCreate.h"
#import "CCodeLibrary/FTPDataPush.h"
#import "CCodeLibrary/GSSiPopoverView.h"

@interface UploadDirectory : UIViewController<GSSiPopoverViewDelegate,FTPDirectoryCreateDelegate,FTPDataPushDelegate>
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *returnButton;
@property FTPDirectoryCreate * ftpcd;
@property NSString * dirToUpload;
@property NSString *fromDir;
@property NSString * fileListFile;
@property NSInteger nFiles;
@property NSInteger totSize;
@property NSTimer * timer;
@property NSInteger currentFile;
@property GSSiPopoverView * popover;
@property BOOL keepGoing;
@property FTPDataPush *push;
- (IBAction)startTransfer:(id)sender;
- (IBAction)return:(id)sender;

@end
