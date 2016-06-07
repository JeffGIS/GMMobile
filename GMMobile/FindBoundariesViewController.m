//  FindBoundariesViewController.m
//  GMMobile

#import "FindBoundariesViewController.h"
#import "BoundaryData.h"
#import "CrimeDataOptions.h"

@interface FindBoundariesViewController ()

@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UITableView *topTableView;
@property (weak, nonatomic) IBOutlet UITableView *bottomTableView;
@property (weak, nonatomic) IBOutlet UIView *polylineView;
@property (weak, nonatomic) IBOutlet UIView *maskBoundsView;
@property (weak, nonatomic) IBOutlet UIButton *offsetButton;
@property (weak, nonatomic) IBOutlet UISwitch *polylineSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *maskBoundsSwitch;
@property (weak, nonatomic) IBOutlet UILabel *polylineLabel;
@property (weak, nonatomic) IBOutlet UILabel *maskBoundsLabel;
@property (weak, nonatomic) IBOutlet UIButton *selectFromMapButton;

@property (nonatomic) NSMutableArray *boundaryList, *boundaryDataList;
@property (nonatomic, copy) NSString *selectedType;
@property (nonatomic) NSMutableDictionary *sections;
@property (nonatomic) NSMutableArray *sectionBegins, *sectionCounts, *sectionKeys;
@property BOOL useOtherAreas;

@end

@implementation FindBoundariesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    
    BoundaryData *boundData = [[BoundaryData alloc] init];
    _boundaryList = [boundData getBoundaryAreaTypes];
    _useOtherAreas = NO;
    
    if (_otherAreas.count)
        [_boundaryList addObject:@"Other Areas"];
    
    [self setupTableView:_topTableView];
    [self setupTableView:_bottomTableView];
    
    [self setupButton:_backButton
                title:@"< Return"];
    
    [self setupButton:_offsetButton
                title:[NSString stringWithFormat:@"Edit Offset:\n%@",
                       CRAPI.sharedInstance.offsetForBounds]];
    
    [self setupButton:_selectFromMapButton
                title:@"Select From Map"];
    
    [self setupView:_polylineView];
    [self setupView:_maskBoundsView];
    
    [self setupLabel:_polylineLabel
                text:@"Show\nPolyline"];
    
    [self setupLabel:_maskBoundsLabel
                text:@"Mask\nBounds"];
    
    _polylineSwitch.tintColor = UIColor.redColor;
    _maskBoundsSwitch.tintColor = UIColor.redColor;
    _polylineSwitch.on = CRAPI.sharedInstance.showPolylineForBounds;
    _maskBoundsSwitch.on = CRAPI.sharedInstance.maskBoundsForBounds;
    _selectFromMapButton.enabled = NO;
    _selectFromMapButton.alpha = 0.4;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        _offsetButton.titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
        _selectFromMapButton.titleLabel.font = [UIFont boldSystemFontOfSize:24.0];
    }
    
    else
        _selectFromMapButton.titleLabel.font = [UIFont boldSystemFontOfSize:36.0];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setupView:(UIView *)view
{
    view.backgroundColor = UserDefaults.defaults.appleGray;
    view.layer.borderColor = UIColor.blackColor.CGColor;
    view.layer.borderWidth = 2.0;
    view.layer.cornerRadius = 10.0;
}

- (void)setupLabel:(UILabel *)label
              text:(NSString *)text
{
    label.text = text;
    label.numberOfLines = 2;
    label.font = [UIFont boldSystemFontOfSize:32.0];
    label.adjustsFontSizeToFitWidth = YES;
    label.textAlignment = NSTextAlignmentCenter;
}

- (void)setupButton:(UIButton *)button
              title:(NSString *)title
{
    button.backgroundColor = UIColor.blackColor;
    button.layer.cornerRadius = 10.0;
    button.titleLabel.font = [UIFont boldSystemFontOfSize:24.0];
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    button.titleLabel.numberOfLines = 2;
    button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    [button setTitle:title
            forState:UIControlStateNormal];
    
    [button setTitleColor:UIColor.whiteColor
                 forState:UIControlStateNormal];
}

- (void)setupTableView:(UITableView *)tableView
{
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.separatorInset = UIEdgeInsetsZero;
    tableView.separatorColor = UIColor.blackColor;
    tableView.backgroundColor = UserDefaults.defaults.green;
    tableView.bounces = YES;
    tableView.layer.borderColor = UIColor.blackColor.CGColor;
    
    CGFloat rowHeight = MAX((MAX(self.view.frame.size.width, self.view.bounds.size.height) / 14.0), 44.0);
    tableView.rowHeight = rowHeight;
    tableView.sectionHeaderHeight = 0.0;
    tableView.layer.borderWidth = (rowHeight / 20.0);
    tableView.layer.cornerRadius = 10.0;
    tableView.sectionIndexMinimumDisplayRowCount = 8;
    tableView.delaysContentTouches = YES;
    
    tableView.sectionIndexTrackingBackgroundColor = [UIColor colorWithWhite:0.0
                                                                      alpha:0.1];
}

