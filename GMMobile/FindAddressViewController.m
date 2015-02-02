//  FindAddressViewController.m
//  GMMobile

#import "FindAddressViewController.h"
#import "PropertyData.h"

@interface FindAddressViewController ()

@property (nonatomic) NSMutableArray *addressList;

@end

@implementation FindAddressViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    [self setupTableView];
    [self setupBackButton];
    [self setupTextField:_houseTF];
    [self setupTextField:_streetTF];
    _houseLabel.textColor = UIColor.whiteColor;
    _streetLabel.textColor = UIColor.whiteColor;
    
    [_houseTF addTarget:self
                 action:@selector(houseTFDidChange:)
       forControlEvents:UIControlEventEditingChanged];
    
    [_streetTF addTarget:self
                 action:@selector(streetTFDidChange:)
       forControlEvents:UIControlEventEditingChanged];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setupTableView
{
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorInset = UIEdgeInsetsZero;
    _tableView.separatorColor = UIColor.blackColor;
    _tableView.layer.cornerRadius = 24.0;
    _tableView.backgroundColor = UserDefaults.defaults.green;
    _tableView.bounces = NO;
    _tableView.layer.borderColor = UIColor.blackColor.CGColor;
    _tableView.layer.borderWidth = 4.0;
    _tableView.rowHeight = 80.0;
}

- (void)setupBackButton
{
    _backButton.backgroundColor = UIColor.blackColor;
    _backButton.layer.cornerRadius = 10.0;
    _backButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    
    [_backButton setTitleColor:UIColor.whiteColor
                      forState:UIControlStateNormal];
}

- (void)setupTextField:(UITextField *)textField
{
    textField.delegate = self;
    textField.layer.borderColor = UIColor.blackColor.CGColor;
    textField.layer.borderWidth = 4.0;
    textField.layer.cornerRadius = 10.0;
    textField.adjustsFontSizeToFitWidth = YES;
}

- (void)houseTFDidChange:(UITextField *)textField
{
    PropertyData *propData = [[PropertyData alloc] init];
    
    _addressList = [propData getPIDsMatchingAddress:textField.text.intValue
                                         streetName:_streetTF.text];
    
    [_tableView reloadData];
}

- (void)streetTFDidChange:(UITextField *)textField
{
    PropertyData *propData = [[PropertyData alloc] init];
    
    _addressList = [propData getPIDsMatchingAddress:_houseTF.text.intValue
                                         streetName:textField.text];
    
    [_tableView reloadData];
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
    if (_addressList.count != 0)
        return _addressList.count;
    
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
    
    if (_addressList.count != 0)
    {
        cell.textLabel.text = [[UserDefaults.defaults includeTextBeforeSecondTabFromEnd:_addressList[indexPath.row]]
                               stringByReplacingOccurrencesOfString:@"\t" withString:@" "];
        
        cell.detailTextLabel.text = [UserDefaults.defaults includeTextAfterLastTab:_addressList[indexPath.row]];
        cell.textLabel.textColor = UIColor.blackColor;
        cell.detailTextLabel.textColor = UIColor.blackColor;
        cell.userInteractionEnabled = YES;
    }
    
    else
    {
        cell.textLabel.text = @"No Addresses match current search text";
        cell.detailTextLabel.text = @"No Addresses match current search text";
        cell.textLabel.textColor = UIColor.grayColor;
        cell.detailTextLabel.textColor = UIColor.grayColor;
        cell.userInteractionEnabled = NO;
    }
    
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.detailTextLabel.textAlignment = NSTextAlignmentCenter;
    cell.layer.borderColor = UIColor.blackColor.CGColor;
    cell.layer.borderWidth = 0.5;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:32];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:24];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    return cell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   [self dismissTextField];
    
    if (_delegate)
    {
        [_delegate findAddressViewController:self
                            didSelectAddress:[[UserDefaults.defaults includeTextBeforeSecondTabFromEnd:_addressList[indexPath.row]]
                                              stringByReplacingOccurrencesOfString:@"\t" withString:@" "]
                                         PID:[UserDefaults.defaults includeTextBeforeLastTab:
                                              [UserDefaults.defaults includeTextAfterSecondTabFromEnd:_addressList[indexPath.row]]]];
    }
}

@end