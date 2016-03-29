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
@property (nonatomic) UIButton *topPlusButton, *bottomPlusButton, *topMapItButton, *bottomMapItButton;
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
        _rowHeight = 44.0;
        _font = [UIFont boldSystemFontOfSize:18.0];
        _subFont = [UIFont systemFontOfSize:12.0];
    }
    
    else
    {
        _rowHeight = 60.0;
        _font = [UIFont boldSystemFontOfSize:32.0];
        _subFont = [UIFont systemFontOfSize:20.0];
    }
    
    _topPlusButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _bottomPlusButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _topMapItButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _bottomMapItButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    _topPlusButton.translatesAutoresizingMaskIntoConstraints = NO;
    _bottomPlusButton.translatesAutoresizingMaskIntoConstraints = NO;
    _topMapItButton.translatesAutoresizingMaskIntoConstraints = NO;
    _bottomMapItButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_topPlusButton setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"greenPlusSign"
                                                                                            ofType:@"png"]]
                    forState:UIControlStateNormal];
    
    [_bottomPlusButton setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"greenPlusSign"
                                                                                               ofType:@"png"]]
                       forState:UIControlStateNormal];
    
    [_topMapItButton setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"whiteMapItWithX"
                                                                                             ofType:@"png"]]
                     forState:UIControlStateNormal];
    
    [_topMapItButton setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"whiteMapItWithX"
                                                                                             ofType:@"png"]]
                     forState:UIControlStateNormal|UIControlStateHighlighted];
    
    [_topMapItButton setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"whiteMapIt"
                                                                                             ofType:@"png"]]
                     forState:UIControlStateSelected];
    
    [_topMapItButton setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"whiteMapIt"
                                                                                             ofType:@"png"]]
                     forState:UIControlStateSelected|UIControlStateHighlighted];
    
    [_bottomMapItButton setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"whiteMapItWithX"
                                                                                                ofType:@"png"]]
                        forState:UIControlStateNormal];
    
    [_bottomMapItButton setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"whiteMapItWithX"
                                                                                                ofType:@"png"]]
                        forState:UIControlStateNormal|UIControlStateHighlighted];
    
    [_bottomMapItButton setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"whiteMapIt"
                                                                                                ofType:@"png"]]
                        forState:UIControlStateSelected];
    
    [_bottomMapItButton setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"whiteMapIt"
                                                                                                ofType:@"png"]]
                        forState:UIControlStateSelected|UIControlStateHighlighted];
    
    CGFloat imageInset = (_rowHeight / 10.0);
    UIEdgeInsets edgeInsets = UIEdgeInsetsMake(imageInset, imageInset, imageInset, imageInset);
    
    _topPlusButton.imageEdgeInsets = edgeInsets;
    _bottomPlusButton.imageEdgeInsets = edgeInsets;
    _topMapItButton.imageEdgeInsets = edgeInsets;
    _bottomMapItButton.imageEdgeInsets = edgeInsets;
    
    _topMapItButton.selected = CRAPI.sharedInstance.mapIndividualDest;
    _bottomMapItButton.selected = CRAPI.sharedInstance.mapGroupDest;
    
    [_topPlusButton addTarget:self
                       action:@selector(addIndividual:)
             forControlEvents:UIControlEventTouchUpInside];
    
    [_bottomPlusButton addTarget:self
                          action:@selector(addGroup:)
                forControlEvents:UIControlEventTouchUpInside];
    
    [_topMapItButton addTarget:self
                        action:@selector(individualMapItToggle:)
              forControlEvents:UIControlEventTouchUpInside];
    
    [_bottomMapItButton addTarget:self
                           action:@selector(groupMapItToggle:)
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
    UIView *headerView = UIView.new;
    headerView.backgroundColor = UIColor.blackColor;
    
    UILabel *headerLabel = UILabel.new;
    headerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    headerLabel.font = _font;
    headerLabel.textColor = UIColor.whiteColor;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.adjustsFontSizeToFitWidth = YES;
    
    if (tableView == _topTableView)
        headerLabel.text = @"Individual Destinations";
    
    else
        headerLabel.text = @"Group Destinations";
    
    [headerView addSubview:headerLabel];
    
    if (tableView == _topTableView)
    {
        if (![headerView.subviews containsObject:_topPlusButton])
        {
            [headerView addSubview:_topMapItButton];
            [headerView addSubview:_topPlusButton];
            
            [_topMapItButton.leadingAnchor constraintEqualToAnchor:headerView.leadingAnchor].active = YES;
            [_topMapItButton.topAnchor constraintEqualToAnchor:headerView.topAnchor].active = YES;
            [_topMapItButton.bottomAnchor constraintEqualToAnchor:headerView.bottomAnchor].active = YES;
            [_topMapItButton.widthAnchor constraintEqualToConstant:_rowHeight].active = YES;
            
            [_topPlusButton.trailingAnchor constraintEqualToAnchor:headerView.trailingAnchor].active = YES;
            [_topPlusButton.topAnchor constraintEqualToAnchor:headerView.topAnchor].active = YES;
            [_topPlusButton.bottomAnchor constraintEqualToAnchor:headerView.bottomAnchor].active = YES;
            [_topPlusButton.widthAnchor constraintEqualToConstant:_rowHeight].active = YES;
            
            [headerLabel.leadingAnchor constraintEqualToAnchor:_topMapItButton.trailingAnchor].active = YES;
            [headerLabel.trailingAnchor constraintEqualToAnchor:_topPlusButton.leadingAnchor].active = YES;
            [headerLabel.topAnchor constraintEqualToAnchor:headerView.topAnchor].active = YES;
            [headerLabel.bottomAnchor constraintEqualToAnchor:headerView.bottomAnchor].active = YES;
        }
    }
    
    else
    {
        if (![headerView.subviews containsObject:_bottomPlusButton])
        {
            [headerView addSubview:_bottomMapItButton];
            [headerView addSubview:_bottomPlusButton];
            
            [_bottomMapItButton.leadingAnchor constraintEqualToAnchor:headerView.leadingAnchor].active = YES;
            [_bottomMapItButton.topAnchor constraintEqualToAnchor:headerView.topAnchor].active = YES;
            [_bottomMapItButton.bottomAnchor constraintEqualToAnchor:headerView.bottomAnchor].active = YES;
            [_bottomMapItButton.widthAnchor constraintEqualToConstant:_rowHeight].active = YES;
            
            [_bottomPlusButton.trailingAnchor constraintEqualToAnchor:headerView.trailingAnchor].active = YES;
            [_bottomPlusButton.topAnchor constraintEqualToAnchor:headerView.topAnchor].active = YES;
            [_bottomPlusButton.bottomAnchor constraintEqualToAnchor:headerView.bottomAnchor].active = YES;
            [_bottomPlusButton.widthAnchor constraintEqualToConstant:_rowHeight].active = YES;
            
            [headerLabel.leadingAnchor constraintEqualToAnchor:_bottomMapItButton.trailingAnchor].active = YES;
            [headerLabel.trailingAnchor constraintEqualToAnchor:_bottomPlusButton.leadingAnchor].active = YES;
            [headerLabel.topAnchor constraintEqualToAnchor:headerView.topAnchor].active = YES;
            [headerLabel.bottomAnchor constraintEqualToAnchor:headerView.bottomAnchor].active = YES;
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
    
    TableViewCellLabel *cellTextLabel = TableViewCellLabel.new;
    cellTextLabel.translatesAutoresizingMaskIntoConstraints = NO;
    cellTextLabel.adjustsFontSizeToFitWidth = YES;
    cellTextLabel.textColor = UIColor.blackColor;
    cellTextLabel.textAlignment = NSTextAlignmentLeft;
    cellTextLabel.font = _font;
    
    [cell.contentView addSubview:cellTextLabel];
    
    TableViewCellLabel *cellSubTextLabel = TableViewCellLabel.new;
    cellSubTextLabel.translatesAutoresizingMaskIntoConstraints = NO;
    cellSubTextLabel.adjustsFontSizeToFitWidth = YES;
    cellSubTextLabel.textColor = UIColor.blackColor;
    cellSubTextLabel.textAlignment = NSTextAlignmentLeft;
    cellSubTextLabel.font = _subFont;
    
    [cell.contentView addSubview:cellSubTextLabel];
    
    Destination *destination = nil;
    CGSize size = cell.contentView.frame.size;
    CGFloat margin = 5.0;
    
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
    
    
    TableViewCellButton *editName = TableViewCellButton.new;
    editName.translatesAutoresizingMaskIntoConstraints = NO;
    
    editName.tag = (indexPath.row + 100);
    
    if (tableView == _bottomTableView)
        editName.tag += 1000;
    
    [editName setImage:_editNameImage
              forState:UIControlStateNormal];
    
    [cell.contentView addSubview:editName];
    
    [editName addTarget:self
                 action:@selector(editNameTapped:)
       forControlEvents:UIControlEventTouchUpInside];
    
    TableViewCellButton *editOptions = TableViewCellButton.new;
    editOptions.translatesAutoresizingMaskIntoConstraints = NO;
    editOptions.tag = (indexPath.row + 400);
    
    if (tableView == _bottomTableView)
        editOptions.tag += 1000;
    
    [editOptions setImage:_editOptionsImage
                 forState:UIControlStateNormal];
    
    [cell.contentView addSubview:editOptions];
    
    [editOptions addTarget:self
                    action:@selector(editOptionsTapped:)
          forControlEvents:UIControlEventTouchUpInside];
    
    TableViewCellButton *mapIt = TableViewCellButton.new;
    mapIt.translatesAutoresizingMaskIntoConstraints = NO;
    mapIt.tag = (indexPath.row + 700);
    
    if (tableView == _bottomTableView)
        mapIt.tag += 1000;
    
    [mapIt setImage:_googleImage
           forState:UIControlStateNormal];
    
    [cell.contentView addSubview:mapIt];
    
    [mapIt addTarget:self
              action:@selector(mapItTapped:)
    forControlEvents:UIControlEventTouchUpInside];
    
    [mapIt.leadingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:(-margin - size.height)].active = YES;
    [mapIt.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-margin].active = YES;
    [mapIt.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:margin].active = YES;
    [mapIt.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor constant:-margin].active = YES;
    
    [editOptions.leadingAnchor constraintEqualToAnchor:mapIt.leadingAnchor constant:(-margin - size.height)].active = YES;
    [editOptions.trailingAnchor constraintEqualToAnchor:mapIt.leadingAnchor constant:-margin].active = YES;
    [editOptions.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:margin].active = YES;
    [editOptions.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor constant:-margin].active = YES;
    
    [editName.leadingAnchor constraintEqualToAnchor:editOptions.leadingAnchor constant:(-margin - size.height)].active = YES;
    [editName.trailingAnchor constraintEqualToAnchor:editOptions.leadingAnchor constant:-margin].active = YES;
    [editName.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:margin].active = YES;
    [editName.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor constant:-margin].active = YES;
    
    [cellTextLabel.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:(margin * 2.0)].active = YES;
    [cellTextLabel.trailingAnchor constraintEqualToAnchor:editName.leadingAnchor constant:-margin].active = YES;
    [cellTextLabel.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor].active = YES;
    [cellTextLabel.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor constant:(-size.height * 0.3)].active = YES;
    
    [cellSubTextLabel.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:(margin * 2.0)].active = YES;
    [cellSubTextLabel.trailingAnchor constraintEqualToAnchor:editName.leadingAnchor constant:-margin].active = YES;
    [cellSubTextLabel.topAnchor constraintEqualToAnchor:cellTextLabel.bottomAnchor].active = YES;
    [cellSubTextLabel.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor].active = YES;
    
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
        NSInteger destNum = destination.destinationID;
        
        Destinations *destinations = [[Destinations alloc] init];
        [destinations updateDestinationName:destNum newName:text];
        
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

- (void)individualMapItToggle:(UIButton *)button
{
    button.selected = !button.selected;
    CRAPI.sharedInstance.mapIndividualDest = button.selected;
}

- (void)groupMapItToggle:(UIButton *)button
{
    button.selected = !button.selected;
    CRAPI.sharedInstance.mapGroupDest = button.selected;
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