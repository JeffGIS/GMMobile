//  SelectOrganizationVC.m
//  GMMobile

#import "SelectOrganizationVC.h"
#import "CCodeLibrary/UserDefaults.h"
#import "CCodeLibrary/CRAPI.h"
#import "CCodeLibrary/GeoMasterServer.h"
#import "CCodeLibrary/NVAlertView.h"
@import CoreLocation;

@interface SelectOrganizationVC () <UIPickerViewDataSource,UIPickerViewDelegate,GeoMasterServerDelegate,GSSiPopoverViewDelegate,CLLocationManagerDelegate,NVAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *returnButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (weak, nonatomic) IBOutlet UIButton *connectManagerButton;
@property (nonatomic) GeoMasterServer *GMServer;
@property (nonatomic) GSSiPopoverView *popoverView;
@property (nonatomic, copy) NSString *iPad_name;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) CLLocation *currentLocation;
@property (nonatomic) NSTimer *timer;

@end

@implementation SelectOrganizationVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UserDefaults.defaults.appleGray;
    _returnButton.backgroundColor = UIColor.whiteColor;
    _returnButton.layer.cornerRadius = 10.0;
    _connectManagerButton.backgroundColor = UIColor.whiteColor;
    _connectManagerButton.layer.cornerRadius = 10.0;
    _connectManagerButton.hidden = YES;
    _pickerView.backgroundColor = UIColor.whiteColor;
    _pickerView.layer.cornerRadius = 10.0;
    _pickerView.delegate = self;
    _pickerView.dataSource = self;
    
    _popoverView = [[GSSiPopoverView alloc] initWithView:self.view];
    _popoverView.delegate = self;
    _iPad_name = UIDevice.currentDevice.name;
    
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    [_locationManager requestLocation];
    
    _GMServer = GeoMasterServer.open;
    _GMServer.delegate = self;
    _GMServer.messageID = GMSMessageOpenConnect;
    [_GMServer initCommunication:5.0];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    _currentLocation = (CLLocation *)locations.lastObject;
    
    NSLog(@"%@", _currentLocation);
    
    [self performSelector:@selector(okayToConnectToManager)
               withObject:nil
               afterDelay:0.5];
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    NSLog(@"locationManager ERROR:%@", error.localizedDescription);
}

- (void)okayToConnectToManager
{
    _connectManagerButton.hidden = NO;
}

