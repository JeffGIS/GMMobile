//  DestinationsViewController.m
//  GMMobile

#import "DestinationsViewController.h"
#import "CCodeLibrary/UserDefaults.h"
#import "PropertyList.h"
#import "Destinations.h"

@interface DestinationsViewController ()

@property (nonatomic) CGFloat rowHeight;
@property (nonatomic) UIFont *font;
@property (nonatomic) NSArray *individualDestinations, *groupDestinations;
@property (nonatomic) UIButton *topHeaderButton, *bottomHeaderButton;

@end

@implementation DestinationsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        _rowHeight = 60.0;
        _font = [UIFont boldSystemFontOfSize:22.0];
    }
    
    else
    {
        _rowHeight = 76.0;
        _font = [UIFont boldSystemFontOfSize:36.0];
    }
    
    _topHeaderButton = [[UIButton alloc] init];
    _bottomHeaderButton = [[UIButton alloc] init];
    
    [_topHeaderButton setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"greenPlusSign"
                                                                                              ofType:@"png"]]
                      forState:UIControlStateNormal];
    
    [_bottomHeaderButton setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"greenPlusSign"
                                                                                                 ofType:@"png"]]
                         forState:UIControlStateNormal];
    
    CGFloat imageInset = (_rowHeight / 10.0);
    UIEdgeInsets edgeInsets = UIEdgeInsetsMake(imageInset, imageInset, imageInset, imageInset);
    
    _topHeaderButton.imageEdgeInsets = edgeInsets;
    _bottomHeaderButton.imageEdgeInsets = edgeInsets;
    
    [_topHeaderButton addTarget:self
                         action:@selector(addIndividual:)
               forControlEvents:UIControlEventTouchUpInside];
    
    [_bottomHeaderButton addTarget:self
                            action:@selector(addGroup:)
                  forControlEvents:UIControlEventTouchUpInside];
    
    [self setupTableView:_topTableView];
    [self setupTableView:_bottomTableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    Destinations *destinations = [[Destinations alloc] init];
    
    _individualDestinations = [destinations getIndividualDestinations];
    [_topTableView reloadData];
    
    _groupDestinations = [destinations getGroupDestinations];
    [_bottomTableView reloadData];
}

- (void)setupTableView:(UITableView *)tableView
{
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.separatorInset = UIEdgeInsetsZero;
    tableView.separatorColor = UIColor.blackColor;
    tableView.backgroundColor = UserDefaults.defaults.green;
    tableView.bounces = NO;
    tableView.layer.borderColor = UIColor.blackColor.CGColor;
    tableView.layer.borderWidth = (_rowHeight / 24.0);
    tableView.layer.cornerRadius = 10.0;
    tableView.rowHeight = _rowHeight;
    tableView.sectionHeaderHeight = _rowHeight;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    if (tableView == _topTableView)
        return _individualDestinations.count;
    
    else
        return _groupDestinations.count;
}

- (UIView *)tableView:(UITableView *)tableView
viewForHeaderInSection:(NSInteger)section
{
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:
                            CGRectMake(_rowHeight, 0.0, (tableView.frame.size.width - (_rowHeight * 2.0)), _rowHeight)];
    
    headerLabel.font = _font;
    headerLabel.textColor = UIColor.whiteColor;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    
    if (tableView == _topTableView)
        headerLabel.text = @"Individual Destinations";
    
    else
        headerLabel.text = @"Group Destinations";
    
    UIView *headerView = [[UIView alloc] initWithFrame:
                          CGRectMake(0.0, 0.0, tableView.frame.size.width, _rowHeight)];
    
    [headerView addSubview:headerLabel];
    headerView.backgroundColor = UIColor.blackColor;
    
    if (tableView == _topTableView)
    {
        if (![headerView.subviews containsObject:_topHeaderButton])
        {
            _topHeaderButton.frame = CGRectMake((headerView.frame.size.width - _rowHeight),
                                                0.0, _rowHeight, _rowHeight);
            
            [headerView addSubview:_topHeaderButton];
        }
    }
    
    else
    {
        if (![headerView.subviews containsObject:_bottomHeaderButton])
        {
            _bottomHeaderButton.frame = CGRectMake((headerView.frame.size.width - _rowHeight),
                                                   0.0, _rowHeight, _rowHeight);
            
            [headerView addSubview:_bottomHeaderButton];
        }
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
    
    if (tableView == _topTableView)
        cell.textLabel.text = [_individualDestinations[indexPath.row] destinationName];
    
    else
        cell.textLabel.text = [_groupDestinations[indexPath.row] destinationName];
    
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.textColor = UIColor.blackColor;
    cell.userInteractionEnabled = YES;
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.font = _font;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    [_topTableView reloadData];
    [_bottomTableView reloadData];
}

- (void)addIndividual:(UIButton *)button
{
    
}

- (void)addGroup:(UIButton *)button
{
    
}

@end