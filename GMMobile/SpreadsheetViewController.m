//  SpreadsheetViewController.m
//  GMMobile

#import "SpreadsheetViewController.h"
#import "CCodeLibrary/SpreadsheetView.h"

@interface SpreadsheetViewController ()

@property (nonatomic) SpreadsheetView *spreadsheetView;

@end

@implementation SpreadsheetViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGFloat statusBarHeight = [self statusBarHeight:self.interfaceOrientation];
    CGFloat tabBarHeight = self.tabBarController.tabBar.frame.size.height;
    
    CGRect ssFrame = CGRectMake(0.0, statusBarHeight, self.view.frame.size.width,
                                self.view.frame.size.height - statusBarHeight - tabBarHeight);
    
    _spreadsheetView = [SpreadsheetView spreadsheetViewWithRows:40
                                                        columns:12
                                                           view:self.view
                                                          frame:ssFrame
                                                   returnHidden:YES];
    
    [self.view addSubview:_spreadsheetView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    PropertyList *proplist = [[PropertyList alloc] init];
    proplist.delegate = self;
    NSArray *props = [proplist getPropertyNumbers];
    NSArray *fields = [proplist availablePropertyFields];
    
    NSMutableArray *fieldNames = [[NSMutableArray alloc] init];
    
    for (NSNumber *field in fields)
    {
        NSInteger ifield = field.integerValue;
        NSString *fieldName = [proplist propertyFieldName:ifield];
        [fieldNames addObject:fieldName];
    }
    
    [_spreadsheetView setTextArray:fieldNames
                  forColumnAtIndex:0];
    
    for (NSNumber *pnum in props)
    {
        NSInteger iprop = pnum.integerValue;
        
        [proplist getPropertyFieldValueOfType:PFT_ID
                            forPropertyNumber:iprop];
    }
}

- (void)PropertyList:(PropertyList *)propList
        returnsValue:(NSString *)value
   forPropertyNumber:(NSInteger)propNum
        andFieldType:(PropFieldType)type
          withStatus:(long)status;
{
    [_spreadsheetView setText:value
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
    if (_spreadsheetView)
    {
        [_spreadsheetView willRotateWithDuration:duration
                                    tabBarHeight:self.tabBarController.tabBar.frame.size.height];
    }
}

@end