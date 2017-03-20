//  CrimeDataOptions.m
//  GMMobile

#import "CrimeDataOptions.h"
#import "CCodeLibrary/UserDefaults.h"
#import "CCodeLibrary/CRAPI.h"
#import "CCodeLibrary/NVAlertView.h"
#import "ConfigurationControl.h"
#import "FindBoundariesViewController.h"

@interface CrimeDataOptions () <FindBoundsViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *dateRangeButton;
@property (weak, nonatomic) IBOutlet UIButton *areaTypeButton;
@property (weak, nonatomic) IBOutlet UIButton *legendButton;
@property (weak, nonatomic) IBOutlet UIButton *modeButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *multipleOffenseButton;
@property (weak, nonatomic) IBOutlet UIButton *attemptOptionButton;

@property (nonatomic) CGFloat rowHeight, headerHeight, cornerRadius;
@property (nonatomic) UIFont *font, *headerFont;
@property (nonatomic) UIImageView *checkmarkView;
@property (nonatomic, copy) NSArray *legends, *modeTypes, *pinModes, *hotspotModes, *choroplethModes, *modes;
@property (nonatomic, copy) NSArray *multipleOffenseOptions, *adjustmentOptions, *currentArray;
@property (nonatomic, copy) NSString *selectedAreaType, *selectedLegend, *selectedMode;
@property (nonatomic, copy) NSString *selectedMultipleOffenseOption, *selectedAdjustmentOption;
@property NVMapModeType selectedModeType;

@end

