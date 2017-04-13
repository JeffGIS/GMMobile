//  FindViewController.m
//  GMMobile

#import "FindViewController.h"
#import "PropertyData.h"
#import "MapViewController.h"
#import "CCodeLibrary/NVTabBarEdit.h"

@interface FindViewController ()

@end

@implementation FindViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    [self setupButton:_pidButton];
    [self setupButton:_addressButton];
    [self setupButton:_taxpayerButton];
    [self setupButton:_intersectionButton];
    [self setupButton:_boundariesButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setupButton:(UIButton *)button
{
    button.layer.cornerRadius = 10.0;
    button.layer.borderColor = UserDefaults.defaults.green.CGColor;
    button.layer.borderWidth = 4.0;
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ShowFindPID"])
    {
        FindPIDViewController *findPID = segue.destinationViewController;
        findPID.delegate = self;
    }
    
    else if ([segue.identifier isEqualToString:@"ShowFindAddress"])
    {
        FindAddressViewController *findAddress = segue.destinationViewController;
        findAddress.delegate = self;
    }
    
    else if ([segue.identifier isEqualToString:@"ShowFindIntersection"])
    {
        FindAddressViewController *findInt = segue.destinationViewController;
        findInt.delegate = self;
    }
}

- (IBAction)showPropertyOwner:(id)sender
{
    FindPropertyOwnerViewController *findPropOwner = FindPropertyOwnerViewController.new;
    findPropOwner.delegate = self;
    
    [self presentViewController:findPropOwner
                       animated:YES
                     completion:nil];
}
- (IBAction)showBoundaries:(id)sender
{
    FindBoundariesViewController *findBounds = FindBoundariesViewController.new;
    findBounds.delegate = self;
    
    [self presentViewController:findBounds
                       animated:YES
                     completion:nil];
}

- (void)findPIDViewController:(FindPIDViewController *)findPID
                 didSelectPID:(NSString *)PID
{
    PropertyData *propData = [[PropertyData alloc] init];
    
    CRAPI.sharedInstance.selectBoundaryFromMapType = nil;
    CRAPI.sharedInstance.GMMSetting = GMMSettingPID;
    CRAPI.sharedInstance.currentPID = PID;
    CRAPI.sharedInstance.currentPropOwner = [propData getOwnerNameForPID:PID];
    self.tabBarController.selectedIndex = 0;
    [findPID dismissViewControllerAnimated:YES completion:nil];
}

- (void)findAddressViewController:(FindAddressViewController *)findAddress
                 didSelectAddress:(NSString *)address
                              PID:(NSString *)PID
{
    CRAPI.sharedInstance.selectBoundaryFromMapType = nil;
    CRAPI.sharedInstance.GMMSetting = GMMSettingAddress;
    CRAPI.sharedInstance.currentPID = PID;
    CRAPI.sharedInstance.currentAddress = address;
    self.tabBarController.selectedIndex = 0;
    [findAddress dismissViewControllerAnimated:YES completion:nil];
}

- (void)findIntersectionViewController:(FindIntersectionViewController *)findIntersection
                 didSelectIntersection:(NSString *)intersection
{
    [findIntersection dismissViewControllerAnimated:YES
                                         completion:nil];
}

- (void)findPropOwnerViewController:(FindPropertyOwnerViewController *)findPropOwner
                 didSelectPropOwner:(NSString *)propOwner
                                PID:(NSString *)PID
{
    CRAPI.sharedInstance.selectBoundaryFromMapType = nil;
    CRAPI.sharedInstance.GMMSetting = GMMSettingPropOwner;
    CRAPI.sharedInstance.currentPID = PID;
    CRAPI.sharedInstance.currentPropOwner = propOwner;
    self.tabBarController.selectedIndex = 0;
    [findPropOwner dismissViewControllerAnimated:YES completion:nil];
}

- (void)findBoundsViewController:(FindBoundariesViewController *)findBounds
                 didSelectBounds:(NSString *)bounds
                            type:(NSString *)type
                           refno:(int)refno
{
    //CRAPI.sharedInstance.selectBoundaryFromMapType = nil;
    CRAPI.sharedInstance.GMMSetting = GMMSettingBoundaries;
    CRAPI.sharedInstance.currentOverallBoundaryName = bounds;
    CRAPI.sharedInstance.currentOverallBoundaryType = type;
    CRAPI.sharedInstance.currentOverallBoundaryRefno = refno;
    self.tabBarController.selectedIndex = 0;
    [findBounds dismissViewControllerAnimated:YES completion:nil];
}

- (void)findPropOwnerViewController:(FindPropertyOwnerViewController *)findPropOwner
             didSelectMultipleProps:(NSArray<PropertyRecord *> *)multipleProps
{
    MapViewController *mapVC = (MapViewController *)[NVTabBarEdit viewControllerWithID:@"MapVC"
                                                                    inTabBarController:self.tabBarController];
    
    if (mapVC)
        mapVC.propArray = multipleProps;
    
    CRAPI.sharedInstance.selectBoundaryFromMapType = nil;
    CRAPI.sharedInstance.GMMSetting = GMMSettingMultipleProps;
    self.tabBarController.selectedIndex = 0;
    [findPropOwner dismissViewControllerAnimated:YES completion:nil];
}

- (void)findBoundsViewController:(FindBoundariesViewController *)findBounds
          didSelectMultipleProps:(NSArray<PropertyRecord *> *)multipleProps
{
    MapViewController *mapVC = (MapViewController *)[NVTabBarEdit viewControllerWithID:@"MapVC"
                                                                    inTabBarController:self.tabBarController];
    
    if (mapVC)
        mapVC.propArray = multipleProps;
    
    CRAPI.sharedInstance.selectBoundaryFromMapType = nil;
    CRAPI.sharedInstance.GMMSetting = GMMSettingMultipleProps;
    self.tabBarController.selectedIndex = 0;
    [findBounds dismissViewControllerAnimated:YES completion:nil];
}

@end
