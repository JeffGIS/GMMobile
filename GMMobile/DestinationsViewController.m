//  DestinationsViewController.m
//  GMMobile

#import "DestinationsViewController.h"
#import "CCodeLibrary/UserDefaults.h"
#import "PropertyList.h"
#import "Destinations.h"
#import "CCodeLibrary/TableViewCellButton.h"
#import "CCodeLibrary/TableViewCellLabel.h"

@interface DestinationsViewController ()

@property (nonatomic) CGFloat rowHeight;
@property (nonatomic) UIFont *font;
@property (nonatomic) NSArray *individualDestinations, *groupDestinations;
@property (nonatomic) UIButton *topHeaderButton, *bottomHeaderButton;
@property (nonatomic) UIImage *editNameImage, *editOptionsImage;

@end

@implementation DestinationsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    
    _editNameImage = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"editText"
                                                                                    ofType:@"png"]];
    
    _editOptionsImage = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"editOptions"
                                                                                       ofType:@"png"]];
    
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
        
        cell.userInteractionEnabled = YES;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    for (UIView *views in cell.contentView.subviews)
    {
        if ([views isKindOfClass:TableViewCellLabel.class] ||
            [views isKindOfClass:TableViewCellButton.class])
        {
            [views removeFromSuperview];
        }
    }
    
    TableViewCellLabel *cellTextLabel = [[TableViewCellLabel alloc] initWithFrame:
                                         CGRectMake(16.0, 0.0, ((cell.contentView.frame.size.width - (cell.contentView.frame.size.height * 2.0)) - 32.0),
                                                    cell.contentView.frame.size.height)];
    
    cellTextLabel.adjustsFontSizeToFitWidth = YES;;
    cellTextLabel.textColor = UIColor.blackColor;
    cellTextLabel.textAlignment = NSTextAlignmentLeft;
    cellTextLabel.font = _font;
    
    [cell.contentView addSubview:cellTextLabel];
    
    if (tableView == _topTableView)
        cellTextLabel.text = [_individualDestinations[indexPath.row] destinationName];
    
    else
        cellTextLabel.text = [_groupDestinations[indexPath.row] destinationName];
    
    
    TableViewCellButton *editName = [[TableViewCellButton alloc] initWithFrame:
                                     CGRectMake((cell.contentView.frame.size.width - (cell.contentView.frame.size.height * 2.0)), 5.0,
                                                (cell.contentView.frame.size.height - 10.0),
                                                (cell.contentView.frame.size.height - 10.0))];
    
    editName.tag = (indexPath.row + 100);
    
    [editName setImage:_editNameImage
              forState:UIControlStateNormal];
    
    [cell.contentView addSubview:editName];
    
    [editName addTarget:self
                 action:@selector(editNameTapped:)
       forControlEvents:UIControlEventTouchUpInside];
    
    TableViewCellButton *editOptions = [[TableViewCellButton alloc] initWithFrame:
                                        CGRectMake((cell.contentView.frame.size.width - cell.contentView.frame.size.height), 5.0,
                                                   (cell.contentView.frame.size.height - 10.0),
                                                   (cell.contentView.frame.size.height - 10.0))];
    
    editOptions.tag = (indexPath.row + 200);
    
    [editOptions setImage:_editOptionsImage
                 forState:UIControlStateNormal];
    
    [cell.contentView addSubview:editOptions];
    
    [editOptions addTarget:self
                    action:@selector(editOptionsTapped:)
          forControlEvents:UIControlEventTouchUpInside];

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView
canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        if (tableView == _topTableView)
        {
            Destinations *destinations = [[Destinations alloc] init];
            [destinations removeDestination:(indexPath.row + 1)];
            
            _individualDestinations = [destinations getIndividualDestinations];
            [tableView reloadData];
        }
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    [_topTableView reloadData];
    [_bottomTableView reloadData];
}

- (void)editNameTapped:(TableViewCellButton *)button
{
    NVTextAlert *textAlert = [NVTextAlert showTextAlertinView:self.view
                                                     delegate:self
                                                        title:@"Enter Destination Name"];
    textAlert.minimumCharacters = 0;
    textAlert.tag = button.tag;
}

- (void)editOptionsTapped:(TableViewCellButton *)button
{
    NSUInteger row = (button.tag - 200);
}

- (void)textAlert:(NVTextAlert *)textAlert
    didReturnText:(NSString *)text
{
    if (text && ![text isEqualToString:@""])
    {
        NSUInteger row = (textAlert.tag - 100);
        
        Destinations *destinations = [[Destinations alloc] init];
        Destination *destination = [destinations getDestination:(row + 1)];
        destination.destinationName = text;
        [destinations updateDestination:destination];
        
        _individualDestinations = [destinations getIndividualDestinations];
        [_topTableView reloadData];
    }
        
    [textAlert hideTextAlert:YES];
}

- (void)addIndividual:(UIButton *)button
{
    
}

- (void)addGroup:(UIButton *)button
{
    
}

@end