@implementation CrimeDataOptions

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        _rowHeight = 36.0;
        _headerHeight = 24.0;
        _cornerRadius = 4.0;
        _font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:14.0];
        _headerFont = [UIFont boldSystemFontOfSize:18.0];
    }
    
    else
    {
        _rowHeight = 52.0;
        _headerHeight = 40.0;
        _cornerRadius = 10.0;
        _font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:24.0];
        _headerFont = [UIFont boldSystemFontOfSize:28.0];
    }
    
    _legends = @[@"Part 1 Offenses", @"Part 2 Offenses", @"Arson", @"Assault", @"Burglary",
                 @"Force/NoForce Burglary of Dwelling", @"Graffiti", @"Narcotics", @"Prostitution",
                 @"Robbery", @"Sex Crimes", @"Vehicle Theft", @"Selected Theft", @"Theft From Auto",
                 @"Auto Theft/Recovery", @"Luring Related Offenses", @"Animal Related Offenses",
                 @"Bike Theft", @"Phone Theft", @"Crisis Related"];
    
    _modeTypes = @[@"PIN Map", @"Hotspot Map", @"Choropleth Map"];
    _pinModes = @[@"Basic PIN Map", @"PIN Map for Month with Yearly Totals", @"PIN Map for Month with Monthly Totals"];
    
    _hotspotModes = @[@"Basic Hotspot Map", @"Hotspot Map for Month with Yearly Compare",
                      @"Hotspot Map for Month with Monthly Compare", @"Hotspot Map for Week with Weekly Compare"];
    
    _choroplethModes = @[@"Choropleth Map for Precincts", @"Choropleth Map for Wards",
                         @"Basic Choropleth Map for Sectors", @"Choropleth Map for Neighborhoods",
                        @"Choropleth Map For Census Tracts",@"Choropleth Map for Block Groups",@"Choropleth Map for Blocks"];
    
    _multipleOffenseOptions = @[@"Most Serious Offense per Incident", @"All Offenses"];
    _adjustmentOptions = @[@"None", @"Population", @"Housing Units"];
    
    _modes = @[_pinModes, _hotspotModes, _choroplethModes];
    _currentArray = _modeTypes;
    
    NSString *defaultSelectedLegend = [UserDefaults.defaults stringForKey:@"SelectedLegend"];
    
    if (defaultSelectedLegend && defaultSelectedLegend.length)
        _selectedLegend = defaultSelectedLegend;
    
    else
        _selectedLegend = _legends[0];
    
    NSString *defaultSelectedMode = [UserDefaults.defaults stringForKey:@"SelectedMode"];
    
    if (defaultSelectedMode && defaultSelectedMode.length)
        _selectedMode = defaultSelectedMode;
    
    else
        _selectedMode = _selectedMode = _modes[0][0];
    
    NSString *defaultSelectedMultipleOffenseOption = [UserDefaults.defaults stringForKey:@"SelectedMultipleOffenseOption"];
    
    if (defaultSelectedMultipleOffenseOption && defaultSelectedMultipleOffenseOption.length)
        _selectedMultipleOffenseOption = defaultSelectedMultipleOffenseOption;
    
    else
        _selectedMultipleOffenseOption = _multipleOffenseOptions[0];
    
    NSString *defaultSelectedAdjustmentOption = [UserDefaults.defaults stringForKey:@"SelectedAdjustmentOption"];
    
    if (defaultSelectedAdjustmentOption && defaultSelectedAdjustmentOption.length)
        _selectedAdjustmentOption = defaultSelectedAdjustmentOption;
    
    else
        _selectedAdjustmentOption = _adjustmentOptions[0];
    
    _modeButton.selected = YES;
    _areaTypeButton.selected = NO;
    _legendButton.selected = NO;
    _dateRangeButton.selected = NO;
    _multipleOffenseButton.selected = NO;
    _attemptOptionButton.selected = NO;
    _attemptOptionButton.enabled = NO;
    
    [self setupButton:_dateRangeButton];
    [self setupButton:_areaTypeButton];
    [self setupButton:_legendButton];
    [self setupButton:_modeButton];
    [self setupButton:_multipleOffenseButton];
    [self setupButton:_attemptOptionButton];
    
    [self setDateRangeButtonTextFromDate:CRAPI.sharedInstance.fromDate
                                  toDate:CRAPI.sharedInstance.toDate];
    
    [_legendButton setTitle:[NSString stringWithFormat:@"Legend:%@", _selectedLegend]
                   forState:UIControlStateNormal];
    
    [_modeButton setTitle:[NSString stringWithFormat:@"Mode:%@", _selectedMode]
                 forState:UIControlStateNormal];
    
    [_multipleOffenseButton setTitle:[NSString stringWithFormat:@"Multiple Offenses:%@", _selectedMultipleOffenseOption]
                            forState:UIControlStateNormal];
    
    [_attemptOptionButton setTitle:[NSString stringWithFormat:@"Adjustment Option:%@", _selectedAdjustmentOption]
                          forState:UIControlStateNormal];
    
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
    
    [_areaTypeButton setTitle:[NSString stringWithFormat:@"Bounding Area:%@ (%@)",
                               CRAPI.sharedInstance.currentOverallBoundaryName,
                               CRAPI.sharedInstance.currentOverallBoundaryType]
                     forState:UIControlStateNormal];
    
    [_tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setupButton:(UIButton *)button
{
    [self updateButton:button];
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        button.titleLabel.font = [UIFont boldSystemFontOfSize:22.0];
    
    else
        button.titleLabel.font = [UIFont boldSystemFontOfSize:32.0];
    
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [button setTitleColor:UIColor.grayColor forState:(UIControlStateHighlighted|UIControlStateSelected)];
    [button setTitleColor:UIColor.grayColor forState:UIControlStateHighlighted];
    [button setTitleColor:UIColor.blackColor forState:UIControlStateSelected];
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    button.layer.cornerRadius = _cornerRadius;
    button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    button.contentEdgeInsets = UIEdgeInsetsMake(2.0, 2.0, 2.0, 2.0);
}

- (void)updateButton:(UIButton *)button
{
    if (button.selected)
        button.backgroundColor = UIColor.whiteColor;
    
    else
        button.backgroundColor = UIColor.blackColor;
    
    if (!button.enabled)
        button.alpha = 0.4;
    
    else
        button.alpha = 1.0;
}

- (void)setupTableView
{
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = UIColor.grayColor;
    _tableView.bounces = YES;
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
    
    [_dateRangeButton setTitle:[NSString stringWithFormat:@"Date Range:%@-%@", fromString, toString]
                      forState:UIControlStateNormal];
}

- (void)updateButtons
{
    [self updateButton:_areaTypeButton];
    [self updateButton:_legendButton];
    [self updateButton:_modeButton];
    [self updateButton:_dateRangeButton];
    [self updateButton:_multipleOffenseButton];
    [self updateButton:_attemptOptionButton];
}

- (IBAction)legend:(UIButton *)sender
{
    if (!_legendButton.selected)
    {
        _legendButton.selected = YES;
        _areaTypeButton.selected = NO;
        _modeButton.selected = NO;
        _multipleOffenseButton.selected = NO;
        _attemptOptionButton.selected = NO;
        _currentArray = _legends;
        
        [self updateButtons];
        [_tableView reloadData];
    }
}

- (IBAction)mode:(id)sender
{
    if (!_modeButton.selected)
    {
        _modeButton.selected = YES;
        _areaTypeButton.selected = NO;
        _legendButton.selected = NO;
        _multipleOffenseButton.selected = NO;
        _attemptOptionButton.selected = NO;
        _currentArray = _modeTypes;
        
        [self updateButtons];
        [_tableView reloadData];
    }
    
    else if (_currentArray != _modeTypes)
    {
        _currentArray = _modeTypes;
        [_tableView reloadData];
    }
}

- (IBAction)multipleOffense:(id)sender
{
    if (!_multipleOffenseButton.selected)
    {
        _multipleOffenseButton.selected = YES;
        _legendButton.selected = NO;
        _areaTypeButton.selected = NO;
        _modeButton.selected = NO;
        _attemptOptionButton.selected = NO;
        _currentArray = _multipleOffenseOptions;
        
        [self updateButtons];
        [_tableView reloadData];
    }
}

- (IBAction)attemptOption:(id)sender
{
    if (!_attemptOptionButton.selected)
    {
        _attemptOptionButton.selected = YES;
        _multipleOffenseButton.selected = NO;
        _legendButton.selected = NO;
        _areaTypeButton.selected = NO;
        _modeButton.selected = NO;
        _currentArray = _adjustmentOptions;
        
        [self updateButtons];
        [_tableView reloadData];
    }
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return _currentArray.count;
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
    
    headerView.backgroundColor = UserDefaults.defaults.green;
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:headerView.frame];
    headerLabel.font = _headerFont;
    headerLabel.textColor = UIColor.blackColor;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    
    if (_currentArray == _legends)
        headerLabel.text = @"Select Legend";
    
    else if (_currentArray == _modeTypes)
        headerLabel.text = @"Select Mode Type";
    
    else if (_currentArray == _multipleOffenseOptions)
        headerLabel.text = @"Select Multiple Offense Option";
    
    else if (_currentArray == _adjustmentOptions)
        headerLabel.text = @"Select Attempt Option";
    
    else
        headerLabel.text = @"Select Mode";
    
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
    
    if (_currentArray == _modeTypes)
    {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.accessoryView = nil;
    }
    
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        if ([_currentArray[indexPath.row] isEqualToString:_selectedLegend] ||
            [_currentArray[indexPath.row] isEqualToString:_selectedMode] ||
            [_currentArray[indexPath.row] isEqualToString:_selectedMultipleOffenseOption] ||
            [_currentArray[indexPath.row] isEqualToString:_selectedAdjustmentOption])
        {
            cell.accessoryView = _checkmarkView;
        }
        
        else
            cell.accessoryView = nil;
    }
    
    cell.textLabel.text = _currentArray[indexPath.row];
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
    if (_currentArray == _legends)
    {
        _selectedLegend = _legends[indexPath.row];
        [UserDefaults.defaults saveString:_selectedLegend forKey:@"SelectedLegend"];
        
        [_legendButton setTitle:[NSString stringWithFormat:@"Legend:%@", _selectedLegend]
                       forState:UIControlStateNormal];
    }
    
    else if (_currentArray == _modeTypes)
    {
        _currentArray = _modes[indexPath.row];
        _selectedModeType = (NVMapModeType)indexPath.row;
        
        if (![_modes[_selectedModeType] containsObject:_selectedMode])
        {
            _selectedMode = _modes[_selectedModeType][0];
            [UserDefaults.defaults saveString:_selectedMode forKey:@"SelectedMode"];
        }
        
        [self updateModes];
    }
    
    else if (_currentArray == _multipleOffenseOptions)
    {
        _selectedMultipleOffenseOption = _multipleOffenseOptions[indexPath.row];
        [UserDefaults.defaults saveString:_selectedMultipleOffenseOption forKey:@"SelectedMultipleOffenseOptions"];
        
        [_multipleOffenseButton setTitle:[NSString stringWithFormat:@"Multiple Offenses:%@", _selectedMultipleOffenseOption]
                                forState:UIControlStateNormal];
        
        ConfigurationControl.sharedInstance.wantAllCrimes = [_selectedMultipleOffenseOption isEqualToString:@"All Offenses"];
        [UserDefaults.defaults saveBool:ConfigurationControl.sharedInstance.wantAllCrimes forKey:@"WantAllCrimes"];
    }
    
    else if (_currentArray == _adjustmentOptions)
    {
        _selectedAdjustmentOption = _adjustmentOptions[indexPath.row];
        [UserDefaults.defaults saveString:_selectedAdjustmentOption forKey:@"SelectedAdjustmentOption"];
        
        [_attemptOptionButton setTitle:[NSString stringWithFormat:@"Adjustment Option:%@", _selectedAdjustmentOption]
                              forState:UIControlStateNormal];
        
        ConfigurationControl.sharedInstance.adjustCrimeOption = (int)indexPath.row;
        [UserDefaults.defaults saveInteger:ConfigurationControl.sharedInstance.adjustCrimeOption forKey:@"AdjustCrimeOption"];
        ConfigurationControl.sharedInstance.adjustCrimeArea = @"BLOCK";
        [UserDefaults.defaults saveString:ConfigurationControl.sharedInstance.adjustCrimeArea forKey:@"AdjustCrimeArea"];
    }
    
    else
    {
        _selectedMode = _modes[_selectedModeType][indexPath.row];
        [UserDefaults.defaults saveString:_selectedMode forKey:@"SelectedMode"];
        [self updateModes];
        _currentArray = _modeTypes;
    }

    [_tableView reloadData];
}

