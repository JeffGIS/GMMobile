//  CrimeDataOptions.m
//  GMMobile

#include "CCodeLibrary/shr.h"
#import "CrimeDataOptions.h"
#import "CCodeLibrary/UserDefaults.h"
#import "CCodeLibrary/CRAPI.h"
#import "CCodeLibrary/NVAlertView.h"
#import "ConfigurationControl.h"
#import "FindBoundariesViewController.h"

@interface CrimeDataOptions () <FindBoundsViewControllerDelegate>

@property (nonatomic) UIButton *dateRangeButton, *boundingAreaButton, *legendButton;
@property (nonatomic) UIButton *modeButton, *multipleOffenseButton;
@property (nonatomic) UIButton *adjustmentOptionButton, *compareOptionButton;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) CGFloat rowHeight, headerHeight, margin, innerMargin, borderWidth;
@property (nonatomic) UIFont *font, *headerFont;
@property (nonatomic) UIImageView *checkmarkView;
@property (nonatomic, copy) NSArray *legends, *modeTypes, *pinModes, *hotspotModes, *hotspotVideoModes, *choroplethModes, *linegraphModes, *modes;
@property (nonatomic, copy) NSArray *multipleOffenseOptions, *adjustmentOptions, *currentArray, *compareOptions;
@property (nonatomic, copy) NSString *selectedAreaType, *selectedLegend, *selectedMode;
@property (nonatomic, copy) NSString *selectedMultipleOffenseOption, *selectedAdjustmentOption, *selectedCompareOption;
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
        _borderWidth = 1.0;
        _margin = _innerMargin = 4.0;
        _font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:14.0];
        _headerFont = [UIFont boldSystemFontOfSize:18.0];
    }
    
    else
    {
        _rowHeight = 52.0;
        _headerHeight = 40.0;
        _borderWidth = 2.5;
        _margin = 12.0;
        _innerMargin = 8.0;
        _font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:24.0];
        _headerFont = [UIFont boldSystemFontOfSize:28.0];
    }
    
    _dateRangeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _boundingAreaButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _legendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _modeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _multipleOffenseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _adjustmentOptionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _compareOptionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _tableView = UITableView.new;
    
    _legends = @[@"Part 1 Offenses", @"Part 2 Offenses", @"Violent Crimes", @"Assault", @"Domestic Assault", @"Burglary", @"Robbery",
                 @"Motor Vehicle Theft", @"Selected Theft", @"Theft From Auto", @"Crime Index"];
    
    _modeTypes = @[@"PIN Map", @"Hotspot Map", @"Hotspot Video", @"Choropleth Map", @"Line Graph"];
    _pinModes = @[@"Basic PIN Map", @"PIN Map for Month with Yearly Totals", @"PIN Map for Month with Monthly Totals"];
    
