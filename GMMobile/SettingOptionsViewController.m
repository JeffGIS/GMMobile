//  SettingOptionsViewController.m
//  GMMobile

#import "SettingOptionsViewController.h"
#import "ConfigurationControl.h"
#import "CCodeLibrary/NVCalibrationController.h"
#import "CCodeLibrary/GSSiPopoverView.h"
#import "CCodeLibrary/NSData+Compression.h"

@interface SettingOptionsViewController ()

@property (nonatomic) NSArray *contents, *images;
@property (nonatomic) NVContactPicker *nvcp;
@property (nonatomic) FTPDataPush *push;

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
                  @"Purchase Data", @"Access Contacts", @"Test Compression & Upload"];
    
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
    cell.textLabel.text = _contents[indexPath.row];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    if (indexPath.row < _images.count)
        cell.imageView.image = _images[indexPath.row];
    
    cell.textLabel.highlightedTextColor = UserDefaults.defaults.appleBlue;
    cell.indentationWidth = 10.0;
    
    BOOL containsSwitch = NO;
    
    if (indexPath.row == 0)
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
              isEqualToString:@"Purchase Data"])
    {
        [self purchaseData];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Clear Prop List & Destinations"])
    {
        CRAPI.sharedInstance.resetPropList = YES;
        CRAPI.sharedInstance.resetDestinations = YES;
        CRAPI.sharedInstance.clearSpreadsheet = YES;
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Access Contacts"])
    {
        _nvcp = [NVContactPicker presentContactPickerInDelegate:self];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Test Compression & Upload"])
    {
        NSString *filePath = [NSString stringWithFormat:@"%@/Sewer.sqlite",
                              UserDefaults.defaults.sharedFilePath];
        
        NSData *rawFile = [NSData dataWithContentsOfFile:filePath];
        NSString *md5 = rawFile.MD5;
        NSString *sha256 = rawFile.SHA256;
        NSLog(@"MD5:%@", md5);
        NSLog(@"SHA256:%@", sha256);
        
        //NSData *compressedData = [NSData compressFileAtPath:filePath];
        //compressedData = [NSData lzCompressFileAtPath:filePath];
        
        /*_push = FTPDataPush.push;
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
        }*/
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

- (void)purchaseData
{
    NSDictionary *parametersDict = @{SKStoreProductParameterITunesItemIdentifier:@(1033650392)};
    
    SKStoreProductViewController *spvc = [[SKStoreProductViewController alloc] init];
    spvc.delegate = self;
    
    [spvc loadProductWithParameters:parametersDict
                    completionBlock:^(BOOL result, NSError *error)
     {
         if (result)
         {
             [self presentViewController:spvc
                                animated:YES
                              completion:nil];
         }
         
         else
             NSLog(@"Error message: %@", error.localizedDescription);
     }];
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    
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
    [alertView hideLargeAlertView:YES];
    
    if (buttonIndex == 1)
    {
        NVTextAlert *textAlert = [NVTextAlert showTextAlertinView:self.view
                                                         delegate:self
                                                            title:@"Password Required for Access to Load Data"];
        
        textAlert.keyboardType = UIKeyboardTypeNumberPad;
        textAlert.minimumCharacters = 0;
    }
}

- (void)cellSwitchValueChanged:(UISwitch *)aSwitch
{
    NSLog(@"Auto Upload Status:%d", aSwitch.on);
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