- (void)updateModes
{
    _attemptOptionButton.enabled = (_selectedModeType == NVMapModeTypeChoropleth);
    [self updateButton:_attemptOptionButton];
    
    NSString *uppercaseMode = _selectedMode.uppercaseString;
    CRAPI.sharedInstance.crimeAdjustValueArea = nil;
    
    if ([uppercaseMode containsString:@"PIN"])
        CRAPI.sharedInstance.crimeMode = PINMAP;
    
    else if ([uppercaseMode containsString:@"CHOROPLETH"])
        CRAPI.sharedInstance.crimeMode = CHOROPLETH;
    
    else if ([uppercaseMode containsString:@"HOTSPOT"])
        CRAPI.sharedInstance.crimeMode = HOTSPOT;
    
    [UserDefaults.defaults saveNSInteger:CRAPI.sharedInstance.crimeMode forKey:@"CrimeMode"];
    
    if ([uppercaseMode containsString:@"PRECINCTS"])
        CRAPI.sharedInstance.crimeTarget = @"Minneapolis Precincts";
    
    else if ([uppercaseMode containsString:@"NEIGHBORHOODS"])
        CRAPI.sharedInstance.crimeTarget = @"Minneapolis Neighborhoods";
    
    else if ([uppercaseMode containsString:@"WARDS"])
        CRAPI.sharedInstance.crimeTarget = @"Minneapolis Wards";
    
    else if ([uppercaseMode containsString:@"SECTORS"])
        CRAPI.sharedInstance.crimeTarget = @"Minneapolis Sectors";
    
    else if ([uppercaseMode containsString:@"BLOCK GROUPS"])
        CRAPI.sharedInstance.crimeTarget = @"BLOCKGROUP";
    
    else if ([uppercaseMode containsString:@"BLOCK"])
        CRAPI.sharedInstance.crimeTarget = @"BLOCK";
    
    else if ([uppercaseMode containsString:@"CENSUS TRACT"])
        CRAPI.sharedInstance.crimeTarget = @"TRACT";
    
    [UserDefaults.defaults saveString:CRAPI.sharedInstance.crimeTarget forKey:@"CrimeTarget"];
    
    if ([uppercaseMode containsString:@"HOUSING UNIT"])
    {
        CRAPI.sharedInstance.crimeAdjustValue = @"HUTOTAL";
        CRAPI.sharedInstance.crimeAdjustValueArea = @"TRACT";
        [UserDefaults.defaults saveString:CRAPI.sharedInstance.crimeAdjustValue forKey:@"CrimeAdjustValue"];
        [UserDefaults.defaults saveString:CRAPI.sharedInstance.crimeAdjustValueArea forKey:@"CrimeAdjustValueArea"];
    }
    
    [_modeButton setTitle:[NSString stringWithFormat:@"Mode:%@", _selectedMode]
                 forState:UIControlStateNormal];
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
    dateFormatter.dateFormat = @"MM/dd/yyyy";
    formattedDate = [dateFormatter stringFromDate:date];
    
    return formattedDate;
}