- (void)closeGMServer
{
    if (_GMServer)
    {
        [_GMServer closeServer];
        _GMServer.delegate = nil;
    }
    
    _GMServer = nil;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView
rowHeightForComponent:(NSInteger)component
{
    return 80.0;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (UIView *)pickerView:(UIPickerView *)pickerView
            viewForRow:(NSInteger)row
          forComponent:(NSInteger)component
           reusingView:(UIView *)view
{
    UILabel *pView = (UILabel *)view;
    
    if (!pView)
    {
        pView = [[UILabel alloc] init];
        pView.font = [UIFont boldSystemFontOfSize:72.0];
        pView.textColor = UIColor.blackColor;
        pView.textAlignment = NSTextAlignmentCenter;
    }
    
    NSString *pickerText = textInsideParentheses(CRAPI.sharedInstance.placesArray[row]);
    pView.text = addSpaceAfterComma(pickerText);
    return pView;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{
    return CRAPI.sharedInstance.placesArray.count;
}

- (void)GMServerDidOpen:(GeoMasterServer *)server
{
    NSString *msg = @"";
    
    switch (server.messageID)
    {
        case GMSMessageOpenConnect:
            msg = [NSString stringWithFormat:@"$MACRO([%%DL]macros\\GetCitiesForiPad.txt,%@,%@)\r\n",
                   vendorUUIDString(), _iPad_name];
            break;
            
        case GMSMessageSetNearby:
            msg = [NSString stringWithFormat:@"$MACRO([%%DL]macros\\SetNearbyiPad.txt,%@,%@,%f %f)\r\n",
                   vendorUUIDString(), _iPad_name, _currentLocation.coordinate.latitude, _currentLocation.coordinate.longitude];
            break;
            
        case GMSMessageCheckNearby:
            msg = [NSString stringWithFormat:@"$MACRO([%%DL]macros\\CheckNearbyiPad.txt,%@)\r\n",
                   vendorUUIDString()];
            break;
            
        case GMSMessageCancelConnect:
            msg = [NSString stringWithFormat:@"$MACRO([%%DL]macros\\RemoveNearbyiPad.txt,%@)\r\n",
                   vendorUUIDString()];
            break;
    }
    
    if (msg)
        [_GMServer sendMessage:msg];
    
    NSLog(@"GMServer Query: %@", msg);
}

- (void)GMServer:(GeoMasterServer *)server
didReceiveMessage:(NSString *)message
      withStatus:(long)status
{
    [self closeGMServer];
    NSLog(@"GMServer Message(SelectOrganizationVC): %@", message);
    
    if (status == GMServerStatusOK)
    {
        switch (server.messageID)
        {
            case GMSMessageOpenConnect:
            {
                NSMutableArray *tempArray = [[NSMutableArray alloc] initWithArray:[message componentsSeparatedByString:@":"]];
                [tempArray removeObjectAtIndex:0];
                
                if (tempArray.count == 0)
                    [tempArray addObject:@"No Cities in List"];
                
                CRAPI.sharedInstance.placesArray = tempArray;
                NSUInteger row = [UserDefaults.defaults integerForKey:@"SelectedRow"];
                
                if (CRAPI.sharedInstance.placesArray.count <= 1 || CRAPI.sharedInstance.placesArray.count <= row ||CRAPI.sharedInstance.currentGeoid == 0)
                {
                    row = 0;
                    [UserDefaults.defaults saveInteger:(int)row
                                                forKey:@"SelectedRow"];
                }
                
                NSString *locationLabelText = textInsideParentheses(CRAPI.sharedInstance.placesArray[row]);
                CRAPI.sharedInstance.currentCityNameAndState = addSpaceAfterComma(locationLabelText);
                NSString *geoid = textBeforeParentheses(CRAPI.sharedInstance.placesArray[row]);
                CRAPI.sharedInstance.currentGeoid = geoid.intValue;
                int manager = 0;
                NSString *placeAndManager = CRAPI.sharedInstance.placesArray[row];
                
                char *pPar = strrchr(placeAndManager.UTF8String, ')');
                
                if (pPar)
                    manager = atoi(++pPar);
                
                CRAPI.sharedInstance.currentManageriPad = manager;
            }
                
                break;
                
            case GMSMessageSetNearby:
                _timer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                          target:self
                                                        selector:@selector(checkNearby:)
                                                        userInfo:nil
                                                         repeats:NO];
                break;
                
            case GMSMessageCheckNearby:
                if ([message isEqualToString:@"YES"])
                {
                    _timer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                              target:self
                                                            selector:@selector(checkNearby:)
                                                            userInfo:nil
                                                             repeats:NO];
                }
                
                else
                    [_popoverView hide];
                
                break;
                
            case GMSMessageCancelConnect:
                [_popoverView hide];
                break;
        }
    }
    
    [_pickerView reloadAllComponents];
    
    [_pickerView selectRow:[UserDefaults.defaults integerForKey:@"SelectedRow"]
               inComponent:0
                  animated:YES];
    
    if (CRAPI.sharedInstance.placesArray.count == 1)
        _pickerView.userInteractionEnabled = NO;
    
    else
        _pickerView.userInteractionEnabled = YES;
}


- (void)GMServer:(GeoMasterServer *)server
 didReceiveError:(NSString *)error
      withStatus:(long)status
{
    [self closeGMServer];
    
    NSString *titleMessage = @"";
    
    if ([error isEqualToString:@"Internet Connection Not Available"])
        titleMessage = @"Network Error";
    
    else
        titleMessage = @"NVServer Error";
    
    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                      delegate:self
                                                         title:titleMessage
                                               buttonTextArray:@[@"OK"]
                                              destructiveIndex:0];
#pragma unused(alert)
}

- (void)alertView:(NVAlertView *)alertView
didTapButtonAtIndex:(NSInteger)buttonIndex
{
    [alertView hideLargeAlertView:YES];
}

- (IBAction)returnBack:(id)sender
{
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

- (IBAction)connectManager:(id)sender
{
    _GMServer = GeoMasterServer.open;
    _GMServer.delegate = self;
    _GMServer.messageID = GMSMessageSetNearby;
    [_GMServer initCommunication:5.0];
    
    _popoverView.progressView.hidden = YES;
    
    [_popoverView showAfter:0.0
                  withTitle:@"Waiting\nto Connect\nto Manager"];
}

- (void)checkNearby:(NSTimer *)timer
{
    [self.timer invalidate];
    _GMServer = [GeoMasterServer open];
    _GMServer.delegate = self;
    _GMServer.messageID = GMSMessageCheckNearby;
    [_GMServer initCommunication:5.0];
}

- (void)GSSiPopoverViewdidCancel:(GSSiPopoverView *)popoverView
{
    [self.timer invalidate];
    [self closeGMServer];
    _GMServer = [GeoMasterServer open];
    _GMServer.delegate = self;
    _GMServer.messageID = GMSMessageCancelConnect;
    [_GMServer initCommunication:5.0];
}

@end