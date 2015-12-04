//  CurbRampDataOptions.m
//  GMMobile

#import "CurbRampDataOptions.h"
#import "CCodeLibrary/UserDefaults.h"

@interface CurbRampDataOptions ()

@property (weak, nonatomic) IBOutlet UITableView *intersectionsTV;
@property (weak, nonatomic) IBOutlet UITableView *rampTypeTV;

@property (nonatomic) CGFloat rowHeight, headerHeight, cornerRadius;
@property (nonatomic) UIFont *font, *headerFont;

@end

@implementation CurbRampDataOptions

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        _rowHeight = 36.0;
        _headerHeight = 24.0;
        _cornerRadius = 4.0;
        
        _font = [UIFont fontWithName:@"CourierNewPS-BoldMT"
                                size:14.0];
        
        _headerFont = [UIFont boldSystemFontOfSize:18.0];
    }
    
    else
    {
        _rowHeight = 52.0;
        _headerHeight = 40.0;
        _cornerRadius = 10.0;
        
        _font = [UIFont fontWithName:@"CourierNewPS-BoldMT"
                                size:24.0];
        
        _headerFont = [UIFont boldSystemFontOfSize:28.0];
    }
    
    [self setupTableView:_intersectionsTV];
    [self setupTableView:_rampTypeTV];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setupTableView:(UITableView *)tableView
{
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.backgroundColor = UIColor.whiteColor;
    tableView.bounces = NO;
    tableView.layer.borderColor = UIColor.blackColor.CGColor;
    tableView.layer.borderWidth = (_cornerRadius / 4.0);
    tableView.layer.cornerRadius = _cornerRadius;
    tableView.delaysContentTouches = NO;
    tableView.allowsMultipleSelection = YES;
    tableView.separatorColor = UIColor.clearColor;
    tableView.separatorInset = UIEdgeInsetsZero;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    //ThemeLegend *tl = (ThemeLegend *)_legends[tableView.tag - 1];
    //tableView.rowHeight = (CGFloat)((tableView.frame.size.height - _headerHeight) / tl.numCells);
    //return (NSInteger)tl.numCells;
    
    if (tableView == _intersectionsTV)
    {
        tableView.rowHeight = (CGFloat)((tableView.frame.size.height - _headerHeight) / 4);
        return 4;
    }
    
    else
    {
        tableView.rowHeight = (CGFloat)((tableView.frame.size.height - _headerHeight) / 9);
        return 9;
    }
}

- (CGFloat)tableView:(UITableView *)tableView
heightForHeaderInSection:(NSInteger)section
{
    return _headerHeight;
}

- (UIView *)tableView:(UITableView *)tableView
viewForHeaderInSection:(NSInteger)section
{
    //ThemeLegend *tl = (ThemeLegend *)_legends[0];
    
    CGFloat margin = 40.0;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        margin = 16.0;
        
        if (UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeLeft ||
            UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeRight)
        {
            margin = 12.0;
        }
    }
    
    CGFloat tvWidth = (self.view.frame.size.width - margin);
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, tvWidth, _headerHeight)];
    headerView.backgroundColor = UIColor.blackColor;
    headerView.contentMode = UIViewContentModeCenter;
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:headerView.frame];
    headerLabel.font = _headerFont;
    headerLabel.textColor = UIColor.whiteColor;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    //headerLabel.text = tl.title;
    
    if (tableView == _intersectionsTV)
        headerLabel.text = @"Intersection Types";
    
    else
        headerLabel.text = @"Ramp Types";
    
    [headerView addSubview:headerLabel];
    
    if (![headerView.subviews containsObject:[headerView viewWithTag:3333]])
    {
        UIButton *addToMap = [UIButton buttonWithType:UIButtonTypeCustom];
        addToMap.tag = 3333;
        addToMap.imageView.contentMode = UIViewContentModeScaleAspectFit;
        addToMap.imageEdgeInsets = UIEdgeInsetsMake(2.0, 2.0, 2.0, 2.0);
        //addToMap.selected = tl.drawOnMap;
        
        addToMap.frame = CGRectMake((headerView.frame.size.width - (headerView.frame.size.height * 2.0)), 0.0,
                                    (headerView.frame.size.height * 2.0), headerView.frame.size.height);
        
        [addToMap setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"greenPlusSign"
                                                                                          ofType:@"png"]]
                  forState:UIControlStateNormal];
        
        [addToMap setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"redMinusSign"
                                                                                          ofType:@"png"]]
                  forState:UIControlStateSelected];
        
        /*[addToMap addTarget:self
                     action:@selector(addLegend:)
           forControlEvents:UIControlEventTouchUpInside];*/
        
        [headerView addSubview:addToMap];
    }
    
    return headerView;
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
    
    
    
    cell.layer.borderColor = UIColor.blackColor.CGColor;
    cell.layer.borderWidth = 0.5;
    cell.textLabel.textColor = UIColor.blackColor;
    cell.textLabel.font = _font;
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    
    if (tableView == _intersectionsTV)
        cell.textLabel.text = [NSString stringWithFormat:@"IntersectionType%li", (indexPath.row + 1)];
    
    else
        cell.textLabel.text = [NSString stringWithFormat:@"RampType%li", (indexPath.row + 1)];
    
    return cell;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    [_intersectionsTV reloadData];
    [_rampTypeTV reloadData];
}

@end