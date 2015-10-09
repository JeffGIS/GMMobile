//  DestinationsViewController.m
//  GMMobile

#import "DestinationsViewController.h"
#import "CCodeLibrary/UserDefaults.h"
#import "PropertyList.h"
#import "Destinations.h"
#import "CCodeLibrary/TableViewCellButton.h"
#import "CCodeLibrary/TableViewCellLabel.h"
#import "CCodeLibrary/NVStaticMapView.h"

@interface DestinationsViewController ()

@property (nonatomic) CGFloat rowHeight;
@property (nonatomic) UIFont *font, *subFont;
@property (nonatomic) NSArray *individualDestinations, *groupDestinations;
@property (nonatomic) UIButton *topHeaderButton, *bottomHeaderButton;
@property (nonatomic) UIImage *editNameImage, *editOptionsImage, *googleImage;

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
    
    _googleImage = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"googleIcon"
                                                                                  ofType:@"png"]];

    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        _rowHeight = 60.0;
        _font = [UIFont boldSystemFontOfSize:22.0];
        _subFont = [UIFont systemFontOfSize:12.0];
    }
    
    else
    {
        _rowHeight = 76.0;
        _font = [UIFont boldSystemFontOfSize:36.0];
        _subFont = [UIFont systemFontOfSize:20.0];
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
    
    _individualDestinations = [self sortedDestinationsArray:
                               [destinations getIndividualDestinations]];
    
    [_topTableView reloadData];
    
    _groupDestinations = [self sortedDestinationsArray:
                          [destinations getGroupDestinations]];
    
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
    
    for (UIView *views in cell.contentView.subviews)
    {
        if ([views isKindOfClass:TableViewCellLabel.class] ||
            [views isKindOfClass:TableViewCellButton.class])
        {
            [views removeFromSuperview];
        }
    }
    
    TableViewCellLabel *cellTextLabel = [[TableViewCellLabel alloc] initWithFrame:
                                         CGRectMake(16.0, 0.0, (cell.contentView.frame.size.width - ((cell.contentView.frame.size.height + 16.0) * 3.0)),
                                                    cell.contentView.frame.size.height * 0.7)];
    
    cellTextLabel.adjustsFontSizeToFitWidth = YES;
    cellTextLabel.textColor = UIColor.blackColor;
    cellTextLabel.textAlignment = NSTextAlignmentLeft;
    cellTextLabel.font = _font;
    
    [cell.contentView addSubview:cellTextLabel];
    
    TableViewCellLabel *cellSubTextLabel = [[TableViewCellLabel alloc] initWithFrame:
                                            CGRectMake(16.0, (cell.contentView.frame.size.height * 0.7),
                                                       (cell.contentView.frame.size.width - ((cell.contentView.frame.size.height + 16.0) * 3.0)),
                                                       (cell.contentView.frame.size.height * 0.3))];
    
    cellSubTextLabel.adjustsFontSizeToFitWidth = YES;
    cellSubTextLabel.textColor = UIColor.blackColor;
    cellSubTextLabel.textAlignment = NSTextAlignmentLeft;
    cellSubTextLabel.font = _subFont;
    
    [cell.contentView addSubview:cellSubTextLabel];
    
    Destination *destination = nil;
    
    if (tableView == _topTableView)
    {
        destination = _individualDestinations[indexPath.row];
        cellTextLabel.text = destination.destinationName;
        cellSubTextLabel.text = [[NVDestinationOptions frequencyTitleForFrequency:destination.frequency] uppercaseString];
    }
    
    else
    {
        destination = _groupDestinations[indexPath.row];
        cellTextLabel.text = destination.destinationName;
        cellSubTextLabel.text = [[NVDestinationOptions frequencyTitleForFrequency:destination.frequency] uppercaseString];
    }
    
    
    TableViewCellButton *editName = [[TableViewCellButton alloc] initWithFrame:
                                     CGRectMake((cell.contentView.frame.size.width - (cell.contentView.frame.size.height * 3.0)), 5.0,
                                                (cell.contentView.frame.size.height - 10.0),
                                                (cell.contentView.frame.size.height - 10.0))];
    
    editName.tag = (indexPath.row + 100);
    
    if (tableView == _bottomTableView)
        editName.tag += 1000;
    
    [editName setImage:_editNameImage
              forState:UIControlStateNormal];
    
    [cell.contentView addSubview:editName];
    
    [editName addTarget:self
                 action:@selector(editNameTapped:)
       forControlEvents:UIControlEventTouchUpInside];
    
    TableViewCellButton *editOptions = [[TableViewCellButton alloc] initWithFrame:
                                        CGRectMake((cell.contentView.frame.size.width - (cell.contentView.frame.size.height * 2.0)), 5.0,
                                                   (cell.contentView.frame.size.height - 10.0),
                                                   (cell.contentView.frame.size.height - 10.0))];
    
    editOptions.tag = (indexPath.row + 400);
    
    if (tableView == _bottomTableView)
        editOptions.tag += 1000;
    
    [editOptions setImage:_editOptionsImage
                 forState:UIControlStateNormal];
    
    [cell.contentView addSubview:editOptions];
    
    [editOptions addTarget:self
                    action:@selector(editOptionsTapped:)
          forControlEvents:UIControlEventTouchUpInside];
    
    TableViewCellButton *mapIt = [[TableViewCellButton alloc] initWithFrame:
                                  CGRectMake((cell.contentView.frame.size.width - cell.contentView.frame.size.height), 5.0,
                                             (cell.contentView.frame.size.height - 10.0),
                                             (cell.contentView.frame.size.height - 10.0))];
    
    mapIt.tag = (indexPath.row + 700);
    
    if (tableView == _bottomTableView)
        mapIt.tag += 1000;
    
    [mapIt setImage:_googleImage
           forState:UIControlStateNormal];
    
    [cell.contentView addSubview:mapIt];
    
    [mapIt addTarget:self
              action:@selector(mapItTapped:)
    forControlEvents:UIControlEventTouchUpInside];
    
    cell.userInteractionEnabled = YES;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

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
        Destination *destination = nil;
        
        if (tableView == _topTableView)
            destination= _individualDestinations[indexPath.row];
        
        else
            destination= _groupDestinations[indexPath.row];
        
        Destinations *destinations = [[Destinations alloc] init];
        [destinations removeDestination:destination.destinationID];
            
        if (tableView == _topTableView)
        {
            _individualDestinations = [self sortedDestinationsArray:
                                       [destinations getIndividualDestinations]];
        }
        
        else
        {
            _groupDestinations = [self sortedDestinationsArray:
                                  [destinations getGroupDestinations]];
        }
        
        [tableView reloadData];
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
    Destination *destination = nil;
    
    if (button.tag < 1000)
        destination = _individualDestinations[(button.tag - 400)];
    
    else
        destination = _groupDestinations[(button.tag - 1400)];
    
    NVDestinationOptions *destOpt =
    [NVDestinationOptions showDestinationOptionsInView:self.view
                                              delegate:self
                                             frequency:destination.frequency
                                            timeDepart:destination.timeDepart
                                            timeReturn:destination.timeReturn
                                         destinationID:destination.destinationID];

    destOpt.tag = button.tag;
}

