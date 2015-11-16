//  CrimeOptions2.m
//  GMMobile

#import "CrimeOptions2.h"
#import "CCodeLibrary/UserDefaults.h"
#import "ConfigurationControl.h"
#import "ThemeLegend.h"
#import "CCodeLibrary/UIImage+ImageFromColor.h"

@interface CrimeOptions2 ()

@property (nonatomic) NSMutableArray *legends, *countLengths;
@property (nonatomic) UIFont *font, *headerFont;
@property (nonatomic) CGFloat headerHeight, cornerRadius;
@property int firstLegend;

@end

@implementation CrimeOptions2

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _legends = ConfigurationControl.sharedInstance.legendList;
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    
    _firstLegend = 2;
    _tv5.tag = (_firstLegend + 1);
    _tv1.tag = (_firstLegend + 2);
    _tv2.tag = (_firstLegend + 3);
    _tv3.tag = (_firstLegend + 4);
    _tv4.tag = (_firstLegend + 5);
    
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
    
    [self setupTableView:_tv1];
    [self setupTableView:_tv2];
    [self setupTableView:_tv3];
    [self setupTableView:_tv4];
    [self setupTableView:_tv5];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _legends = ConfigurationControl.sharedInstance.legendList;
    _countLengths = NSMutableArray.array;
    
    for (int i = _firstLegend; i < _legends.count; i++)
    {
        ThemeLegend *tl = (ThemeLegend *)_legends[i];
        NSUInteger length = 0;
        
        for (ThemeLegendCell *cells in tl.cells)
        {
            NSString *countString = [NSString stringWithFormat:@"%i", cells.count];
            length = MAX(length, countString.length);
        }
        
        [_countLengths insertObject:@(length)
                            atIndex:(i - _firstLegend)];
    }
    
    [self reloadTableViews];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)reloadTableViews
{
    [_tv1 reloadData];
    [_tv2 reloadData];
    [_tv3 reloadData];
    [_tv4 reloadData];
    [_tv5 reloadData];
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
    ThemeLegend *tl = (ThemeLegend *)_legends[tableView.tag - 1];
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
    ThemeLegend *tl = (ThemeLegend *)_legends[tableView.tag - 1];
    
    CGFloat margin = 52.0;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        margin = 26.0;
        
        if (UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeLeft ||
            UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeRight)
        {
            margin = 30.0;
        }
    }
    
    CGFloat tvWidth = ((self.view.frame.size.width - margin) / 2.0);
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        if (UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeLeft ||
            UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeRight)
        {
            tvWidth = ((self.view.frame.size.width - margin) / 4.0);
        }
    }
    
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
    
    if (![headerView.subviews containsObject:[headerView viewWithTag:(tableView.tag * 111)]])
    {
        UIButton *addToMap = [UIButton buttonWithType:UIButtonTypeCustom];
        addToMap.tag = (tableView.tag * 111);
        addToMap.imageView.contentMode = UIViewContentModeScaleAspectFit;
        addToMap.imageEdgeInsets = UIEdgeInsetsMake(2.0, 2.0, 2.0, 2.0);
        addToMap.selected = tl.drawOnMap;
        
        addToMap.frame = CGRectMake((headerView.frame.size.width - (headerView.frame.size.height * 2.0)), 0.0,
                                    (headerView.frame.size.height * 2.0), headerView.frame.size.height);
        
        [addToMap setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"greenPlusSign"
                                                                                          ofType:@"png"]]
                  forState:UIControlStateNormal];
        
        [addToMap setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"redMinusSign"
                                                                                          ofType:@"png"]]
                  forState:UIControlStateSelected];
        
        [addToMap addTarget:self
                     action:@selector(addLegend:)
           forControlEvents:UIControlEventTouchUpInside];
        
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
    
    for (UIView *views in cell.contentView.subviews)
    {
        if (views.tag == 777 || views.tag == 888)
            [views removeFromSuperview];
    }
    
    ThemeLegend *tl = (ThemeLegend *)_legends[tableView.tag - 1];
    ThemeLegendCell *tlc = (ThemeLegendCell *)tl.cells[indexPath.row];
    
    NSMutableString *text = tlc.label.mutableCopy;
    
    if (tl.appendClassCount)
    {
        NSMutableString *countString = [NSString stringWithFormat:@"%i", tlc.count].mutableCopy;
        
        while (countString.length < [_countLengths[((tableView.tag - _firstLegend) - 1)] integerValue])
        {
            [countString insertString:@" "
                              atIndex:0];
        }
        
        [text appendString:[NSString stringWithFormat:@" (%@)", countString.copy]];
    }
    
    UILabel *textLabel = [[UILabel alloc] init];
    textLabel.textColor = UIColor.blackColor;
    textLabel.font = _font;
    
    if (tlc.status)
        textLabel.text = tlc.label;
    
    else
        textLabel.text = text.copy;
    
    textLabel.textAlignment = NSTextAlignmentLeft;
    textLabel.adjustsFontSizeToFitWidth = YES;
    textLabel.tag = 888;
    
    cell.layer.borderColor = UIColor.blackColor.CGColor;
    cell.layer.borderWidth = 0.5;
    
    NSDictionary *attributes = @{NSFontAttributeName:_font};
    
    CGRect textSize = [text boundingRectWithSize:CGSizeMake(cell.textLabel.frame.size.width,
                                                            cell.textLabel.frame.size.height)
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:attributes
                                         context:nil];
    
    CGFloat xMargin = 52.0, yMargin = 52.0, barMargin = 8.0, fixedSize = 120.0, fixedMargin = 12.0;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        xMargin = 18.0, yMargin = 36.0, barMargin = 4.0, fixedSize = 80.0, fixedMargin = 6.0;
        
        if (UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeLeft ||
            UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeRight)
        {
            xMargin = 30.0, yMargin = 28.0, barMargin = 6.0;
        }
    }
    
    CGFloat tvWidth = ((self.view.frame.size.width - xMargin) / 2.0);
    CGFloat tvHeight = ((self.view.frame.size.height - yMargin) / 2.0);
    
    if (tableView == _tv3)
        tvHeight -= (fixedSize + fixedMargin);
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        if (UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeLeft ||
            UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeRight)
        {
            tvWidth = ((self.view.frame.size.width - xMargin) / 4.0);
            tvHeight = (self.view.frame.size.height - yMargin);
            
            if (tableView == _tv3)
                tvHeight -= (fixedSize + fixedMargin);
        }
    }
    
    if (tableView == _tv5)
        tvHeight = fixedSize;
    
    CGFloat rowHeight =  (CGFloat)((tvHeight - _headerHeight) / tl.numCells);
    CGFloat textWidth = ceil(textSize.size.width);
    
    textLabel.frame = CGRectMake((tvWidth - textWidth), 0.0, textWidth, rowHeight);
    [cell.contentView addSubview:textLabel];
    
    CGFloat barWidth = (((tvWidth - textWidth) - (barMargin * 2.0)) * tlc.symbolWidth);
    
    UIImageView *barView = [[UIImageView alloc] initWithFrame:
                            CGRectMake(barMargin, (rowHeight * 0.15), barWidth, (rowHeight * 0.7))];
    
    if (tl.useClassColors)
        barView.image = [UIImage imageFromColor:tlc.symbolColor];
    
    else
        barView.image = [UIImage imageFromColor:tl.symbolDefaultColor];
    
    barView.layer.borderColor = UIColor.blackColor.CGColor;
    barView.layer.borderWidth = 1.0;
    barView.tag = 777;
    [cell.contentView addSubview:barView];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    ThemeLegend *tl = (ThemeLegend *)_legends[tableView.tag - 1];
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
    ThemeLegend *tl = (ThemeLegend *)_legends[tableView.tag - 1];
    ThemeLegendCell *tlc = (ThemeLegendCell *)tl.cells[indexPath.row];
    tlc.status = YES;
    
    [tableView reloadRowsAtIndexPaths:@[indexPath]
                     withRowAnimation:UITableViewRowAnimationNone];
}

- (void)tableView:(UITableView *)tableView
didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ThemeLegend *tl = (ThemeLegend *)_legends[tableView.tag - 1];
    ThemeLegendCell *tlc = (ThemeLegendCell *)tl.cells[indexPath.row];
    tlc.status = NO;
    
    [tableView reloadRowsAtIndexPaths:@[indexPath]
                     withRowAnimation:UITableViewRowAnimationNone];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    [self reloadTableViews];
}

- (void)addLegend:(UIButton *)button
{
    ThemeLegend *tl = _legends[(button.tag / 111) - 1];
    
    if (!button.selected)
        tl.drawOnMap = button.selected = YES;
    
    else
        tl.drawOnMap = button.selected = NO;
}

@end