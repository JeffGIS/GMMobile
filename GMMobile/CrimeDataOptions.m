//  CrimeDataOptions.m
//  GMMobile

#import "CrimeDataOptions.h"
#import "CCodeLibrary/UserDefaults.h"
#import "CCodeLibrary/CRAPI.h"

@interface CrimeDataOptions ()

@property (weak, nonatomic) IBOutlet UIButton *dateRangeButton;
@property (weak, nonatomic) IBOutlet UIButton *areaTypeButton;
@property (weak, nonatomic) IBOutlet UIButton *legendButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) CGFloat rowHeight;
@property (nonatomic) UIFont *font;
@property (nonatomic) UIImageView *checkmarkView;
@property (nonatomic) NSArray *legends, *areaTypes;
@property NSInteger selectedAreaType, selectedLegend;

@end

@implementation CrimeDataOptions

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    _selectedAreaType = 0, _selectedLegend = 0;
    
    _areaTypes = @[@"Entire City", @"Neighborhoods", @"Wards", @"Precincts", @"Sectors",
                   @"Broadway Area", @"Downtown Improvement District", @"NorthWest L",
                   @"Midtown", @"Midtown (expanded)", @"Violent Crime Hotspots"];
    
    _legends = @[@"Part 1 Offenses", @"Part 2 Offenses", @"Arson", @"Assault", @"Burglary",
                 @"Force/NoForce Burglary of Dwelling", @"Graffiti", @"Narcotics", @"Prostitution",
                 @"Robbery", @"Sex Crimes", @"Vehicle Theft", @"Selected Theft", @"Theft From Auto",
                 @"Auto Theft/Recovery", @"Luring Related Offenses", @"Animal Related Offenses",
                 @"Bike Theft", @"Phone Theft", @"Crisis Related"];
    
    [self setupButton:_dateRangeButton];
    [self setupButton:_areaTypeButton];
    [self setupButton:_legendButton];
    
    [self setDateRangeButtonTextFromDate:CRAPI.sharedInstance.fromDate
                                  toDate:CRAPI.sharedInstance.toDate];
    
    [_areaTypeButton setTitle:_areaTypes[_selectedAreaType]
                     forState:UIControlStateNormal];
    
    [_legendButton setTitle:_legends[_selectedLegend]
                   forState:UIControlStateNormal];
    
    _legendButton.selected = YES;
    
    _checkmarkView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:
                                                         [NSBundle.mainBundle pathForResource:@"checkmark"
                                                                                       ofType:@"png"]]];
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        _checkmarkView.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
    
    else
        _checkmarkView.frame = CGRectMake(0.0, 0.0, 60.0, 60.0);
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        _rowHeight = 40.0;
        _font = [UIFont boldSystemFontOfSize:20.0];
    }
    
    else
    {
        _rowHeight = 60.0;
        _font = [UIFont boldSystemFontOfSize:30.0];
    }
    
    [self setupTableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [_tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setupButton:(UIButton *)button
{
    button.backgroundColor = UIColor.blackColor;
    
    [button setTitleColor:UIColor.whiteColor
                 forState:UIControlStateNormal];
    
    [button setTitleColor:UIColor.grayColor
                 forState:UIControlStateHighlighted];
    
    [button setTitleColor:UIColor.whiteColor
                 forState:UIControlStateSelected];
    
    [button setTitleColor:UIColor.grayColor
                 forState:(UIControlStateHighlighted|UIControlStateSelected)];
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        button.titleLabel.font = [UIFont boldSystemFontOfSize:22.0];
    
    else
        button.titleLabel.font = [UIFont boldSystemFontOfSize:32.0];
    
    button.titleLabel.numberOfLines = 2;
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    button.layer.cornerRadius = 10.0;
    button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    button.contentEdgeInsets = UIEdgeInsetsMake(2.0, 2.0, 2.0, 2.0);
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
    _tableView.delaysContentTouches = NO;
}

- (IBAction)dateRange:(UIButton *)sender
{
    NVDateRange *nvdr = [NVDateRange showDateRangeInView:self.view
                                                delegate:self
                                                fromDate:CRAPI.sharedInstance.fromDate
                                                  toDate:CRAPI.sharedInstance.toDate];
#pragma unused(nvdr)
}

- (void)dateRange:(NVDateRange *)dateRange
didReturnFromDate:(NSInteger)fromDate
           toDate:(NSInteger)toDate
{
    [dateRange hideDateRange:YES];
    
    CRAPI.sharedInstance.fromDate = fromDate;
    CRAPI.sharedInstance.toDate = toDate;
    
    [self setDateRangeButtonTextFromDate:fromDate
                                  toDate:toDate];
}

- (void)setDateRangeButtonTextFromDate:(NSInteger)fromDate
                                toDate:(NSInteger)toDate
{
    NSString *fromString = [self formattedDate:[NSDate dateWithTimeIntervalSince1970:fromDate]];
    NSString *toString = [self formattedDate:[NSDate dateWithTimeIntervalSince1970:toDate]];
    
    [_dateRangeButton setTitle:[NSString stringWithFormat:@"%@-%@", fromString, toString]
                      forState:UIControlStateNormal];
}

- (IBAction)areaType:(UIButton *)sender
{
    if (!_areaTypeButton.selected)
    {
        _areaTypeButton.selected = YES;
        _legendButton.selected = NO;
        [_tableView reloadData];
    }
}

- (IBAction)legend:(UIButton *)sender
{
    if (!_legendButton.selected)
    {
        _legendButton.selected = YES;
        _areaTypeButton.selected = NO;
        [_tableView reloadData];
    }
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    if (_areaTypeButton.selected)
        return _areaTypes.count;
    
    else
        return _legends.count;
}

- (UIView *)tableView:(UITableView *)tableView
viewForHeaderInSection:(NSInteger)section
{
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:
                            CGRectMake(0.0, 0.0, tableView.frame.size.width, _rowHeight)];
    
    headerLabel.font = _font;
    headerLabel.textColor = UIColor.whiteColor;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    
    if (_areaTypeButton.selected)
        headerLabel.text = @"Select Area Type";
    
    else
        headerLabel.text = @"Select Legend";
    
    UIView *headerView = [[UIView alloc] initWithFrame:
                          CGRectMake(0.0, 0.0, tableView.frame.size.width, _rowHeight)];
    
    [headerView addSubview:headerLabel];
    headerView.backgroundColor = UIColor.blackColor;
    
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
    
    if (_areaTypeButton.selected)
    {
        cell.textLabel.text = _areaTypes[indexPath.row];
        
        if (indexPath.row == _selectedAreaType)
            cell.accessoryView = _checkmarkView;
        
        else
            cell.accessoryView = nil;
    }
    
    else
    {
        cell.textLabel.text = _legends[indexPath.row];
        
        if (indexPath.row == _selectedLegend)
            cell.accessoryView = _checkmarkView;
        
        else
            cell.accessoryView = nil;
    }
    
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.textColor = UIColor.blackColor;
    cell.userInteractionEnabled = YES;
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.font = _font;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_areaTypeButton.selected)
    {
        _selectedAreaType = indexPath.row;
        
        [_areaTypeButton setTitle:_areaTypes[_selectedAreaType]
                         forState:UIControlStateNormal];
    }
    
    else
    {
        _selectedLegend = indexPath.row;
        
        [_legendButton setTitle:_legends[_selectedLegend]
                       forState:UIControlStateNormal];
    }
    
    [_tableView reloadData];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    [_tableView reloadData];
}

- (NSString *)formattedDate:(NSDate *)date
{
    NSString *formattedDate = @"";
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"MM/dd/YYYY";
    formattedDate = [dateFormatter stringFromDate:date];
    
    return formattedDate;
}

@end