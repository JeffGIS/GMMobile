//  FindBoundariesViewController.m
//  GMMobile

#import "FindBoundariesViewController.h"
#import "PropertyData.h"

@interface FindBoundariesViewController ()

@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UITableView *topTableView;
@property (weak, nonatomic) IBOutlet UITableView *bottomTableView;
@property (weak, nonatomic) IBOutlet UIView *polylineView;
@property (weak, nonatomic) IBOutlet UIView *maskView;
@property (weak, nonatomic) IBOutlet UIView *offsetView;

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
    
    PropertyData *propData = [[PropertyData alloc] init];
    _boundaryList = [propData getBoundaryAreaTypes];
    
    [self setupTableView:_topTableView];
    [self setupTableView:_bottomTableView];
    [self setupBackButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
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

- (void)setupBackButton
{
    _backButton.backgroundColor = UIColor.blackColor;
    _backButton.layer.cornerRadius = 10.0;
    _backButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    
    [_backButton setTitleColor:UIColor.whiteColor
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
        PropertyData *propData = [[PropertyData alloc] init];
        
        _selectedType = _boundaryList[indexPath.row];
        _boundaryDataList = [propData getBoundaryAreaDataForType:_selectedType];
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

@end