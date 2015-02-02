//  FindIntersectionViewController.m
//  GMMobile

#import "FindIntersectionViewController.h"
#import "PropertyData.h"

@interface FindIntersectionViewController ()

@property (nonatomic) NSMutableArray *intersectionList;

@end

@implementation FindIntersectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    [self setupTableView];
    [self setupBackButton];
    [self setupTextField:_street1TF];
    [self setupTextField:_street2TF];
    _street1Label.textColor = UIColor.whiteColor;
    _street2Label.textColor = UIColor.whiteColor;
    
    [_street1TF addTarget:self
                   action:@selector(street1TFDidChange:)
         forControlEvents:UIControlEventEditingChanged];
    
    [_street2TF addTarget:self
                   action:@selector(street2TFDidChange:)
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

- (void)setupTextFieldDefaults
{
    NSString *street1SearchText = [UserDefaults.defaults stringForKey:@"CurrentStreet1SearchText"];
    NSString *street2SearchText = [UserDefaults.defaults stringForKey:@"CurrentStreet2SearchText"];
    
    if (![street1SearchText isEqualToString:@""])
        _street1TF.text = street1SearchText;
    
    if (![street2SearchText isEqualToString:@""])
    {
        _street2TF.text = street2SearchText;
        PropertyData *propData = [[PropertyData alloc] init];
        
        //_intersectionList = [propData someMethod];
        [_tableView reloadData];
    }
}

- (void)street1TFDidChange:(UITextField *)textField
{
    PropertyData *propData = [[PropertyData alloc] init];
    
    //_intersectionList = [propData someMethod];
    [_tableView reloadData];
}

- (void)street2TFDidChange:(UITextField *)textField
{
    PropertyData *propData = [[PropertyData alloc] init];
    
    //_intersectionList = [propData someMethod];
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
    if (_intersectionList.count != 0)
        return _intersectionList.count;
    
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
    
    if (_intersectionList.count != 0)
    {
        cell.textLabel.text = _intersectionList[indexPath.row];
        cell.detailTextLabel.text = _intersectionList[indexPath.row];
        cell.textLabel.textColor = UIColor.blackColor;
        cell.detailTextLabel.textColor = UIColor.blackColor;
        cell.userInteractionEnabled = YES;
    }
    
    else
    {
        cell.textLabel.text = @"No Intersections match current search text";
        cell.detailTextLabel.text = @"No Intersections match current search text";
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
        //[_delegate findIntersectionViewController:self
                            //didSelectIntersection:someString];
    }
}

@end