//  FindPIDViewController.m
//  GMMobile

#import "FindPIDViewController.h"
#import "PropertyData.h"

@interface FindPIDViewController ()

@property (nonatomic) NSMutableArray *pidList;

@end

@implementation FindPIDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    [self setupTableView];
    [self setupBackButton];
    [self setupTextField];
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

- (void)setupTextField
{
    _pidEntry.delegate = self;
    _pidEntry.layer.borderColor = UIColor.blackColor.CGColor;
    _pidEntry.layer.borderWidth = 4.0;
    _pidEntry.layer.cornerRadius = 10.0;
    _pidEntry.adjustsFontSizeToFitWidth = YES;
    
    NSString *pidSearchText = [UserDefaults.defaults stringForKey:@"CurrentPIDSearchText"];
    
    if (![pidSearchText isEqualToString:@""])
    {
        _pidEntry.text = pidSearchText;
        PropertyData *propData = [[PropertyData alloc] init];
        
        _pidList = [propData getPIDsWithOwnerMatchingString:pidSearchText];
        [_tableView reloadData];
    }
    
    _pidEntry.text = pidSearchText;
    
    [_pidEntry addTarget:self
                  action:@selector(textFieldDidChange:)
        forControlEvents:UIControlEventEditingChanged];
}


- (void)textFieldDidChange:(UITextField *)textField
{
    if ([textField.text isEqualToString:@""])
    {
        _pidList = nil;
        [_tableView reloadData];
    }
    
    else
    {
        PropertyData *propData = [[PropertyData alloc] init];

        _pidList = [propData getPIDsWithOwnerMatchingString:textField.text];
        [_tableView reloadData];
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
    [UserDefaults.defaults saveString:_pidEntry.text
                               forKey:@"CurrentPIDSearchText"];
    
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
    if (_pidList.count != 0)
        return _pidList.count;
    
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
    
    if (_pidList.count != 0)
    {
        cell.textLabel.text = [UserDefaults.defaults includeTextBeforeTab:_pidList[indexPath.row]];
        cell.detailTextLabel.text = [UserDefaults.defaults includeTextAfterTab:_pidList[indexPath.row]];
        cell.textLabel.textColor = UIColor.blackColor;
        cell.detailTextLabel.textColor = UIColor.blackColor;
        cell.userInteractionEnabled = YES;
    }
    
    else
    {
        cell.textLabel.text = @"No PIDs match current search text";
        cell.detailTextLabel.text = @"No PIDs match current search text";
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
        [_delegate findPIDViewController:self
                            didSelectPID:[UserDefaults.defaults includeTextBeforeTab:_pidList[indexPath.row]]];
    }
}

@end