//  CrimeDataOptions.m
//  GMMobile

#import "CrimeDataOptions.h"
#import "CCodeLibrary/UserDefaults.h"
#import "CCodeLibrary/CRAPI.h"
#import "CCodeLibrary/NVAlertView.h"

@interface CrimeDataOptions ()

@property (weak, nonatomic) IBOutlet UIButton *dateRangeButton;
@property (weak, nonatomic) IBOutlet UIButton *areaTypeButton;
@property (weak, nonatomic) IBOutlet UIButton *legendButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) CGFloat rowHeight, headerHeight, cornerRadius;
@property (nonatomic) UIFont *font, *headerFont;
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
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        _rowHeight = 36.0;
        _headerHeight = 24.0;
        _cornerRadius = 4.0;
        
        _font = [UIFont fontWithName:@"CourierNewPS-BoldMT"
                                size:14.0];
        
        _headerFont = [UIFont boldSystemFontOfSize:18.0];
    }
    
    else
    {
        _rowHeight = 52.0;
        _headerHeight = 40.0;
        _cornerRadius = 10.0;
        
        _font = [UIFont fontWithName:@"CourierNewPS-BoldMT"
                                size:24.0];
        
        _headerFont = [UIFont boldSystemFontOfSize:28.0];
    }
    
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
    button.layer.cornerRadius = _cornerRadius;
    button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    button.contentEdgeInsets = UIEdgeInsetsMake(2.0, 2.0, 2.0, 2.0);
}

- (void)setupTableView
{
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = UIColor.whiteColor;
    _tableView.bounces = NO;
    _tableView.layer.borderColor = UIColor.blackColor.CGColor;
    _tableView.layer.borderWidth = (_cornerRadius / 4.0);
    _tableView.layer.cornerRadius = _cornerRadius;
    _tableView.rowHeight = _rowHeight;
    _tableView.sectionHeaderHeight = _headerHeight;
    _tableView.delaysContentTouches = NO;
    _tableView.separatorColor = UIColor.clearColor;
    _tableView.separatorInset = UIEdgeInsetsZero;
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
    CGFloat margin = 40.0;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        margin = 16.0;
        
        if (UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeLeft ||
            UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeRight)
        {
            margin = 12.0;
        }
    }
    
    CGFloat tvWidth = (self.view.frame.size.width - margin);
    
    UIView *headerView = [[UIView alloc] initWithFrame:
                          CGRectMake(0.0, 0.0, tvWidth, _headerHeight)];
    
    headerView.backgroundColor = UIColor.blackColor;
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:headerView.frame];
    headerLabel.font = _headerFont;
    headerLabel.textColor = UIColor.whiteColor;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    
    if (_areaTypeButton.selected)
        headerLabel.text = @"Select Area Type";
    
    else
        headerLabel.text = @"Select Legend";
    
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
    
    cell.layer.borderColor = UIColor.blackColor.CGColor;
    cell.layer.borderWidth = 0.5;
    
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
    
    for (NVAlertView *alert in self.view.subviews)
    {
        if ([alert isKindOfClass:NVAlertView.class])
        {
            [self.view bringSubviewToFront:alert];
            [alert willRotateWithDuration:duration];
        }
    }
}

- (NSString *)formattedDate:(NSDate *)date
{
    NSString *formattedDate = @"";
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"MM/dd/yyyy";
    formattedDate = [dateFormatter stringFromDate:date];
    
    return formattedDate;
}

@end