- (IBAction)selectBounds:(id)sender
{
    FindBoundariesViewController *findBounds = FindBoundariesViewController.new;
    findBounds.delegate = self;
    
    findBounds.otherAreas = @[@"Entire City", @"Broadway Area", @"Downtown Improvement District", @"NorthWest L",
                              @"Midtown", @"Midtown (expanded)", @"Violent Crime Hotspots"];
    
    [self presentViewController:findBounds animated:YES completion:nil];
}

- (void)findBoundsViewController:(FindBoundariesViewController *)findBounds
                 didSelectBounds:(NSString *)bounds
                            type:(NSString *)type
                           refno:(int)refno
{
    [findBounds dismissViewControllerAnimated:YES
                                   completion:nil];
    
    CRAPI.sharedInstance.GMMSetting = GMMSettingBoundaries;
    
    if (bounds && ![bounds isEqualToString:@""])
    {
        CRAPI.sharedInstance.currentOverallBoundaryRefno = refno;
        [UserDefaults.defaults saveInteger:refno forKey:@"CurrentOverallBoundaryRefno"];
        CRAPI.sharedInstance.currentOverallBoundaryName = bounds;
        [UserDefaults.defaults saveString:bounds forKey:@"CurrentOverallBoundaryName"];
        CRAPI.sharedInstance.currentOverallBoundaryType = type;
        [UserDefaults.defaults saveString:type forKey:@"CurrentOverallBoundaryType"];
        
        [_areaTypeButton setTitle:[NSString stringWithFormat:@"Bounding Area:%@ (%@)",
                                   CRAPI.sharedInstance.currentOverallBoundaryName,
                                   CRAPI.sharedInstance.currentOverallBoundaryType]
                         forState:UIControlStateNormal];
    }
    
    else
        self.tabBarController.selectedIndex = 0;
}

@end