- (void)destinationOptions:(NVDestinationOptions *)destinationOptions
        didReturnFrequency:(NSInteger)frequency
                timeDepart:(NSInteger)timeDepart
                timeReturn:(NSInteger)timeReturn
             destinationID:(NSInteger)destinationID
{
    [destinationOptions hideDestinationOptions:YES];
    
    Destinations *destinations = [[Destinations alloc] init];
    
    Destination *destination = [destinations getDestination:destinationID];
    destination.frequency = frequency;
    destination.timeDepart = timeDepart;
    destination.timeReturn = timeReturn;
    
    [destinations updateDestination:destination];
    
    if (destinationOptions.tag < 1000)
    {
        _individualDestinations = [self sortedDestinationsArray:
                                   [destinations getIndividualDestinations]];
        
        [_topTableView reloadData];
    }
    
    else
    {
        _groupDestinations = [self sortedDestinationsArray:
                              [destinations getGroupDestinations]];
        
        [_bottomTableView reloadData];
    }
}

- (void)mapItTapped:(TableViewCellButton *)button
{
    Destination *destination = nil;
    
    if (button.tag < 1000)
        destination = _individualDestinations[(button.tag - 700)];
    
    else
        destination = _groupDestinations[(button.tag - 1700)];
    
    NVStaticMapView *staticMap = [NVStaticMapView showStaticMapInView:self.view
                                                       withCoordinate:destination.latlon
                                                                 zoom:17.0
                                                               tabBar:self.tabBarController.tabBar
                                                                label:destination.destinationName];
#pragma unused(staticMap) 
}

- (void)textAlert:(NVTextAlert *)textAlert
    didReturnText:(NSString *)text
{
    if (text && ![text isEqualToString:@""])
    {
        Destination *destination = nil;
        
        if (textAlert.tag < 1000)
            destination = _individualDestinations[(textAlert.tag - 100)];
        
        else
            destination = _groupDestinations[(textAlert.tag - 1100)];
        
        destination.destinationName = text;
        
        Destinations *destinations = [[Destinations alloc] init];
        [destinations updateDestination:destination];
        
        if (textAlert.tag < 1000)
        {
            _individualDestinations = [self sortedDestinationsArray:
                                       [destinations getIndividualDestinations]];
            
            [_topTableView reloadData];
        }
        
        else
        {
            _groupDestinations = [self sortedDestinationsArray:
                                  [destinations getGroupDestinations]];
            
            [_bottomTableView reloadData];
        }
    }
        
    [textAlert hideTextAlert:YES];
}

- (void)addIndividual:(UIButton *)button
{
    
}

- (void)addGroup:(UIButton *)button
{
    
}

- (NSArray *)sortedDestinationsArray:(NSArray *)destinationsArray
{
    NSMutableArray *sortedArray = NSMutableArray.array;
    NSUInteger index = 0;
    
    for (int i = 0; i < destinationsArray.count; i++)
    {
        if (sortedArray.count == 0)
            [sortedArray addObject:destinationsArray[0]];
        
        else
        {
            NSComparisonResult result = [[destinationsArray[i] destinationName]
                                         compare:[sortedArray[index] destinationName]
                                         options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch)];
            
            while (result == NSOrderedDescending)
            {
                index++;
                
                if (index == sortedArray.count)
                    break;
                
                result = [[destinationsArray[i] destinationName]
                          compare:[sortedArray[index] destinationName]
                          options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch)];
            }
            
            [sortedArray insertObject:destinationsArray[i]
                              atIndex:index];
            
            index = 0;
        }
    }
    
    return sortedArray.copy;
}

@end