- (IBAction)polylineSwitchTapped:(UISwitch *)sender
{
    CRAPI.sharedInstance.showPolylineForBounds = sender.on;
}

- (IBAction)maskBoundsSwitchTapped:(UISwitch *)sender
{
    CRAPI.sharedInstance.maskBoundsForBounds = sender.on;
}

- (IBAction)offsetButtonTapped:(id)sender
{
    NVUnitPickerTextAlert *nvupta = [NVUnitPickerTextAlert showUnitPickerTextAlertWithTitle:@"Edit Offset"
                                                                                pickerArray:@[@"feet", @"meters", @"miles"]
                                                                                   delegate:self];
    
    nvupta.text = CRAPI.sharedInstance.offsetForBounds;
}

- (void)textAlert:(NVUnitPickerTextAlert *)textAlert
   didReturnValue:(NSString *)value
            units:(NSString *)units
{
    if (!value || [value isEqualToString:@""])
        value = @"0";
    
    if (!units || [units isEqualToString:@""])
        units = @"feet";
    
    if ([value characterAtIndex:(value.length - 1)] == '.')
        value = [value substringToIndex:value.length - 1];
    
    CRAPI.sharedInstance.offsetForBounds = [NSString stringWithFormat:@"%@ %@", value, units];
    
    NSInteger intValue = value.integerValue;
    
    if ([units isEqualToString:@"feet"])
        CRAPI.sharedInstance.offsetForBoundsInMeters = (int)(intValue * 0.3048);
    
    else if ([units isEqualToString:@"meters"])
        CRAPI.sharedInstance.offsetForBoundsInMeters = (int)intValue;
    
    else if ([units isEqualToString:@"miles"])
        CRAPI.sharedInstance.offsetForBoundsInMeters = (int)(intValue * 1609.34);
    
    [textAlert hideTextAlert:YES];
    
    [_offsetButton setTitle:[NSString stringWithFormat:@"Edit Offset:\n%@",
                             CRAPI.sharedInstance.offsetForBounds]
                   forState:UIControlStateNormal];
}