//    _hotspotModes = @[@"Basic Hotspot Map", @"Hotspot Map for Month with Yearly Compare",
//                      @"Hotspot Map for Month with Monthly Compare", @"Hotspot Map for Week with Weekly Compare"];
    
    _hotspotModes = @[@"Basic Hotspot Map"];

    _hotspotVideoModes = @[@"Hotspot Video by Quadweeks",@"Hotspot Video by Day of Week",@"Hotspot Video by Hour in Day"];

    _choroplethModes = @[@"Choropleth Map for Precincts", @"Choropleth Map for Wards",
                         @"Choropleth Map for Sectors", @"Choropleth Map for Neighborhoods",
                         @"Choropleth Map For Census Tracts",@"Choropleth Map for Block Groups",@"Choropleth Map for Blocks"];
    
    _linegraphModes = @[@"Line Graph for City",@"Line Graph for Precincts", @"Line Graph for Wards",
                         @"Line Graph for Sectors", @"Line Graph for Neighborhoods",
                         @"Line Graph For Census Tracts",@"Line Graph for Block Groups",@"Line Graph for Blocks"];
    
    _multipleOffenseOptions = @[@"Most Serious Offense per Incident", @"All Offenses"];
    
    _adjustmentOptions = @[@"None", @"Population", @"Housing Units", @"Overdue as Percent of Average Frequency",
                           @"Overdue as Percent of STDV of Frequency"];
    
    _compareOptions = @[@"Raw", @"Count Corrected", @"Time Corrected"];
    _modes = @[_pinModes, _hotspotModes, _hotspotVideoModes, _choroplethModes, _linegraphModes];
    _currentArray = _modeTypes;
    
    NSString *defaultOption = [UserDefaults.defaults stringForKey:@"SelectedLegend"];
    
    if (defaultOption && defaultOption.length)
        _selectedLegend = defaultOption;
    
    else
        _selectedLegend = _legends[0];
    
    defaultOption = [UserDefaults.defaults stringForKey:@"SelectedMode"];
    
    if (defaultOption && defaultOption.length)
        _selectedMode = defaultOption;
    
    else
        _selectedMode = _selectedMode = _modes[0][0];
    
    defaultOption = [UserDefaults.defaults stringForKey:@"SelectedMultipleOffenseOption"];
    
    if (defaultOption && defaultOption.length)
        _selectedMultipleOffenseOption = defaultOption;
    
    else
        _selectedMultipleOffenseOption = _multipleOffenseOptions[0];
    
    defaultOption = [UserDefaults.defaults stringForKey:@"SelectedAdjustmentOption"];
    
    if (defaultOption && defaultOption.length)
        _selectedAdjustmentOption = defaultOption;
    
    else
        _selectedAdjustmentOption = _adjustmentOptions[0];
    
    defaultOption = [UserDefaults.defaults stringForKey:@"SelectedCompareOption"];
    
    if (defaultOption && defaultOption.length)
        _selectedCompareOption = defaultOption;
    
    else
        _selectedCompareOption = _compareOptions[0];
    
    _selectedModeType = [UserDefaults.defaults integerForKey:@"SelectedModeType"];
    
    _modeButton.selected = YES;
    _boundingAreaButton.selected = NO;
    _legendButton.selected = NO;
    _dateRangeButton.selected = NO;
    _multipleOffenseButton.selected = NO;
    _adjustmentOptionButton.selected = NO;
    _compareOptionButton.selected = NO;
    _adjustmentOptionButton.enabled = (_selectedModeType == NVMapModeTypeChoropleth);
    _compareOptionButton.enabled = (_selectedModeType != NVMapModeTypePIN);
    
    [self setupButton:_dateRangeButton action:@selector(dateRangeTapped:)];
    [self setupButton:_boundingAreaButton action:@selector(areaTypeTapped:)];
    [self setupButton:_legendButton action:@selector(legendTapped:)];
    [self setupButton:_modeButton action:@selector(modeTapped:)];
    [self setupButton:_multipleOffenseButton action:@selector(multipleOffenseTapped:)];
    [self setupButton:_adjustmentOptionButton action:@selector(adjustmentOptionTapped:)];
    [self setupButton:_compareOptionButton action:@selector(compareOptionTapped:)];
    
    [self setDateRangeButtonTextFromDate:CRAPI.sharedInstance.fromDate
                                  toDate:CRAPI.sharedInstance.toDate];
    
    [_legendButton setTitle:[NSString stringWithFormat:@"Legend:%@", _selectedLegend]
                   forState:UIControlStateNormal];
    
    [_modeButton setTitle:[NSString stringWithFormat:@"Mode:%@", _selectedMode]
                 forState:UIControlStateNormal];
    
    [_multipleOffenseButton setTitle:[NSString stringWithFormat:@"Multiple Offenses:%@", _selectedMultipleOffenseOption]
                            forState:UIControlStateNormal];
    
    [_adjustmentOptionButton setTitle:[NSString stringWithFormat:@"Adjustment Option:%@", _selectedAdjustmentOption]
                             forState:UIControlStateNormal];
    
    [_compareOptionButton setTitle:[NSString stringWithFormat:@"Data Compare Option:%@", _selectedCompareOption]
                          forState:UIControlStateNormal];
    
    _checkmarkView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:
                                                         [NSBundle.mainBundle pathForResource:@"checkmark"
                                                                                       ofType:@"png"]]];
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        _checkmarkView.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
    
    else
        _checkmarkView.frame = CGRectMake(0.0, 0.0, 60.0, 60.0);
    
    [self setupTableView];
    [self setupConstraintsForOrientation:UIApplication.sharedApplication.statusBarOrientation];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [_boundingAreaButton setTitle:[NSString stringWithFormat:@"Bounding Area:%@ (%@)",
                                   CRAPI.sharedInstance.currentOverallBoundaryName,
                                   CRAPI.sharedInstance.currentOverallBoundaryType]
                        forState:UIControlStateNormal];
    
    [_tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)setupButton:(UIButton *)button
             action:(SEL)action
{
    button.translatesAutoresizingMaskIntoConstraints = NO;
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
    button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    button.contentEdgeInsets = UIEdgeInsetsMake(2.0, 2.0, 2.0, 2.0);
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)setupConstraintsForOrientation:(UIInterfaceOrientation)orientation
{
    [_dateRangeButton constrainTopToAnchor:self.view.topAnchor constant:_margin];
    [_dateRangeButton constrainLeadingToAnchor:self.view.leadingAnchor constant:_margin];
    [_dateRangeButton constrainTrailingToAnchor:self.view.trailingAnchor constant:-_margin];
    [_boundingAreaButton constrainTopToAnchor:_dateRangeButton.bottomAnchor constant:_innerMargin];
    [_boundingAreaButton constrainLeadingToAnchor:_dateRangeButton.leadingAnchor];
    [_legendButton constrainTrailingToAnchor:_dateRangeButton.trailingAnchor];
    [_modeButton constrainLeadingToAnchor:_dateRangeButton.leadingAnchor];
    [_multipleOffenseButton constrainTrailingToAnchor:_dateRangeButton.trailingAnchor];
    [_adjustmentOptionButton constrainLeadingToAnchor:_dateRangeButton.leadingAnchor];
    [_compareOptionButton constrainTrailingToAnchor:_dateRangeButton.trailingAnchor];
    [_boundingAreaButton constrainHeightToAnchor:_dateRangeButton.heightAnchor];
    [_legendButton constrainHeightToAnchor:_dateRangeButton.heightAnchor];
    [_modeButton constrainHeightToAnchor:_dateRangeButton.heightAnchor];
    [_multipleOffenseButton constrainHeightToAnchor:_dateRangeButton.heightAnchor];
    [_adjustmentOptionButton constrainHeightToAnchor:_dateRangeButton.heightAnchor];
    [_compareOptionButton constrainHeightToAnchor:_dateRangeButton.heightAnchor];
    [_tableView constrainTopToAnchor:_compareOptionButton.bottomAnchor constant:_margin];
    [_tableView constrainLeadingToAnchor:_dateRangeButton.leadingAnchor];
    [_tableView constrainTrailingToAnchor:_dateRangeButton.trailingAnchor];
    [_tableView constrainBottomToAnchor:self.view.bottomAnchor constant:-_margin];
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad || orientation == UIInterfaceOrientationPortrait)
    {
        [_boundingAreaButton constrainTrailingToAnchor:_dateRangeButton.trailingAnchor];
        [_legendButton constrainTopToAnchor:_boundingAreaButton.bottomAnchor constant:_innerMargin];
        [_legendButton constrainLeadingToAnchor:_dateRangeButton.leadingAnchor];
        [_modeButton constrainTopToAnchor:_legendButton.bottomAnchor constant:_innerMargin];
        [_modeButton constrainTrailingToAnchor:_dateRangeButton.trailingAnchor];
        [_multipleOffenseButton constrainTopToAnchor:_modeButton.bottomAnchor constant:_innerMargin];
        [_multipleOffenseButton constrainLeadingToAnchor:_dateRangeButton.leadingAnchor];
        [_adjustmentOptionButton constrainTopToAnchor:_multipleOffenseButton.bottomAnchor constant:_innerMargin];
        [_adjustmentOptionButton constrainTrailingToAnchor:_dateRangeButton.trailingAnchor];
        [_compareOptionButton constrainTopToAnchor:_adjustmentOptionButton.bottomAnchor constant:_innerMargin];
        [_compareOptionButton constrainLeadingToAnchor:_dateRangeButton.leadingAnchor];
        [_tableView constrainHeightToAnchor:_dateRangeButton.heightAnchor multiplier:8.0];
    }
    
    else
    {
        [_legendButton constrainTopToAnchor:_boundingAreaButton.topAnchor];
        [_legendButton constrainLeadingToAnchor:_boundingAreaButton.trailingAnchor constant:_innerMargin];
        [_modeButton constrainTopToAnchor:_boundingAreaButton.bottomAnchor constant:_innerMargin];
        [_multipleOffenseButton constrainTopToAnchor:_modeButton.topAnchor];
        [_multipleOffenseButton constrainLeadingToAnchor:_modeButton.trailingAnchor constant:_innerMargin];
        [_compareOptionButton constrainLeadingToAnchor:_adjustmentOptionButton.trailingAnchor constant:_innerMargin];
        [_boundingAreaButton constrainWidthToAnchor:_legendButton.widthAnchor];
        [_modeButton constrainWidthToAnchor:_multipleOffenseButton.widthAnchor];
        [_adjustmentOptionButton constrainTopToAnchor:_modeButton.bottomAnchor constant:_innerMargin];
        [_compareOptionButton constrainTopToAnchor:_adjustmentOptionButton.topAnchor];
        [_adjustmentOptionButton constrainWidthToAnchor:_compareOptionButton.widthAnchor];
        [_tableView constrainHeightToAnchor:_dateRangeButton.heightAnchor multiplier:5.0];
    }
}

