//  CrimeOptions2.m
//  GMMobile

#import "CrimeOptions2.h"
#import "CCodeLibrary/UserDefaults.h"
#import "ConfigurationControl.h"
#import "ThemeLegend.h"

@interface CrimeOptions2 ()

@property (nonatomic) NSArray *legends;
@property (nonatomic) UIFont *font;
@property (nonatomic) CGFloat headerHeight;
@property BOOL rotating;

@end

@implementation CrimeOptions2

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _legends = ConfigurationControl.sharedInstance.legendList.copy;
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    _rotating = NO;
    
    _tv1.tag = 1;
    _tv2.tag = 2;
    _tv3.tag = 3;
    _tv4.tag = 4;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        _headerHeight = 32.0;
        _font = [UIFont boldSystemFontOfSize:18.0];
    }
    
    else
    {
        _headerHeight = 44.0;
        _font = [UIFont boldSystemFontOfSize:28.0];
    }
    
    [self setupTableView:_tv1];
    [self setupTableView:_tv2];
    [self setupTableView:_tv3];
    [self setupTableView:_tv4];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _legends = ConfigurationControl.sharedInstance.legendList.copy;
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
}

- (void)setupTableView:(UITableView *)tableView
{
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.backgroundColor = UserDefaults.defaults.green;
    tableView.bounces = NO;
    tableView.layer.borderColor = UIColor.blackColor.CGColor;
    tableView.layer.borderWidth = 2.5;
    tableView.layer.cornerRadius = 10.0;
    tableView.delaysContentTouches = NO;
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
    CGRect frame = CGRectZero;
    
    if (_rotating)
    {
        frame = CGRectMake(0.0, 0.0, tableView.frame.size.height,
                           [self tableView:tableView heightForHeaderInSection:0]);
    }
    
    else
    {
        frame = CGRectMake(0.0, 0.0, tableView.frame.size.width,
                           [self tableView:tableView heightForHeaderInSection:0]);
    }
    
    UIView *headerView = [[UIView alloc] initWithFrame:frame];
    
    headerView.backgroundColor = UIColor.blackColor;
    headerView.contentMode = UIViewContentModeCenter;
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:
                            CGRectMake(0.0, 0.0, headerView.frame.size.width,
                                       headerView.frame.size.height)];
    
    headerLabel.font = _font;
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
    
    ThemeLegend *tl = (ThemeLegend *)_legends[tableView.tag - 1];
    ThemeLegendCell *tlc = (ThemeLegendCell *)tl.cells[indexPath.row];
    
    NSMutableString *text = tlc.label.mutableCopy;
    
    if (tl.appendClassCount)
        [text appendString:[NSString stringWithFormat:@" (%i)", tlc.count]];
    
    cell.textLabel.textColor = UIColor.blackColor;
    cell.textLabel.font = _font;
    cell.textLabel.text = text.copy;
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    
    return cell;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    _rotating = YES;
    [self reloadTableViews];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    _rotating = NO;
}

@end