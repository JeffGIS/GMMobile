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
@property (nonatomic) CGFloat headerHeight;
@property BOOL rotating;
@property int firstLegend;

@end

@implementation CrimeOptions2

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _legends = ConfigurationControl.sharedInstance.legendList.copy;
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    _rotating = NO;
    
    _firstLegend = 3;
    _tv1.tag = (_firstLegend + 1);
    _tv2.tag = (_firstLegend + 2);
    _tv3.tag = (_firstLegend + 3);
    _tv4.tag = (_firstLegend + 4);
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        _headerHeight = 30.0;
        
        _font = [UIFont fontWithName:@"CourierNewPS-BoldMT"
                                size:16.0];
        
        _headerFont = [UIFont boldSystemFontOfSize:18.0];
    }
    
    else
    {
        _headerHeight = 40.0;
        
        _font = [UIFont fontWithName:@"CourierNewPS-BoldMT"
                                size:24.0];
        
        _headerFont = [UIFont boldSystemFontOfSize:28.0];
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
    tableView.allowsMultipleSelection = YES;
    tableView.separatorColor = UIColor.clearColor;
    tableView.separatorInset = UIEdgeInsetsZero;
    tableView.contentInset = UIEdgeInsetsZero;
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
    
    for (UIView *views in cell.contentView.subviews)
    {
        if (views.tag == 777)
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
    
    NSDictionary *attributes = @{NSFontAttributeName:_font};
    
    CGRect textSize = [text boundingRectWithSize:CGSizeMake(cell.textLabel.frame.size.width,
                                                            cell.textLabel.frame.size.height)
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:attributes
                                         context:nil];
    
    CGFloat textWidth = ceil(textSize.size.width);
    CGFloat barWidth = (((cell.contentView.frame.size.width - textWidth) - 32.0) * tlc.symbolWidth);
    
    UIImageView *barView = [[UIImageView alloc] initWithFrame:
                            CGRectMake(8.0, (cell.contentView.frame.size.height * 0.15),
                                       barWidth, (cell.contentView.frame.size.height * 0.7))];
    
    barView.image = [UIImage imageFromColor:UserDefaults.defaults.green];
    barView.layer.borderColor = UIColor.blackColor.CGColor;
    barView.layer.borderWidth = 1.0;
    barView.tag = 777;
    [cell.contentView addSubview:barView];
    
    cell.textLabel.textColor = UIColor.blackColor;
    cell.textLabel.font = _font;
    cell.textLabel.text = text.copy;
    cell.textLabel.textAlignment = NSTextAlignmentRight;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.layer.borderColor = UIColor.blackColor.CGColor;
    cell.layer.borderWidth = 0.5;
    
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
}

- (void)tableView:(UITableView *)tableView
didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ThemeLegend *tl = (ThemeLegend *)_legends[tableView.tag - 1];
    ThemeLegendCell *tlc = (ThemeLegendCell *)tl.cells[indexPath.row];
    tlc.status = NO;
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