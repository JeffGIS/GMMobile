//  UploadViewController.h
//  GMMobile

#import "CCodeLibrary/CCodeLibrary.h"

enum
{
    kSendBufferSize = 32768
};

@class UploadViewController;

@protocol UploadViewControllerDelegate <NSObject>

- (void)uploadViewController:(UploadViewController *)controller
                         return:(BOOL) code;

@end

@interface UploadViewController : UIViewController <NSStreamDelegate>
{
    NSOutputStream *_networkStream;
    NSInputStream *_fileStream;
    uint8_t _buffer[kSendBufferSize];
    size_t _bufferOffset;
    size_t _bufferLimit;
}

@property (nonatomic, weak) id <UploadViewControllerDelegate> delegate;
@property (nonatomic, strong) MPIntersection *currentIntersection;
@property NSTimer * timer;
@property BOOL uploadCancelled;
@property (weak, nonatomic) IBOutlet UIButton *helpButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (nonatomic, copy) NSString *urlText;
@property (nonatomic, copy) NSString *usernameText;
@property (nonatomic, copy) NSString *passwordText;
@property (weak, nonatomic) IBOutlet UILabel *fileListRef;
@property (nonatomic, copy) NSString *outputDirectory;
@property (nonatomic, copy) NSString *currentFile;
@property (weak, nonatomic) IBOutlet UILabel *numberToUploadRef;
@property (weak, nonatomic) IBOutlet UIButton *returnButton;

- (IBAction)listDirectory:(id)sender;
- (IBAction)cancelAction:(id)sender;
- (BOOL)startSend:(NSString *)filePath;

@end