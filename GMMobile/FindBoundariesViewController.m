//  FindBoundariesViewController.m
//  GMMobile

#import "FindBoundariesViewController.h"
#import "PropertyData.h"

@interface FindBoundariesViewController ()

@property (nonatomic) NSMutableArray *boundaryList;

@end

@implementation FindBoundariesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    [self setupTableView:_topTableView];
    [self setupTableView:_bottomTableView];
    [self setupBackButton];
    [self setupTextField];
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

- (void)setupTextField
{
    _boundariesTF.delegate = self;
    _boundariesTF.layer.borderColor = UIColor.blackColor.CGColor;
    _boundariesTF.layer.borderWidth = (_topTableView.rowHeight / 20.0);
    _boundariesTF.layer.cornerRadius = 10.0;
    _boundariesTF.adjustsFontSizeToFitWidth = YES;
    
    NSString *boundsSearchText = [UserDefaults.defaults stringForKey:@"CurrentBoundsSearchText"];
    
    if (![boundsSearchText isEqualToString:@""])
    {
        _boundariesTF.text = boundsSearchText;
        PropertyData *propData = [[PropertyData alloc] init];
        
        //_propOwnerList = [propData someMethod];
        [_topTableView reloadData];
    }
    
    [_boundariesTF addTarget:self
                      action:@selector(textFieldDidChange:)
            forControlEvents:UIControlEventEditingChanged];
}

- (void)textFieldDidChange:(UITextField *)textField
{
    if ([textField.text isEqualToString:@""])
    {
        _boundaryList = nil;
        [_topTableView reloadData];
    }
    
    else
    {
        PropertyData *propData = [[PropertyData alloc] init];
        
        //_boundaryList = [propData someMethod];
        [_topTableView reloadData];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self dismissTextField];
    return NO;
}

- (IBAction)goBack:(id)sender
{
    [self dismissTextField];
    
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    [self dismissTextField];
}

- (void)dismissTextField
{
    [UserDefaults.defaults saveString:_boundariesTF.text
                               forKey:@"CurrentBoundsSearchText"];
    
    for (UIView *textField in self.view.subviews)
    {
        if ([textField isKindOfClass:UITextField.class] && textField.isFirstResponder)
            [textField resignFirstResponder];
    }
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
        {
            cell.textLabel.text = _boundaryList[indexPath.row];
            cell.detailTextLabel.text = _boundaryList[indexPath.row];
        }
        
        else
        {
            //cell.textLabel.text = newArray[indexPath.row];
            //cell.detailTextLabel.text = newArray[indexPath.row];
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
    [self dismissTextField];
    
    //this is where we populate bottomTableView array and reload
}

@end