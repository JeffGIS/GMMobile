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
    _tableView.backgroundColor = UserDefaults.defaults.green;
    _tableView.bounces = NO;
    _tableView.layer.borderColor = UIColor.blackColor.CGColor;
    
    CGFloat rowHeight = MAX((MAX(self.view.frame.size.width, self.view.bounds.size.height) / 12.8), 44.0);
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

- (void)setupTextField
{
    _pidEntry.delegate = self;
    _pidEntry.layer.borderColor = UIColor.blackColor.CGColor;
    _pidEntry.layer.borderWidth = (_tableView.rowHeight / 20.0);
    _pidEntry.layer.cornerRadius = 10.0;
    _pidEntry.adjustsFontSizeToFitWidth = YES;
    
    NSString *pidSearchText = [UserDefaults.defaults stringForKey:@"CurrentPIDSearchText"];
    
    if (![pidSearchText isEqualToString:@""])
    {
        _pidEntry.text = pidSearchText;
        PropertyData *propData = [[PropertyData alloc] init];
        
        _pidList = [propData getPIDsWithOwnerMatchingString:pidSearchText
                                                    limitOf:50];
        
        [_tableView reloadData];
    }
    
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
        if (textField.text.length == 4)
        {
            char txt[6];
            strcpy (txt, textField.text.UTF8String);
            
            if (txt[3] != '-')
            {
                txt[4] = txt[3];
                txt[3] = '-';
                txt[5] = 0;
                textField.text = [NSString stringWithUTF8String:txt];
            }
        }
        
        PropertyData *propData = [[PropertyData alloc] init];
        
        _pidList = [propData getPIDsWithOwnerMatchingString:textField.text
                                                    limitOf:50];
        
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
        [_delegate findPIDViewController:self
                            didSelectPID:[UserDefaults.defaults includeTextBeforeTab:_pidList[indexPath.row]]];
    }
}

@end