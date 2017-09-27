//  ConfigurationVC.m
//  NVMobile

#import "ConfigurationVC.h"
#import "CCodeLibrary/UserDefaults.h"

@interface ConfigurationVC () <UITableViewDelegate,UITableViewDataSource>

@property CGFloat rowHeight, margin;
@property (nonatomic) UIFont *font, *headerFont;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSMutableArray *configurations;

@end

@implementation ConfigurationVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    _configurations = NSMutableArray.array;
    [_configurations addObject:@"Good Configuration"];
    [_configurations addObject:@"Better Configuration"];
    [_configurations addObject:@"Desperate Configuration"];
    [_configurations addObject:@"Last Resort Configuration"];
    [_configurations addObject:@"Pathetic Configuration"];
    [_configurations addObject:@"Million Dollar Configuration"];
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        _rowHeight = 48.0;
        _font = [UIFont boldSystemFontOfSize:16.0];
        _headerFont = [UIFont boldSystemFontOfSize:24.0];
        _margin = 8.0;
    }
    
    else
    {
        _rowHeight = 64.0;
        _font = [UIFont boldSystemFontOfSize:26.0];
        _headerFont = [UIFont boldSystemFontOfSize:40.0];
        _margin = 20.0;
    }
    
    [self setupTableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)setupTableView
{
    _tableView = UITableView.new;
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
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
    [self.view addSubview:_tableView];
    [_tableView constrainToView:self.view leading:_margin trailing:-_margin top:_margin bottom:-_margin];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return _configurations.count;
}

- (UIView *)tableView:(UITableView *)tableView
viewForHeaderInSection:(NSInteger)section
{
    UILabel *headerLabel = UILabel.new;
    headerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    headerLabel.font = _headerFont;
    headerLabel.textColor = UIColor.whiteColor;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.text = @"Configurations";
    
    UIView *headerView = [[UIView alloc] initWithFrame:
                          CGRectMake(0.0, 0.0, tableView.frame.size.width, _rowHeight)];
    
    [headerView addSubview:headerLabel];
    [headerLabel constrainToView:headerView leading:0.0 trailing:0.0 top:0.0 bottom:0.0];
    headerView.backgroundColor = UIColor.blackColor;
    
    CGFloat imageInset = (_rowHeight / 8.0);
    UIEdgeInsets edgeInsets = UIEdgeInsetsMake(imageInset, imageInset, imageInset, imageInset);
    
    UIButton *trash = [UIButton buttonWithType:UIButtonTypeCustom];
    trash.translatesAutoresizingMaskIntoConstraints = NO;
    trash.imageEdgeInsets = edgeInsets;
    
    [trash setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"whiteTrashCan"
                                                                                   ofType:@"png"]]
           forState:UIControlStateNormal];
    
    [trash addTarget:self
              action:@selector(trashTapped:)
    forControlEvents:UIControlEventTouchUpInside];
    
    [headerView addSubview:trash];
    [trash constrainLeadingToAnchor:headerView.leadingAnchor];
    [trash constrainTopToAnchor:headerView.topAnchor];
    [trash constrainBottomToAnchor:headerView.bottomAnchor];
    [trash constrainWidthToConstant:_rowHeight];
    
    UIButton *plus = [UIButton buttonWithType:UIButtonTypeCustom];
    plus.translatesAutoresizingMaskIntoConstraints = NO;
    plus.imageEdgeInsets = edgeInsets;
    
    [plus setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"whitePlus"
                                                                                  ofType:@"png"]]
          forState:UIControlStateNormal];
    
    [plus addTarget:self
             action:@selector(plusTapped:)
   forControlEvents:UIControlEventTouchUpInside];
    
    [headerView addSubview:plus];
    [plus constrainTrailingToAnchor:headerView.trailingAnchor];
    [plus constrainTopToAnchor:headerView.topAnchor];
    [plus constrainBottomToAnchor:headerView.bottomAnchor];
    [plus constrainWidthToConstant:_rowHeight];
    
    return headerView;
}

- (void)plusTapped:(UIButton *)button
{
    
}

- (void)trashTapped:(UIButton *)button
{
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"CustomCell";
    
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellIdentifier];
    }
    
    cell.textLabel.text = _configurations[indexPath.row];
    cell.textLabel.textColor = UIColor.blackColor;
    cell.textLabel.font = _font;
    cell.backgroundColor = UIColor.whiteColor;
    
    return cell;
}

@end
