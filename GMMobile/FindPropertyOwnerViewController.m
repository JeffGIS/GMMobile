//  FindPropertyOwnerViewController.m
//  GMMobile

#import "FindPropertyOwnerViewController.h"
#import "PropertyData.h"

@interface FindPropertyOwnerViewController ()

@property (nonatomic) NSMutableArray *propOwnerList;

@end

@implementation FindPropertyOwnerViewController

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
    _propOwnerTF.delegate = self;
    _propOwnerTF.layer.borderColor = UIColor.blackColor.CGColor;
    _propOwnerTF.layer.borderWidth = (_topTableView.rowHeight / 20.0);
    _propOwnerTF.layer.cornerRadius = 10.0;
    _propOwnerTF.adjustsFontSizeToFitWidth = YES;
    
    NSString *propOwnerSearchText = [UserDefaults.defaults stringForKey:@"CurrentPropOwnerSearchText"];
    
    if (![propOwnerSearchText isEqualToString:@""])
    {
        _propOwnerTF.text = propOwnerSearchText;
        PropertyData *propData = [[PropertyData alloc] init];
        
        //_propOwnerList = [propData someMethod];
        [_topTableView reloadData];
    }
    
    [_propOwnerTF addTarget:self
                     action:@selector(textFieldDidChange:)
           forControlEvents:UIControlEventEditingChanged];
}

- (void)textFieldDidChange:(UITextField *)textField
{
    if ([textField.text isEqualToString:@""])
    {
        _propOwnerList = nil;
        [_topTableView reloadData];
    }
    
    else
    {
        PropertyData *propData = [[PropertyData alloc] init];
        
        //_propOwnerList = [propData someMethod];
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
    [UserDefaults.defaults saveString:_propOwnerTF.text
                               forKey:@"CurrentPropOwnerSearchText"];
    
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
    if (_propOwnerList.count != 0)
        return _propOwnerList.count;
    
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
    
    if (_propOwnerList.count != 0)
    {
        if ([tableView isEqual:_topTableView])
        {
            cell.textLabel.text = _propOwnerList[indexPath.row];
            cell.detailTextLabel.text = _propOwnerList[indexPath.row];
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
            cell.textLabel.text = @"No Property Owners match current search text";
            cell.detailTextLabel.text = @"No Property Owners match current search text";
        }
        
        else
        {
            cell.textLabel.text = @"No Properties selected";
            cell.detailTextLabel.text = @"No Properties selected";
        }

        cell.textLabel.textColor = UIColor.grayColor;
        cell.detailTextLabel.textColor = UIColor.grayColor;
        cell.userInteractionEnabled = NO;
    }
    
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.detailTextLabel.textAlignment = NSTextAlignmentLeft;
    cell.layer.borderColor = UIColor.blackColor.CGColor;
    cell.layer.borderWidth = 0.5;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:(tableView.rowHeight / 2.5)];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:(tableView.rowHeight / 3.3)];
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