//  SettingOptionsViewController.m
//  GMMobile

#import "SettingOptionsViewController.h"
#import "ConfigurationControl.h"
#import "CCodeLibrary/NVCalibrationController.h"
#import "CCodeLibrary/GSSiPopoverView.h"
#import "CCodeLibrary/NSData+Compression.h"
#import <CommonCrypto/CommonDigest.h>
#import "CCodeLibrary/UserDefaults.h"
#import "AppDelegate.h"
@import MediaPlayer;

@interface SettingOptionsViewController () <UIDocumentPickerDelegate>

@property (nonatomic) NSArray *contents, *images;
@property (nonatomic) NVContactPicker *nvcp;
@property (nonatomic) FTPDataPush *push;
@property (nonatomic) NSArray *products;
@property (nonatomic) NSString *iapFilePath;
@property (nonatomic) MPMoviePlayerController *mpController;

@end

@implementation SettingOptionsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UserDefaults.defaults.appleGray;
    
    UIImage *autoUpload = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"autoUpload"
                                                                                         ofType:@"png"]];
    
    UIImage *loadData = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"loadData"
                                                                                       ofType:@"png"]];
    
    UIImage *upload = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"upload"
                                                                                     ofType:@"png"]];
    
    UIImage *update = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"update"
                                                                                     ofType:@"png"]];
    
    UIImage *calibrate = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"calibrate"
                                                                                        ofType:@"png"]];
    
    UIImage *shopping = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"shoppingCart"
                                                                                       ofType:@"png"]];
    
    _images = [NSArray arrayWithObjects:autoUpload, upload, loadData, update, calibrate, shopping, nil];
    
    _tableView.layer.cornerRadius = 10.0;
    _tableView.rowHeight = 72.0;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.bounces = NO;
    _tableView.delaysContentTouches = NO;
    
    _versionLabel.text = [NSString stringWithFormat:@"GMMobile Version %@", UIApplication.appVersionBuild];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _contents = @[@"Auto Upload", @"Upload Now", @"Load Data", @"Update Data", @"Calibrate Device",
                  @"Make In-App Purchase", @"Access Contacts", @"Track User Location", @"Select Organization",
                  @"Access Documents" /*, @"Test Compression & Upload"*/];
    
    if (ConfigurationControl.sharedInstance.currentApp == HCConfigMetroProp)
    {
        NSMutableArray *tempArray = _contents.mutableCopy;
        [tempArray addObject:@"Clear Prop List & Destinations"];
        _contents = tempArray.copy;
    }
    
    [_tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return _contents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"
                                                            forIndexPath:indexPath];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:@"Cell"];
    }
    
    cell.textLabel.font = [UIFont boldSystemFontOfSize:32.0];
    cell.textLabel.textColor = UIColor.blackColor;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.text = _contents[indexPath.row];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    if (indexPath.row < _images.count)
        cell.imageView.image = _images[indexPath.row];
    
    else
        cell.imageView.image = nil;
    
    cell.textLabel.highlightedTextColor = UserDefaults.defaults.appleBlue;
    cell.indentationWidth = 10.0;
    
    for (UIView *views in cell.contentView.subviews)
    {
        if (views.tag == 777 || views.tag == 888)
            [views removeFromSuperview];
    }
    
    BOOL containsSwitch = NO;
    
    if ([cell.textLabel.text isEqualToString:@"Auto Upload"] ||
        [cell.textLabel.text isEqualToString:@"Track User Location"])
    {
        for (UISwitch *switches in cell.contentView.subviews)
        {
            if ([switches isKindOfClass:UISwitch.class])
                containsSwitch = YES;
        }
        
        if (!containsSwitch)
        {
            UISwitch *cellSwitch = [[UISwitch alloc] init];
            cellSwitch.tintColor = UIColor.redColor;
            cellSwitch.onTintColor = UIColor.greenColor;
            
            if ([cell.textLabel.text isEqualToString:@"Auto Upload"])
                cellSwitch.tag = 777;
            
            else
            {
                cellSwitch.tag = 888;
                cellSwitch.on = [UserDefaults.defaults boolForKey:@"TrackLocation"];
            }
            
            cellSwitch.center = CGPointMake((cell.frame.size.width - 100.0),
                                            (cell.frame.size.height / 2.0));
            
            [cellSwitch addTarget:self
                           action:@selector(cellSwitchValueChanged:)
                 forControlEvents:UIControlEventValueChanged];
            
            [cell.contentView addSubview:cellSwitch];
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    else
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
    
    if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
         isEqualToString:@"Upload Now"])
    {
        [self uploadNow];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Load Data"])
    {
        [self loadData];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Calibrate Device"])
    {
        [self calibrateDevice];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Clear Prop List & Destinations"])
    {
        CRAPI.sharedInstance.resetPropList = YES;
        CRAPI.sharedInstance.resetDestinations = YES;
        CRAPI.sharedInstance.clearSpreadsheet = YES;
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Make In-App Purchase"])
    {
        NSSet *prodID = [NSSet setWithObjects:@"com.gssi.gmmobile_TestVideo", nil];
        
        SKProductsRequest *skpr = [[SKProductsRequest alloc] initWithProductIdentifiers:prodID];
        skpr.delegate = self;
        [skpr start];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Access Contacts"])
    {
        _nvcp = [NVContactPicker presentContactPickerInDelegate:self];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Access Documents"])
    {
        UIDocumentPickerViewController *documentPicker =
        [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.content", @"public.composite-content", @"public.data"]
                                                               inMode:UIDocumentPickerModeImport];
        
        documentPicker.delegate = self;
        documentPicker.modalPresentationStyle = UIModalPresentationFormSheet;
        
        [self presentViewController:documentPicker
                           animated:NO
                         completion:nil];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Select Organization"])
    {
        [self performSegueWithIdentifier:@"SelectOrganization"
                                  sender:self];
    }
    
    /*else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Test Compression & Upload"])
    {
        NSString *filePath = [NSString stringWithFormat:@"%@/Sewer.sqlite",
                              UserDefaults.defaults.sharedFilePath];
        
        NSData *rawFile = [NSData dataWithContentsOfFile:filePath];
        NSString *md5 = rawFile.MD5;
        NSString *sha256 = rawFile.SHA256;
        NSLog(@"MD5:%@", md5);
        NSLog(@"SHA256:%@", sha256);
        
        NSData *compressedData = [NSData compressFileAtPath:filePath];
        compressedData = [NSData lzCompressFileAtPath:filePath];
        
        _push = FTPDataPush.push;
        _push.delegate = self;
        
        GSSiPopoverView *popover = [[GSSiPopoverView alloc] initWithView:self.view];
        _push.popover = popover;
        
        [_push.popover showAfter:0.0
                       withTitle:@"Upload Property.sqlite"];
        
        if (![_push sendFile:@"Sewer.sqlite"
               fromDirectory:UserDefaults.defaults.sharedFilePath
                      toFile:@"Sewer.sqlite"
                 toDirectory:@"GMMobileUploads"
              deleteWhenDone:NO])
        {
            [_push.popover hide];
            
            NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                              delegate:self
                                                                 title:@"Upload Failed"
                                                       buttonTextArray:@[@"OK"]
                                                      destructiveIndex:NVLargeAlertIndexNone];
#pragma unused(alert)
        }
    }*/
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller
  didPickDocumentAtURL:(NSURL *)url
{
    if (controller.documentPickerMode == UIDocumentPickerModeImport)
    {
        NSString *alertMessage = [NSString stringWithFormat:@"Successfully imported %@", url.lastPathComponent];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view delegate:self
                                                                 title:alertMessage
                                                       buttonTextArray:@[@"OK"]
                                                      destructiveIndex:0];
#pragma unused(alert)
        });
    }
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller
{
    
}

- (void)productsRequest:(SKProductsRequest *)request
     didReceiveResponse:(SKProductsResponse *)response
{
    _products = response.products;
    
    NSMutableArray *prodNames = NSMutableArray.array;
    
    for (SKProduct *prods in _products)
    {
        [prodNames addObject:[NSString stringWithFormat:@"%@\n$%@",
                              prods.localizedDescription, prods.price]];
    }
    
    [prodNames addObject:@"Cancel"];
    
    for (NSString *IDs in response.invalidProductIdentifiers)
        NSLog(@"INVALID PRODUCT:%@", IDs);
    
    if (_products.count)
    {
        NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                          delegate:self
                                                             title:@"Available In-App Purchases"
                                                   buttonTextArray:prodNames
                                                  destructiveIndex:0];

        alert.tag = 12345;
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue
 updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
    for (SKPaymentTransaction *trans in transactions)
    {
        if (trans.transactionState == SKPaymentTransactionStatePurchased)
        {
            [SKPaymentQueue.defaultQueue startDownloads:trans.downloads];
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue
    updatedDownloads:(NSArray<SKDownload *> *)downloads
{
    for (SKDownload *dload in downloads)
    {
        if (dload.progress == 1.0)
        {
            NSString *cachesPath = dload.contentURL.relativePath;
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = paths.firstObject;
            NSError *error;
            
            NSString *contentsPath = [NSString stringWithFormat:@"%@/Contents", cachesPath];
            
            NSArray *dirContents = [NSFileManager.defaultManager contentsOfDirectoryAtPath:contentsPath
                                                                                     error:&error];
            
            if (error)
                NSLog(@"DIR CONTENTS ERROR:%@", error.localizedDescription);
            
            for (NSString *fileName in dirContents)
            {
                if ([fileName containsString:@".mp4"])
                {
                    _iapFilePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, fileName];
                    NSString *oldFilePath = [NSString stringWithFormat:@"%@/%@", contentsPath, fileName];
                    
                    if ([NSFileManager.defaultManager moveItemAtPath:oldFilePath
                                                              toPath:_iapFilePath
                                                               error:&error])
                    {
                        NSLog(@"IAP FilePath:%@", _iapFilePath.description);
                    }
                    
                    else
                        NSLog(@"FILE MOVE ERROR (%@):%@", fileName, error.localizedDescription);
                }
            }
            
            [queue finishTransaction:dload.transaction];
            [self playPromoVideo];
        }
    }
}

- (void)playPromoVideo
{
    _mpController = [[MPMoviePlayerController alloc] initWithContentURL:
                     [NSURL fileURLWithPath:_iapFilePath]];
    
    _mpController.controlStyle = MPMovieControlStyleFullscreen;
    [_mpController prepareToPlay];
    
    UIWindow *backgroundWindow = UIApplication.sharedApplication.keyWindow;
    _mpController.view.frame = backgroundWindow.frame;
    [backgroundWindow addSubview:_mpController.view];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(promoVideoFinished:)
                                               name:MPMoviePlayerPlaybackDidFinishNotification
                                             object:_mpController];
    
    [_mpController play];
}

- (void)promoVideoFinished:(NSNotification *)notification
{
    [_mpController.view removeFromSuperview];
    
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:MPMoviePlayerPlaybackDidFinishNotification
                                                object:_mpController];
    
    _mpController = nil;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    UIWindow *backgroundWindow = UIApplication.sharedApplication.keyWindow;
    
    if ([backgroundWindow.subviews containsObject:_mpController.view])
    {
        [UIView animateWithDuration:duration animations:^{
            _mpController.view.frame = CGRectMake(0.0, 0.0, backgroundWindow.frame.size.height,
                                                  backgroundWindow.frame.size.width);
        }];
    }
}

- (void)FTPdidComplete:(int)status
              filePath:(NSString *)path
{
    [_push.popover hide];
    NSLog(@"Upload complete!");
}

- (void)contactPicker:(NVContactPicker *)contactPicker
       didReturnEmail:(NSString *)email
       forContactName:(NSString *)contactName
{
    NSLog(@"Name:%@", contactName);
    NSLog(@"Email:%@", email);
    _nvcp = nil;
}

- (void)uploadNow
{
    [self performSegueWithIdentifier:@"UploadData"
                              sender:@"Auto"];
}

- (void)uploadViewController:(UploadViewController *)controller
                      return:(BOOL)code
{
    [controller dismissViewControllerAnimated:YES
                                   completion:nil];
}

- (void)loadData
{
    NVTextAlert *textAlert = [NVTextAlert showTextAlertinView:self.view
                                                     delegate:self
                                                        title:@"Password Required for Access to Load Data"];
    
    textAlert.keyboardType = UIKeyboardTypeNumberPad;
    textAlert.minimumCharacters = 0;
}

- (void)calibrateDevice
{
    NVCalibrationController *calibrationController = [[NVCalibrationController alloc] init];
    
    [self presentViewController:calibrationController
                       animated:YES
                     completion:nil];
}

- (void)textAlert:(NVTextAlert *)textAlert
    didReturnText:(NSString *)text
{
    [textAlert hideTextAlert:YES];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.timeStyle = NSDateFormatterNoStyle;
    dateFormatter.dateStyle = NSDateFormatterShortStyle;
    [dateFormatter setDateFormat:@"MMdd"];
    
    NSString *dateString = [dateFormatter stringFromDate:NSDate.date];
    dateString = reverseString(dateString);
    
    if ([dateString isEqualToString:text])
    {
        [self performSegueWithIdentifier:@"ShowSettings"
                                  sender:self];
    }
    
    else
    {
        NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                          delegate:self
                                                             title:@"Password Not Correct"
                                                   buttonTextArray:@[@"OK", @"Try Again"]
                                                  destructiveIndex:0];
#pragma unused(alert)
    }
}

- (void)alertView:(NVAlertView *)alertView
didTapButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 12345)
    {
        if (buttonIndex < _products.count)
        {
            SKProduct *product = _products[buttonIndex];
            
            SKPayment *payment = [SKPayment paymentWithProduct:product];
            SKPaymentQueue *payQueue = SKPaymentQueue.defaultQueue;
            
            [payQueue addTransactionObserver:self];
            [payQueue addPayment:payment];
        }
    }
    
    else
    {
        if (buttonIndex == 1)
        {
            NVTextAlert *textAlert = [NVTextAlert showTextAlertinView:self.view
                                                             delegate:self
                                                                title:@"Password Required for Access to Load Data"];
            
            textAlert.keyboardType = UIKeyboardTypeNumberPad;
            textAlert.minimumCharacters = 0;
        }
    }
    
    [alertView hideLargeAlertView:YES];
}

- (void)cellSwitchValueChanged:(UISwitch *)aSwitch
{
    switch (aSwitch.tag)
    {
        case 777://Auto upload
            NSLog(@"Auto Upload Status:%d", aSwitch.on);
            break;
            
        case 888://Track location
        {
            if (aSwitch.on)
                [AppDelegate.sharedAppDelegate scheduleLocationTracking];
            
            else
                [AppDelegate.sharedAppDelegate stopLocationTracking];
            
            [UserDefaults.defaults saveBool:aSwitch.on
                                     forKey:@"TrackLocation"];
        }
            break;
            
        default:
            break;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"UploadData"])
    {
        UploadViewController *uploadViewController = segue.destinationViewController;
        uploadViewController.delegate = self;
    }
}

@end