- (void)removeAllConstraints
{
    [_dateRangeButton removeAllConstraints];
    [_boundingAreaButton removeAllConstraints];
    [_legendButton removeAllConstraints];
    [_modeButton removeAllConstraints];
    [_multipleOffenseButton removeAllConstraints];
    [_adjustmentOptionButton removeAllConstraints];
    [_compareOptionButton removeAllConstraints];
    [_tableView removeAllConstraints];
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
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = UIColor.grayColor;
    _tableView.bounces = YES;
    _tableView.layer.borderColor = UIColor.blackColor.CGColor;
    _tableView.layer.borderWidth = _borderWidth;
    _tableView.rowHeight = _rowHeight;
    _tableView.sectionHeaderHeight = _headerHeight;
    _tableView.delaysContentTouches = NO;
    _tableView.separatorColor = UIColor.clearColor;
    _tableView.separatorInset = UIEdgeInsetsZero;
    [self.view addSubview:_tableView];
}

- (void)dateRangeTapped:(UIButton *)button
{
    NVDateRange *nvdr = [NVDateRange showDateRangeInView:self.view
                                                delegate:self
                                                fromDate:CRAPI.sharedInstance.fromDate
                                                  toDate:CRAPI.sharedInstance.toDate
                                               lockRange:NO
                                             forAllYears:CRAPI.sharedInstance.forAllYears];
#pragma unused(nvdr)
}

