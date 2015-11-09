//  CrimeOptions1.m
//  GMMobile

#import "CrimeOptions1.h"
#import "CCodeLibrary/UserDefaults.h"
#import "ConfigurationControl.h"
#import "ThemeLegend.h"
#import "SymbolDictionary.h"

@interface CrimeOptions1 ()

@property (nonatomic) NSArray *legends;
@property (nonatomic) NSUInteger countLength;
@property (nonatomic) UIFont *font, *headerFont;
@property (nonatomic) CGFloat headerHeight, cornerRadius;
@property (nonatomic) UILabel *deptHeaderView;

@end

@implementation CrimeOptions1

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _legends = ConfigurationControl.sharedInstance.legendList;//.copy;
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    _countLength = 0;
 
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        _headerHeight = 24.0;
        _cornerRadius = 4.0;
        
        _font = [UIFont fontWithName:@"CourierNewPS-BoldMT"
                                size:14.0];
        
        _headerFont = [UIFont boldSystemFontOfSize:18.0];
    }
    
    else
    {
        _headerHeight = 40.0;
        _cornerRadius = 10.0;
        
        _font = [UIFont fontWithName:@"CourierNewPS-BoldMT"
                                size:24.0];
        
        _headerFont = [UIFont boldSystemFontOfSize:28.0];
    }
    
    [self setupTableView];
    [self setupDeptView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _legends = ConfigurationControl.sharedInstance.legendList;//.copy;
    
    ThemeLegend *tl = (ThemeLegend *)_legends[0];
    
    for (ThemeLegendCell *cells in tl.cells)
    {
        NSString *countString = [NSString stringWithFormat:@"%i", cells.count];
        _countLength = MAX(_countLength, countString.length);
    }
    
    [_tableView reloadData];
    [self.view layoutIfNeeded];
    [self setupDeptViewComponents:_deptView.frame.size.width];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setupDeptView
{
    ThemeLegend *tl = (ThemeLegend *)_legends[1];
    
    _deptView.backgroundColor = UIColor.whiteColor;
    _deptView.layer.cornerRadius = _cornerRadius;
    _deptView.layer.borderColor = UIColor.blackColor.CGColor;
    _deptView.layer.borderWidth =  (_cornerRadius / 4.0);
    _deptView.clipsToBounds = YES;
    
    _deptHeaderView = [[UILabel alloc] init];
    _deptHeaderView.backgroundColor = UIColor.blackColor;
    _deptHeaderView.text = tl.title;
    _deptHeaderView.font = _headerFont;
    _deptHeaderView.textColor = UIColor.whiteColor;
    _deptHeaderView.textAlignment = NSTextAlignmentCenter;
    
    [_deptView addSubview:_deptHeaderView];
    
    for (int i = 0; i < tl.cells.count; i++)
    {
        UIButton *deptButton = [UIButton buttonWithType:UIButtonTypeCustom];
        deptButton.layer.borderWidth = 0.5;
        deptButton.layer.borderColor = UIColor.blackColor.CGColor;
        deptButton.titleLabel.font = _font;
        deptButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        deptButton.tag = (i + 1);
        
        [deptButton setTitleColor:UIColor.blackColor
                         forState:UIControlStateNormal];
        
        [deptButton addTarget:self
                       action:@selector(deptButtonTapped:)
             forControlEvents:UIControlEventTouchUpInside];
        
        [_deptView addSubview:deptButton];
    }
}

- (void)deptButtonTapped:(UIButton *)button
{
    ThemeLegend *tl = (ThemeLegend *)_legends[1];
    ThemeLegendCell *tlc = (ThemeLegendCell *)tl.cells[button.tag - 1];
    
    if (button.selected)
    {
        button.backgroundColor = UIColor.clearColor;
        button.selected = tlc.status = NO;
    }
    
    else
    {
        button.backgroundColor = UserDefaults.defaults.appleGray;
        button.selected = tlc.status = YES;
    }
}

- (void)setupDeptViewComponents:(CGFloat)width
{
    _deptHeaderView.frame = CGRectMake(0.0, 0.0, width, _headerHeight);
    
    ThemeLegend *tl = (ThemeLegend *)_legends[1];
    CGFloat buttonWidth = (width / tl.cells.count);
    
    for (UIButton *buttons in _deptView.subviews)
    {
        if ([buttons isKindOfClass:UIButton.class])
        {
            buttons.frame = CGRectMake((buttonWidth * (buttons.tag - 1)), _headerHeight,
                                       buttonWidth,(_deptView.frame.size.height - _headerHeight));
            
            ThemeLegendCell *tlc = (ThemeLegendCell *)tl.cells[buttons.tag - 1];
            
            [buttons setTitle:[NSString stringWithFormat:@"%@ (%i)", tlc.label, tlc.count]
                     forState:UIControlStateNormal];
            
            buttons.selected = tlc.status;
            
            if (buttons.selected)
                buttons.backgroundColor = UserDefaults.defaults.appleGray;
            
            else
                buttons.backgroundColor = UIColor.clearColor;
        }
    }
}

- (void)setupTableView
{
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = UIColor.whiteColor;
    _tableView.bounces = NO;
    _tableView.layer.borderColor = UIColor.blackColor.CGColor;
    _tableView.layer.borderWidth = (_cornerRadius / 4.0);
    _tableView.layer.cornerRadius = _cornerRadius;
    _tableView.delaysContentTouches = NO;
    _tableView.allowsMultipleSelection = YES;
    _tableView.separatorColor = UIColor.clearColor;
    _tableView.separatorInset = UIEdgeInsetsZero;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    ThemeLegend *tl = (ThemeLegend *)_legends[0];
    tableView.rowHeight = (CGFloat)((tableView.frame.size.height - _headerHeight) / tl.numCells);
    return (NSInteger)tl.numCells;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForHeaderInSection:(NSInteger)section
{
    return _headerHeight;
}

- (UIView *)tableView:(UITableView *)tableView
viewForHeaderInSection:(NSInteger)section
{
    ThemeLegend *tl = (ThemeLegend *)_legends[0];
    
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
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:
                            CGRectMake(0.0, 0.0, headerView.frame.size.width,
                                       headerView.frame.size.height)];
    
    headerLabel.font = _headerFont;
    headerLabel.textColor = UIColor.whiteColor;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.text = tl.title;
    
    [headerView addSubview:headerLabel];
    
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
    
    ThemeLegend *tl = (ThemeLegend *)_legends[0];
    ThemeLegendCell *tlc = (ThemeLegendCell *)tl.cells[indexPath.row];
    
    NSMutableString *text = tlc.label.mutableCopy;
    
    if (tl.appendClassCount)
    {
        NSMutableString *countString = [NSString stringWithFormat:@"%i", tlc.count].mutableCopy;
        
        while (countString.length < _countLength)
        {
            [countString insertString:@" "
                              atIndex:0];
        }
        
        [text appendString:[NSString stringWithFormat:@" (%@)", countString.copy]];
    }
    
    cell.textLabel.textColor = UIColor.blackColor;
    cell.textLabel.font = _font;
    cell.textLabel.text = text.copy;
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    
    cell.layer.borderColor = UIColor.blackColor.CGColor;
    cell.layer.borderWidth = 0.5;
    
    CGFloat symbolSize = 52.0;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        symbolSize = 36.0;
    
    cell.imageView.image = imageFromSymbol(tlc.symbol, symbolSize, tl.symbolDefaultColor);
    
    return cell;
}

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    ThemeLegend *tl = (ThemeLegend *)_legends[0];
    ThemeLegendCell *tlc = (ThemeLegendCell *)tl.cells[indexPath.row];
    
    if (tlc.status)
    {
        [tableView selectRowAtIndexPath:indexPath
                               animated:NO
                         scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ThemeLegend *tl = (ThemeLegend *)_legends[0];
    ThemeLegendCell *tlc = (ThemeLegendCell *)tl.cells[indexPath.row];
    tlc.status = YES;
}

- (void)tableView:(UITableView *)tableView
didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ThemeLegend *tl = (ThemeLegend *)_legends[0];
    ThemeLegendCell *tlc = (ThemeLegendCell *)tl.cells[indexPath.row];
    tlc.status = NO;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    [_tableView reloadData];
    
    CGFloat tabBarHeight = self.tabBarController.tabBar.frame.size.height;
    CGFloat margin = 40.0;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        margin = 12.0;
    
    [UIView animateWithDuration:duration animations:^{
        [self setupDeptViewComponents:((self.view.frame.size.height + tabBarHeight) - margin)];
    }];
}

@end