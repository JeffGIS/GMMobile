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

@end

@implementation CrimeOptions1

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _legends = ConfigurationControl.sharedInstance.legendList.copy;
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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _legends = ConfigurationControl.sharedInstance.legendList.copy;
    
    ThemeLegend *tl = (ThemeLegend *)_legends[0];
    
    for (ThemeLegendCell *cells in tl.cells)
    {
        NSString *countString = [NSString stringWithFormat:@"%i", cells.count];
        _countLength = MAX(_countLength, countString.length);
    }
    
    [_tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setupTableView
{
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = UserDefaults.defaults.green;
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
        margin = 26.0;
        
        if (UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeLeft ||
            UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeRight)
        {
            margin = 30.0;
        }
    }
    
    CGFloat tvWidth = (self.view.frame.size.width - margin);
    
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
    
    cell.imageView.image = imageFromSymbol(tlc.symbol, 48.0, UIColor.redColor);
    
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
}

@end