- (void)dateRange:(NVDateRange *)dateRange
didReturnFromDate:(NSInteger)fromDate
           toDate:(NSInteger)toDate
      forAllYears:(BOOL)forAllYears
{
    [dateRange hideDateRange:YES];
    CRAPI.sharedInstance.fromDate = fromDate;
    CRAPI.sharedInstance.toDate = toDate;
    CRAPI.sharedInstance.forAllYears = forAllYears;
    [self setDateRangeButtonTextFromDate:fromDate toDate:toDate];
}

- (void)setDateRangeButtonTextFromDate:(NSInteger)fromDate
                                toDate:(NSInteger)toDate
{
    NSString *fromString = [self formattedDate:[NSDate dateWithTimeIntervalSince1970:fromDate]];
    NSString *toString = [self formattedDate:[NSDate dateWithTimeIntervalSince1970:toDate]];
    NSString *titleText = [NSString stringWithFormat:@"Date Range:%@-%@", fromString, toString];
    if (CRAPI.sharedInstance.forAllYears)
        titleText = [titleText stringByAppendingString:@" FAY"];
    [_dateRangeButton setTitle:titleText forState:UIControlStateNormal];
}

- (void)updateButtons
{
    [self updateButton:_boundingAreaButton];
    [self updateButton:_legendButton];
    [self updateButton:_modeButton];
    [self updateButton:_dateRangeButton];
    [self updateButton:_multipleOffenseButton];
    [self updateButton:_adjustmentOptionButton];
    [self updateButton:_compareOptionButton];
}

- (void)legendTapped:(UIButton *)button
{
    if (!_legendButton.selected)
    {
        _legendButton.selected = YES;
        _boundingAreaButton.selected = NO;
        _modeButton.selected = NO;
        _multipleOffenseButton.selected = NO;
        _adjustmentOptionButton.selected = NO;
        _compareOptionButton.selected = NO;
        _currentArray = _legends;
        
        [self updateButtons];
        [_tableView reloadData];
    }
}

