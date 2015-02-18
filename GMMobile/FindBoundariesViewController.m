//  FindBoundariesViewController.m
//  GMMobile

#import "FindBoundariesViewController.h"
#import "PropertyData.h"

@interface FindBoundariesViewController ()

@property (nonatomic) NSMutableArray *boundaryList;
@property (nonatomic) NSMutableArray *boundaryDataList;
@property (nonatomic) NSString *selectedType;

@end

@implementation FindBoundariesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    [self setupTableView:_topTableView];
    [self setupTableView:_bottomTableView];
    [self setupBackButton];
    
    PropertyData *propData = [[PropertyData alloc] init];
    _boundaryList = [propData getBoundaryAreaTypes];
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
    tableView.layer.borderWidth = (rowHeight / 20.0);
    tableView.layer.cornerRadius = 10.0;
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
    return 1;
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
            return _boundaryDataList.count;
        
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
                cell.accessoryType = UITableViewCellAccessoryNone;
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
                BoundaryAreaData *baData = [[BoundaryAreaData alloc] init];
                baData = _boundaryDataList[indexPath.row];
                
                cell.textLabel.text = baData.name;
                cell.textLabel.textColor = UIColor.blackColor;
                cell.userInteractionEnabled = YES;
                cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
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
        
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name"
                                                               ascending:YES];
        
        [_boundaryDataList sortUsingDescriptors:[NSArray arrayWithObject:sort]];
        
        [_bottomTableView reloadData];
    }
    
    else
    {
        if (_delegate)
        {
            BoundaryAreaData *baData = [[BoundaryAreaData alloc] init];
            baData = _boundaryDataList[indexPath.row];
            
            [_delegate findBoundsViewController:self
                                didSelectBounds:baData.name
                                           type:_selectedType
                                          refno:baData.refno];
        }
    }
}

- (void)tableView:(UITableView *)tableView
accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    BoundaryAreaData *baData = [[BoundaryAreaData alloc] init];
    baData = _boundaryDataList[indexPath.row];
    
    NSLog(@"Detail Disclosure requested for %@", baData.name);
}

@end