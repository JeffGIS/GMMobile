//  UploadDirectory.h
//  NVMobile

#import <UIKit/UIKit.h>
#import "CCodeLibrary/FTPDirectoryCreate.h"
#import "CCodeLibrary/FTPDataPush.h"
#import "CCodeLibrary/GSSiPopoverView.h"

@interface UploadDirectory : UIViewController<GSSiPopoverViewDelegate,FTPDirectoryCreateDelegate,FTPDataPushDelegate>
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *returnButton;
@property (weak, nonatomic) IBOutlet UIButton *restartButton;
@property (weak, nonatomic) IBOutlet UIButton *skipAndRestartButton;
@property FTPDirectoryCreate * ftpcd;
@property NSString * dirToUpload;
@property NSString *fromDir;
@property NSString * fileListFile;
@property NSString * lastFileFile;
@property NSInteger nFiles;
@property NSInteger totSize;
@property NSTimer * timer;
@property NSInteger currentFile;
@property NSInteger nextFile;
@property GSSiPopoverView * popover;
@property FTPDataPush *push;
- (IBAction)startTransfer:(id)sender;
- (IBAction)return:(id)sender;
- (IBAction)restart:(id)sender;
- (IBAction)skipAndRestart:(id)sender;

@end
