//  ThemesViewController.m
//  GMMobile

#import "ThemesViewController.h"
#import "ConfigurationControl.h"

@interface ThemesViewController ()

@property (nonatomic) NSArray *appList;
@property (nonatomic) CGFloat rowHeight;
@property (nonatomic) NSInteger selectedRow;
@property (nonatomic) UIImageView *checkmarkView;
@property (nonatomic) UIFont *font;

@end

@implementation ThemesViewController
{
    NVDataLoader * _nvdl;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _popover = [[GSSiPopoverView alloc] initWithView:self.view];
    _popover.delegate = self;
    _appList = ConfigurationControl.sharedInstance.appList;
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    
    _checkmarkView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:
                                                         [NSBundle.mainBundle pathForResource:@"checkmark"
                                                                                       ofType:@"png"]]];
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        _checkmarkView.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
        _rowHeight = 60.0;
        _font = [UIFont boldSystemFontOfSize:22.0];
    }
    
    else
    {
        _checkmarkView.frame = CGRectMake(0.0, 0.0, 60.0, 60.0);
        _rowHeight = 76.0;
        _font = [UIFont boldSystemFontOfSize:36.0];
    }
    
    _checkmarkView.contentMode = UIViewContentModeScaleToFill;
    
    _selectedRow = -1;
    [self setupTableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateTableView];
    [_tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _nvdl = [[NVDataLoader alloc]init];
    _nvdl.delegate = self;
    [_nvdl loadNVData:ConfigurationControl.sharedInstance.currentApp popover:_popover];
}

- (void) NVDataLoaderFailed:(int)status
{
    _nvdl.popover = nil;
    _nvdl.delegate = nil;
    _nvdl = nil;
}
- (void) NVDataLoaderSuccess
{
    _nvdl.popover = nil;
    _nvdl.delegate = nil;
    _nvdl = nil;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setupTableView
{
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorInset = UIEdgeInsetsZero;
    _tableView.separatorColor = UIColor.blackColor;
    _tableView.backgroundColor = UserDefaults.defaults.green;
    _tableView.bounces = NO;
    _tableView.layer.borderColor = UIColor.blackColor.CGColor;
    _tableView.layer.borderWidth = (_rowHeight / 24.0);
    _tableView.layer.cornerRadius = 10.0;
    _tableView.rowHeight = _rowHeight;
    _tableView.sectionHeaderHeight = _rowHeight;
}

- (void)updateTableView
{
    NSInteger selectedRow = (NSInteger)ConfigurationControl.sharedInstance.currentApp;
    
    NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:selectedRow
                                                        inSection:0];
    
    [_tableView cellForRowAtIndexPath:selectedIndexPath].accessoryView = _checkmarkView;
    _selectedRow = selectedIndexPath.row;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView
viewForHeaderInSection:(NSInteger)section
{
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:
                            CGRectMake(0.0, 0.0, tableView.frame.size.width, _rowHeight)];
    
    headerLabel.font = _font;
    headerLabel.textColor = UIColor.whiteColor;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.text = @"Select Application";
    
    UIView *headerView = [[UIView alloc] initWithFrame:
                          CGRectMake(0.0, 0.0, tableView.frame.size.width, _rowHeight)];

    [headerView addSubview:headerLabel];
    headerView.backgroundColor = UIColor.blackColor;
    return headerView;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return ConfigurationControl.sharedInstance.appList.count;
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
    
    if (_appList.count != 0)
    {
        ApplicationObject *app = (ApplicationObject *)_appList[indexPath.row];
        cell.textLabel.text = app.appName;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.textColor = UIColor.blackColor;
        cell.userInteractionEnabled = YES;
    }
    
    else
    {
        cell.textLabel.text = @"No Apps in List";
        cell.textLabel.textColor = UIColor.grayColor;
        cell.userInteractionEnabled = NO;
    }
    
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.font = _font;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == _selectedRow)
        cell.accessoryView = _checkmarkView;
    
    else
        cell.accessoryView = nil;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ApplicationObject *app = _appList[indexPath.row];
    [ConfigurationControl.sharedInstance setApp:app.appID];
    
    [tableView cellForRowAtIndexPath:indexPath].accessoryView = _checkmarkView;
    _selectedRow = indexPath.row;
    [tableView reloadData];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    [_tableView reloadData];
}

@end