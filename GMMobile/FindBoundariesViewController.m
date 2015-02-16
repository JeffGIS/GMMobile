//  FindBoundariesViewController.m
//  GMMobile

#import "FindBoundariesViewController.h"
#import "PropertyData.h"

@interface FindBoundariesViewController ()

@property (nonatomic) NSMutableArray *boundaryList;
@property (nonatomic) NSMutableArray *boundaryDataList;

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
    if (_boundaryList.count != 0)
        return _boundaryList.count;
    
    else
        return 1;
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
            cell.textLabel.text = _boundaryList[indexPath.row];
        
        else
        {
            BoundaryAreaData *baData = [[BoundaryAreaData alloc] init];
            baData = _boundaryDataList[indexPath.row];
            
            cell.textLabel.text = _boundaryDataList[indexPath.row];
            cell.detailTextLabel.text = _boundaryDataList[indexPath.row];
        }
        
        cell.textLabel.textColor = UIColor.blackColor;
        cell.detailTextLabel.textColor = UIColor.blackColor;
        cell.userInteractionEnabled = YES;
    }
    
    else
    {
        if ([tableView isEqual:_topTableView])
        {
            cell.textLabel.text = @"No Boundaries Type match current search text";
            cell.detailTextLabel.text = @"No Boundaries Type match current search text";
        }
        
        else
        {
            cell.textLabel.text = @"No Boundaries selected";
            cell.detailTextLabel.text = @"No Boundaries selected";
        }
        
        cell.textLabel.textColor = UIColor.grayColor;
        cell.detailTextLabel.textColor = UIColor.grayColor;
        cell.userInteractionEnabled = NO;
    }
    
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.detailTextLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:(tableView.rowHeight / 2.2)];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:(tableView.rowHeight / 3.0)];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    return cell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:_topTableView])
    {
        PropertyData *propData = [[PropertyData alloc] init];
        
        _boundaryDataList = [propData getBoundaryAreaDataForType:[tableView cellForRowAtIndexPath:indexPath].textLabel.text];
        [_bottomTableView reloadData];
    }
    
    else
    {
        
    }
}

@end