- (IBAction)goBack:(id)sender
{
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == _bottomTableView && !_useOtherAreas)
        return _sections.count;
    
    else
        return 1;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if (tableView == _bottomTableView && !_useOtherAreas)
        return _sectionKeys;

    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    if (tableView == _topTableView)
    {
        if (_boundaryList.count)
            return _boundaryList.count;
        
        else
            return 1;
    }
    
    else if (_useOtherAreas)
    {
        if (_otherAreas.count)
            return _otherAreas.count;
        
        else
            return 1;
    }
    
    else
    {
        if (_boundaryDataList.count)
        {
            if (_sectionCounts.count)
                return [_sectionCounts[section] integerValue];
            
            else
                return _boundaryDataList.count;
        }
        
        else
            return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"
                                                            forIndexPath:indexPath];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:@"Cell"];
    }
    
    if (_boundaryList.count)
    {
        if (tableView == _topTableView)
        {
            if (_boundaryList.count)
            {
                cell.textLabel.text = _boundaryList[indexPath.row];
                cell.textLabel.textColor = UIColor.blackColor;
                cell.userInteractionEnabled = YES;
            }
            
            else
            {
                cell.textLabel.text = @"No Boundaries Types available";
                cell.textLabel.textColor = UIColor.grayColor;
                cell.userInteractionEnabled = NO;
            }
        }
        
        else if (_useOtherAreas)
        {
            if (_otherAreas.count)
            {
                cell.textLabel.text = _otherAreas[indexPath.row];
                cell.textLabel.textColor = UIColor.blackColor;
                cell.userInteractionEnabled = YES;
            }
            
            else
            {
                cell.textLabel.text = @"No Boundaries Types available";
                cell.textLabel.textColor = UIColor.grayColor;
                cell.userInteractionEnabled = NO;
            }
        }
        
        else
        {
            if (_boundaryDataList.count)
            {
                NSNumber *begin = _sectionBegins[indexPath.section];
                BoundaryAreaData *baData = _boundaryDataList[(begin.integerValue + indexPath.row)];
                
                if ([_selectedType isEqualToString:@"Minneapolis Wards"])
                    cell.textLabel.text = [NSString stringWithFormat:@"Ward %@", baData.name.capitalizedString];
                
                else
                    cell.textLabel.text = baData.name.capitalizedString;
                
                cell.textLabel.textColor = UIColor.blackColor;
                cell.userInteractionEnabled = YES;
            }
            
            else
            {
                cell.textLabel.text = @"No Boundaries available";
                cell.textLabel.textColor = UIColor.grayColor;
                cell.userInteractionEnabled = NO;
            }
        }
    }
    
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:(tableView.rowHeight / 2.2)];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    return cell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == _topTableView)
    {
        _selectedType = _boundaryList[indexPath.row];
        
        if ([_selectedType isEqualToString:@"Other Areas"])
            _useOtherAreas = YES;
        
        else
        {
            _useOtherAreas = NO;
            BoundaryData *boundData = [[BoundaryData alloc] init];
            _boundaryDataList = [boundData getBoundaryAreaDataForType:_selectedType];
        }
        
        NSSortDescriptor *sort = nil;
        
        if ([_selectedType isEqualToString:@"Entire City"])
        {
            CRAPI.sharedInstance.currentOverallBoundaryRefno = 51144;
            CRAPI.sharedInstance.parcelTextOption = 2;
            CRAPI.sharedInstance.currentOverallBoundaryName = @"Minneapolis";
            CRAPI.sharedInstance.currentOverallBoundaryType = @"City";
            CRAPI.sharedInstance.GMMSetting = GMMSettingBoundaries;
            self.tabBarController.selectedIndex = 0;
            return;
        }
        else if ([_selectedType isEqualToString:@"Minneapolis Wards"])
        {
            sort = [NSSortDescriptor sortDescriptorWithKey:@"name"
                                                 ascending:YES
                                                comparator:^NSComparisonResult(id obj1, id obj2){
                                                    return [obj1 compare:obj2
                                                                 options:NSNumericSearch];
                                                }];
        }
        
        else
        {
            sort = [NSSortDescriptor sortDescriptorWithKey:@"name"
                                                 ascending:YES
                                                  selector:@selector(caseInsensitiveCompare:)];
        }
        
        if (!_useOtherAreas)
        {
            [_boundaryDataList sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            [self setupSectionIndex];
        }
        
        [_bottomTableView reloadData];
        _selectFromMapButton.enabled = YES;
        _selectFromMapButton.alpha = 1.0;
    }
    
    else
    {
        if (_delegate)
        {
            NSString *boundsName = @"";
            int refno = 0;
            
            if (_useOtherAreas)
                boundsName = _otherAreas[indexPath.row];
            
            else
            {
                NSNumber *begin = _sectionBegins[indexPath.section];
                BoundaryAreaData *baData = _boundaryDataList[(begin.integerValue + indexPath.row)];
                boundsName = baData.name;
                refno = baData.refno;
            }
            
            [_delegate findBoundsViewController:self
                                didSelectBounds:boundsName
                                           type:_selectedType
                                          refno:refno];
        }
    }
}

- (void)setupSectionIndex
{
    _sections = [[NSMutableDictionary alloc] init];
    _sectionBegins = [[NSMutableArray alloc] init];
    _sectionCounts = [[NSMutableArray alloc] init];
    _sectionKeys = [[NSMutableArray alloc] init];
    
    int sectionCount = 0;
    
    for (int i = 0; i < _boundaryDataList.count; i++)
    {
        BoundaryAreaData *baData = [_boundaryDataList objectAtIndex:i];
        NSString *baDataName = baData.name;
        NSString *indexLetter = [baDataName substringToIndex:1];
        NSString *key = [[NSString alloc] initWithFormat:@"%@", indexLetter];
        
        if (!_sections[key])
        {
            if (sectionCount)
                [_sectionCounts addObject:[[NSNumber alloc] initWithInt:sectionCount]];
            
            sectionCount = 1;
            [_sections setValue:[[NSMutableArray alloc] init] forKey:key];
            [_sectionBegins addObject:[[NSNumber alloc] initWithInt:i]];
            [_sectionKeys addObject:key];
        }
        
        else
            sectionCount++;
        
        [_sections[key] addObject:baDataName];
    }
    
    if (sectionCount)
        [_sectionCounts addObject:[[NSNumber alloc] initWithInt:sectionCount]];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    
    
    for (NVUnitPickerTextAlert *alert in UIApplication.sharedApplication.keyWindow.subviews)
    {
        if ([alert isKindOfClass:NVUnitPickerTextAlert.class])
            [alert willRotateWithDuration:duration];
    }
}

- (IBAction)selectFromMap:(id)sender
{
    NSString *type = [_topTableView cellForRowAtIndexPath:_topTableView.indexPathForSelectedRow].textLabel.text;
    CRAPI.sharedInstance.selectBoundaryFromMapType = type;
    
    if (_delegate)
    {
        [_delegate findBoundsViewController:self
                            didSelectBounds:nil
                                       type:nil
                                      refno:0];
    }
}

@end