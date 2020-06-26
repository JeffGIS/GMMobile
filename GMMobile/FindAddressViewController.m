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
    
    [self setupTextFieldDefaults];
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
    _tableView.backgroundColor = UserDefaults.defaults.green;
    _tableView.bounces = NO;
    _tableView.layer.borderColor = UIColor.blackColor.CGColor;
    
    CGFloat rowHeight = MAX((MAX(self.view.frame.size.width, self.view.bounds.size.height) / 14.0), 44.0);
    _tableView.rowHeight = rowHeight;
    _tableView.layer.borderWidth = (rowHeight / 20.0);
    _tableView.layer.cornerRadius = 10.0;
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
    textField.layer.borderWidth = (_tableView.rowHeight / 20.0);
    textField.layer.cornerRadius = 10.0;
    textField.adjustsFontSizeToFitWidth = YES;
}

- (void)setupTextFieldDefaults
{
    NSString *houseSearchText = [UserDefaults.defaults stringForKey:@"CurrentHouseSearchText"];
    NSString *streetSearchText = [UserDefaults.defaults stringForKey:@"CurrentStreetSearchText"];
    
    if ((streetSearchText) && ![streetSearchText isEqualToString:@""])
        _streetTF.text = streetSearchText;
    
    if ((houseSearchText) && ![houseSearchText isEqualToString:@""])
    {
        _houseTF.text = houseSearchText;
        PropertyData *propData = [[PropertyData alloc] init];
        
        _addressList = [propData getPIDsMatchingAddress:houseSearchText
                                             streetName:streetSearchText];
        
        [_tableView reloadData];
    }
}

- (void)houseTFDidChange:(UITextField *)textField
{
    if ([textField.text isEqualToString:@""])
    {
        [_addressList removeAllObjects];
        [_tableView reloadData];
    }
    
    PropertyData *propData = [[PropertyData alloc] init];
    
    _addressList = [propData getPIDsMatchingAddress:textField.text
                                         streetName:_streetTF.text];
    
    [_tableView reloadData];
}

- (void)streetTFDidChange:(UITextField *)textField
{
    PropertyData *propData = [[PropertyData alloc] init];
    
    _addressList = [propData getPIDsMatchingAddress:_houseTF.text
                                         streetName:textField.text];
    
    [_tableView reloadData];
}

- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string
{
    if (textField == _houseTF)
    {
        NSCharacterSet *numberSet = NSCharacterSet.decimalDigitCharacterSet;
        NSCharacterSet *whitespaceSet = NSCharacterSet.whitespaceCharacterSet;
        NSCharacterSet *stringSet = [NSCharacterSet characterSetWithCharactersInString:string];
        
        if ([numberSet isSupersetOfSet:stringSet])
            return YES;
        else if ([string isEqualToString:@"%"]||[string isEqualToString:@"_"])
            return YES;
        else
        {
            [_houseTF resignFirstResponder];
            [_streetTF becomeFirstResponder];
            
            if (![whitespaceSet isSupersetOfSet:stringSet])
                _streetTF.text = string;
            
            return NO;
        }
    }
    
    else
        return YES;
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
    [UserDefaults.defaults saveString:_houseTF.text
                               forKey:@"CurrentHouseSearchText"];
    
    [UserDefaults.defaults saveString:_streetTF.text
                               forKey:@"CurrentStreetSearchText"];
    
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
        cell.textLabel.text = [textBeforeSecondTabFromEnd(_addressList[indexPath.row])
                               stringByReplacingOccurrencesOfString:@"\t"
                                                         withString:@" "];
        
        cell.detailTextLabel.text = textAfterLastTab(_addressList[indexPath.row]);
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
    
    if (_delegate)
    {
        [_delegate findAddressViewController:self
                            didSelectAddress:[textBeforeSecondTabFromEnd(_addressList[indexPath.row])
                                              stringByReplacingOccurrencesOfString:@"\t"
                                                                        withString:@" "]
                                         PID:textBeforeLastTab(textAfterSecondTabFromEnd(_addressList[indexPath.row]))];
    }
}

@end
