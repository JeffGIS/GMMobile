//  SpreadsheetViewController.m
//  GMMobile

#import "SpreadsheetViewController.h"
#import "CCodeLibrary/NVTabBarEdit.h"
#import "MapViewController.h"

@interface SpreadsheetViewController ()

@property (nonatomic) NVSpreadsheetView *ssv;
@property NSUInteger selectedRow, selectedColumn;

@end

@implementation SpreadsheetViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.blackColor;
    _selectedRow = _selectedColumn = 0;
    
    CGFloat statusBarHeight = [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation];
    CGFloat tabBarHeight = self.tabBarController.tabBar.frame.size.height;
    
    CGRect ssFrame = CGRectMake(0.0, statusBarHeight, self.view.frame.size.width,
                                self.view.frame.size.height - statusBarHeight - tabBarHeight);
    
    _ssv = [NVSpreadsheetView showSpreadsheetWithRows:40
                                              columns:26
                                                 view:self.view
                                                frame:ssFrame
                                             editable:NO
                                           selectable:YES
                                             delegate:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (CRAPI.sharedInstance.clearSpreadsheet)
    {
        [_ssv clearContents];
        CRAPI.sharedInstance.clearSpreadsheet = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main"
                                                         bundle:NSBundle.mainBundle];
    
    UIViewController *fovc = [storyboard instantiateViewControllerWithIdentifier:@"FieldOptionsVC"];
    
    [NVTabBarEdit tabBarController:self.tabBarController
       replaceViewControllerWithID:@"FindVC"
                withViewController:fovc];
    
    UIViewController *dvc = [storyboard instantiateViewControllerWithIdentifier:@"DestinationsVC"];
    
    [NVTabBarEdit tabBarController:self.tabBarController
       replaceViewControllerWithID:@"ApplicationsVC"
                withViewController:dvc];
    
    PropertyList *proplist = [[PropertyList alloc] init];
    proplist.delegate = self;
    NSArray *props = [proplist getPropertyNumbers];
    NSArray *fields = [proplist availablePropertyFields];
    
    _ssv.activeColumns = props.count;
    _ssv.activeRows = fields.count;
    
    NSMutableArray *fieldNames = [[NSMutableArray alloc] init];
    
    for (NSNumber *field in fields)
    {
        NSInteger ifield = field.integerValue;
        NSString *fieldName = [proplist propertyFieldName:ifield];
        [fieldNames addObject:fieldName];
    }
    
    [_ssv setRowHeaderText:fieldNames];
    
    for (NSNumber *pnum in props)
    {
        NSInteger iprop = pnum.integerValue;
        
        for (NSNumber *field in fields)
        {
            [proplist getPropertyFieldValueOfType:field.integerValue
                                forPropertyNumber:iprop];
        }
    }
}

- (void)PropertyList:(PropertyList *)propList
        returnsValue:(NSString *)value
   forPropertyNumber:(NSInteger)propNum
        andFieldType:(PropFieldType)type
          withStatus:(long)status;
{
    [_ssv setText:value
     forCellAtRow:type
           column:propNum];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (CGFloat)statusBarHeight:(UIInterfaceOrientation)orientation
{
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        if (orientation == UIDeviceOrientationLandscapeLeft ||
            orientation == UIDeviceOrientationLandscapeRight)
        {
            return 0.0;
        }
    }
    
    return 20.0;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
duration:(NSTimeInterval)duration
{
    if (_ssv)
    {
        [_ssv willRotateWithDuration:duration
                        tabBarHeight:self.tabBarController.tabBar.frame.size.height];
    }
}

- (void)ssvDidEditText:(NSString *)text
          forCellAtRow:(NSUInteger)row
                column:(NSUInteger)column
{
    if (row == PFT_UserID)
    {
        PropertyList *proplist = [[PropertyList alloc] init];
        
        [proplist updatePropertyUserID:column
                                userID:text];
    }
}

- (void)ssvCellWasTappedAtRowIndex:(NSUInteger)rowIndex
                       columnIndex:(NSUInteger)columnIndex
{
    _selectedRow = rowIndex;
    _selectedColumn = columnIndex;
    
    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                      delegate:self
                                                         title:@"Spreadsheet Options"
                                               buttonTextArray:@[@"Map It!", @"Cancel"]
                                              destructiveIndex:0];
#pragma unused(alert)
}

- (void)alertView:(NVAlertView *)alertView
didTapButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        PropertyList *proplist = [[PropertyList alloc] init];
        LLPOINT llpoint = [proplist getPropertyLatLon:_selectedColumn];
        CLLocationCoordinate2D ssCoords = CLLocationCoordinate2DMake(llpoint.lat, llpoint.lon);
        NSUInteger index = 0;
        
        MapViewController *mapVC = (MapViewController *)[NVTabBarEdit viewControllerWithID:@"MapVC"
                                                                        inTabBarController:self.tabBarController
                                                                                     index:&index];
        
        if (mapVC)
        {
            mapVC.fromSpreadsheet = YES;
            mapVC.spreadsheetCoords = ssCoords;
        }
        
        self.tabBarController.selectedIndex = index;
    }
    
    [alertView hideLargeAlertView:YES];
}

@end