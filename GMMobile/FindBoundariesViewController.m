//  FindBoundariesViewController.m
//  GMMobile

#import "FindBoundariesViewController.h"
#import "BoundaryData.h"

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

@property (nonatomic) NSMutableArray *boundaryList, *boundaryDataList;
@property (nonatomic) NSString *selectedType;
@property (nonatomic) NSMutableDictionary *sections;
@property (nonatomic) NSMutableArray *sectionBegins, *sectionCounts, *sectionKeys;

@end

@implementation FindBoundariesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    
    BoundaryData *boundData = [[BoundaryData alloc] init];
    _boundaryList = [boundData getBoundaryAreaTypes];
    
    [self setupTableView:_topTableView];
    [self setupTableView:_bottomTableView];
    
    [self setupButton:_backButton
                title:@"< Return"];
    
    [self setupButton:_offsetButton
                title:[NSString stringWithFormat:@"Edit Offset:\n%@",
                       CRAPI.sharedInstance.offsetForBounds]];
    
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
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        _offsetButton.titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
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
    tableView.bounces = NO;
    tableView.layer.borderColor = UIColor.blackColor.CGColor;
    
    CGFloat rowHeight = MAX((MAX(self.view.frame.size.width, self.view.bounds.size.height) / 12.8), 44.0);
    tableView.rowHeight = rowHeight;
    tableView.sectionHeaderHeight = 0.0;
    tableView.layer.borderWidth = (rowHeight / 20.0);
    tableView.layer.cornerRadius = 10.0;
    tableView.sectionIndexMinimumDisplayRowCount = 6;
    
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
    didReturnText:(NSString *)text
{
    if (!text || [text isEqualToString:@""])
        text = @"0 feet";
    
    CRAPI.sharedInstance.offsetForBounds = text;
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
    if (tableView == _bottomTableView &&
        ![_selectedType isEqualToString:@"Minneapolis Wards"])
    {
        return _sections.count;
    }
    
    else
        return 1;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if (tableView == _bottomTableView &&
        ![_selectedType isEqualToString:@"Minneapolis Wards"])
    {
        return _sectionKeys;
    }
    
    else
        return nil;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    if ([tableView isEqual:_topTableView])
    {
        if (_boundaryList.count != 0)
            return _boundaryList.count;
        
        else
            return 1;
    }
    
    else
    {
        if (_boundaryDataList.count != 0)
        {
            if (![_selectedType isEqualToString:@"Minneapolis Wards"])
            {
                NSNumber *num = _sectionCounts[section];
                int n = (int)num.integerValue;
                return n;
            }
            
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
    
    if (_boundaryList.count != 0)
    {
        if ([tableView isEqual:_topTableView])
        {
            if (_boundaryList.count != 0)
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
        
        else
        {
            if (_boundaryDataList.count != 0)
            {
                //BoundaryAreaData *baData = [[BoundaryAreaData alloc] init];
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
    if ([tableView isEqual:_topTableView])
    {
        BoundaryData *boundData = [[BoundaryData alloc] init];
        
        _selectedType = _boundaryList[indexPath.row];
        _boundaryDataList = [boundData getBoundaryAreaDataForType:_selectedType];
        NSSortDescriptor *sort;
        
        if ([_selectedType isEqualToString:@"Minneapolis Wards"])
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
        
        [_boundaryDataList sortUsingDescriptors:[NSArray arrayWithObject:sort]];
        
        if (![_selectedType isEqualToString:@"Minneapolis Wards"])
            [self setupSectionIndex];
        
        [_bottomTableView reloadData];
    }
    
    else
    {
        if (_delegate)
        {
            NSNumber *begin = _sectionBegins[indexPath.section];
            //BoundaryAreaData *baData = [[BoundaryAreaData alloc] init];
            BoundaryAreaData *baData = _boundaryDataList[(begin.integerValue + indexPath.row)];
            
            [_delegate findBoundsViewController:self
                                didSelectBounds:baData.name
                                           type:_selectedType
                                          refno:baData.refno];
        }
    }
}

- (void)setupSectionIndex
{
    _sections = [[NSMutableDictionary alloc] init];
    _sectionBegins = [[NSMutableArray alloc] init];
    _sectionCounts = [[NSMutableArray alloc] init];
    _sectionKeys = [[NSMutableArray alloc] init];
    //BoundaryAreaData *baData = [[BoundaryAreaData alloc] init];
    
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

@end