- (void)modeTapped:(UIButton *)button
{
    if (!_modeButton.selected)
    {
        _modeButton.selected = YES;
        _boundingAreaButton.selected = NO;
        _legendButton.selected = NO;
        _multipleOffenseButton.selected = NO;
        _adjustmentOptionButton.selected = NO;
        _compareOptionButton.selected = NO;
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

- (void)multipleOffenseTapped:(UIButton *)button
{
    if (!_multipleOffenseButton.selected)
    {
        _multipleOffenseButton.selected = YES;
        _legendButton.selected = NO;
        _boundingAreaButton.selected = NO;
        _modeButton.selected = NO;
        _adjustmentOptionButton.selected = NO;
        _compareOptionButton.selected = NO;
        _currentArray = _multipleOffenseOptions;
        
        [self updateButtons];
        [_tableView reloadData];
    }
}

- (void)adjustmentOptionTapped:(UIButton *)button
{
    if (!_adjustmentOptionButton.selected)
    {
        _adjustmentOptionButton.selected = YES;
        _multipleOffenseButton.selected = NO;
        _legendButton.selected = NO;
        _boundingAreaButton.selected = NO;
        _modeButton.selected = NO;
        _compareOptionButton.selected = NO;
        _currentArray = _adjustmentOptions;
        
        [self updateButtons];
        [_tableView reloadData];
    }
}

- (void)compareOptionTapped:(UIButton *)button
{
    if (!_compareOptionButton.selected)
    {
        _adjustmentOptionButton.selected = NO;
        _multipleOffenseButton.selected = NO;
        _legendButton.selected = NO;
        _boundingAreaButton.selected = NO;
        _modeButton.selected = NO;
        _compareOptionButton.selected = YES;
        _currentArray = _compareOptions;
        
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
        headerLabel.text = @"Value Adjustment Options";
    
    else if (_currentArray == _compareOptions)
        headerLabel.text = @"Data Compare Options";
    
    else
        headerLabel.text = @"Select Mode";
    
    [headerView addSubview:headerLabel];
    
    return headerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"CustomCell";
    
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:cellIdentifier];
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
            [_currentArray[indexPath.row] isEqualToString:_selectedCompareOption] ||
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
        
        [UserDefaults.defaults saveNSInteger:_selectedModeType forKey:@"SelectedModeType"];
        [self updateModes];
    }
    
    else if (_currentArray == _multipleOffenseOptions)
    {
        _selectedMultipleOffenseOption = _multipleOffenseOptions[indexPath.row];
        [UserDefaults.defaults saveString:_selectedMultipleOffenseOption forKey:@"SelectedMultipleOffenseOption"];
        
        [_multipleOffenseButton setTitle:[NSString stringWithFormat:@"Multiple Offenses:%@", _selectedMultipleOffenseOption]
                                forState:UIControlStateNormal];
        
        ConfigurationControl.sharedInstance.wantAllCrimes = [_selectedMultipleOffenseOption isEqualToString:@"All Offenses"];
        [UserDefaults.defaults saveBool:ConfigurationControl.sharedInstance.wantAllCrimes forKey:@"WantAllCrimes"];
    }
    
    else if (_currentArray == _adjustmentOptions)
    {
        _selectedAdjustmentOption = _adjustmentOptions[indexPath.row];
        [UserDefaults.defaults saveString:_selectedAdjustmentOption forKey:@"SelectedAdjustmentOption"];
        
        [_adjustmentOptionButton setTitle:[NSString stringWithFormat:@"Adjustment Option:%@", _selectedAdjustmentOption]
                                 forState:UIControlStateNormal];
        
        ConfigurationControl.sharedInstance.adjustCrimeOption = (int)indexPath.row;
        [UserDefaults.defaults saveInteger:ConfigurationControl.sharedInstance.adjustCrimeOption forKey:@"AdjustCrimeOption"];
        ConfigurationControl.sharedInstance.adjustCrimeArea = @"BLOCK";
        [UserDefaults.defaults saveString:ConfigurationControl.sharedInstance.adjustCrimeArea forKey:@"AdjustCrimeArea"];
    }
    
    else if (_currentArray == _compareOptions)
    {
        _selectedCompareOption = _currentArray[indexPath.row];
        [UserDefaults.defaults saveString:_selectedCompareOption forKey:@"SelectedCompareOption"];
        
        [_compareOptionButton setTitle:[NSString stringWithFormat:@"Compare Option:%@", _selectedCompareOption]
                              forState:UIControlStateNormal];
        
        if ([_selectedCompareOption isEqualToString:@"Raw"])
            ConfigurationControl.sharedInstance.dataCompareOption = DCOptionRaw;
        
        else if ([_selectedCompareOption isEqualToString:@"Count Corrected"])
            ConfigurationControl.sharedInstance.dataCompareOption = DCOptionCount;
        
        else if ([_selectedCompareOption isEqualToString:@"Time Corrected"])
            ConfigurationControl.sharedInstance.dataCompareOption = DCOptionTime;
        
        [UserDefaults.defaults saveBool:ConfigurationControl.sharedInstance.dataCompareOption forKey:@"DataCompareOption"];
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
    _adjustmentOptionButton.enabled = (_selectedModeType == NVMapModeTypeChoropleth);
    _compareOptionButton.enabled = (_selectedModeType != NVMapModeTypePIN);
    [self updateButton:_adjustmentOptionButton];
    [self updateButton:_compareOptionButton];
    
    NSString *uppercaseMode = _selectedMode.uppercaseString;
    CRAPI.sharedInstance.crimeAdjustValueArea = nil;
    
    if ([uppercaseMode containsString:@"PIN"])
        CRAPI.sharedInstance.crimeMode = PINMAP;
    
    else if ([uppercaseMode containsString:@"CHOROPLETH"])
        CRAPI.sharedInstance.crimeMode = CHOROPLETH;
    
    else if ([uppercaseMode containsString:@"HOTSPOT VIDEO"])
        CRAPI.sharedInstance.crimeMode = HOTSPOTVIDEO;
    
   else if ([uppercaseMode containsString:@"HOTSPOT"])
        CRAPI.sharedInstance.crimeMode = HOTSPOT;
    
    else if ([uppercaseMode containsString:@"LINE GRAPH"])
        CRAPI.sharedInstance.crimeMode = LINEGRAPH;
    
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
    
    else if ([uppercaseMode containsString:@" CITY "])
        CRAPI.sharedInstance.crimeTarget = @"CITY";
    
    else if ([uppercaseMode containsString:@" FOR CITY"])
        CRAPI.sharedInstance.crimeTarget = @"City";
    
    [UserDefaults.defaults saveString:CRAPI.sharedInstance.crimeTarget forKey:@"CrimeTarget"];
    
    if ([uppercaseMode containsString:@"MONTH WITH YEARLY COMPARE"])
    {
        CRAPI.sharedInstance.crimeCompare = @"Month With Yearly Compare";
        [UserDefaults.defaults saveString:CRAPI.sharedInstance.crimeCompare forKey:@"CrimeCompareValue"];
    }
    
    else if ([uppercaseMode containsString:@"MONTH WITH MONTHLY COMPARE"])
    {
        CRAPI.sharedInstance.crimeCompare = @"Month With Monthly Compare";
        [UserDefaults.defaults saveString:CRAPI.sharedInstance.crimeCompare forKey:@"CrimeCompareValue"];
    }
    
    else if ([uppercaseMode containsString:@"HOTSPOT VIDEO BY QUADWEEKS"])
    {
        CRAPI.sharedInstance.hotspotVideoMode = @"Hotspot Video by Quadweeks";
        [UserDefaults.defaults saveString:CRAPI.sharedInstance.crimeCompare forKey:@"Hotspot Video Mode"];
    }
    
    else if ([uppercaseMode containsString:@"HOTSPOT VIDEO BY DAY OF WEEK"])
    {
        CRAPI.sharedInstance.hotspotVideoMode = @"Hotspot Video by Day of Week";
        [UserDefaults.defaults saveString:CRAPI.sharedInstance.crimeCompare forKey:@"Hotspot Video Mode"];
    }
    
    else if ([uppercaseMode containsString:@"HOTSPOT VIDEO BY HOUR IN DAY"])
    {
        CRAPI.sharedInstance.hotspotVideoMode = @"Hotspot Video by Hour in Day";
        [UserDefaults.defaults saveString:CRAPI.sharedInstance.crimeCompare forKey:@"Hotspot Video Mode"];
    }
    
    else
    {
        CRAPI.sharedInstance.crimeCompare = @"";
        [UserDefaults.defaults saveString:CRAPI.sharedInstance.crimeCompare forKey:@"CrimeCompareValue"];        
    }
    
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
    [self removeAllConstraints];
    [self setupConstraintsForOrientation:toInterfaceOrientation];
}

- (NSString *)formattedDate:(NSDate *)date
{
    NSString *formattedDate = @"";
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"MM/dd/yyyy";
    formattedDate = [dateFormatter stringFromDate:date];
    
    return formattedDate;
}

- (void)areaTypeTapped:(UIButton *)button
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
        
        [_boundingAreaButton setTitle:[NSString stringWithFormat:@"Bounding Area:%@ (%@)",
                                       CRAPI.sharedInstance.currentOverallBoundaryName,
                                       CRAPI.sharedInstance.currentOverallBoundaryType]
                             forState:UIControlStateNormal];
    }
    
    else
        self.tabBarController.selectedIndex = 0;
}

@end
