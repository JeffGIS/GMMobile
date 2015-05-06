//  SettingOptionsViewController.m
//  GMMobile

#import "SettingOptionsViewController.h"
#import "CCodeLibrary/UserDefaults.h"

@interface SettingOptionsViewController ()

@property (nonatomic) NSArray *contents;

@end

@implementation SettingOptionsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UserDefaults.defaults.appleGray;
    _contents = @[@"Auto Upload", @"Upload Now", @"Load Data"];
    
    _tableView.layer.cornerRadius = 10.0;
    _tableView.rowHeight = 72.0;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.bounces = NO;
    _tableView.delaysContentTouches = NO;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return _contents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"
                                                            forIndexPath:indexPath];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:@"Cell"];
    }
    
    cell.textLabel.font = [UIFont boldSystemFontOfSize:32.0];
    cell.textLabel.textColor = UIColor.blackColor;
    cell.textLabel.text = _contents[indexPath.row];
    cell.textLabel.highlightedTextColor = UserDefaults.defaults.appleBlue;
    cell.indentationWidth = 80.0;
    
    BOOL containsSwitch = NO;
    
    if (indexPath.row == 0)
    {
        for (UISwitch *switches in cell.contentView.subviews)
        {
            if ([switches isKindOfClass:UISwitch.class])
                containsSwitch = YES;
        }
        
        if (!containsSwitch)
        {
            UISwitch *cellSwitch = [[UISwitch alloc] init];
            cellSwitch.tintColor = UIColor.redColor;
            cellSwitch.onTintColor = UIColor.greenColor;
            
            cellSwitch.center = CGPointMake((cell.contentView.frame.size.width - 100.0),
                                            (cell.contentView.frame.size.height / 2.0));
            
            [cell.contentView addSubview:cellSwitch];
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    else
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
    
    if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
         isEqualToString:@"Upload Now"])
    {
        [self uploadNow];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Load Data"])
    {
        [self loadData];
    }
}

- (void)uploadNow
{
    
}

- (void)loadData
{
    NVTextAlert *textAlert = [NVTextAlert showTextAlertinView:self.view
                                                     delegate:self
                                                        title:@"Password Required for Access to Load Data"];
    
    textAlert.keyboardType = UIKeyboardTypeNumberPad;
    textAlert.minimumCharacters = 0;
}

- (void)textAlert:(NVTextAlert *)textAlert
    didReturnText:(NSString *)text
{
    [textAlert hideTextAlert:YES];
    
    NSString *dateString = [NSDateFormatter localizedStringFromDate:NSDate.date
                                                          dateStyle:NSDateFormatterShortStyle
                                                          timeStyle:NSDateFormatterShortStyle];
    
    dateString = [UserDefaults.defaults includeTextBeforeComma:dateString];
    dateString = [UserDefaults.defaults includeTextBeforeLastSlash:dateString];
    
    NSString *month = [UserDefaults.defaults includeTextBeforeSlash:dateString];
    NSString *day = [UserDefaults.defaults includeTextAfterSlash:dateString];
    
    if (month.integerValue < 10)
        month = [NSString stringWithFormat:@"0%@", month];
    
    if (day.integerValue < 10)
        day = [NSString stringWithFormat:@"0%@", day];
    
    dateString = [NSString stringWithFormat:@"%@%@", month, day];
    
    dateString = [UserDefaults.defaults reverseString:dateString];
    
    if ([dateString isEqualToString:text])
    {
        [self performSegueWithIdentifier:@"ShowSettings"
                                  sender:self];
    }
    
    else
    {
        NVLargeAlertView *largeAlert = [NVLargeAlertView showLargeAlertViewinView:self.view
                                                                         delegate:self
                                                                            title:@"Password Not Correct"
                                                                    topButtonText:@"OK"
                                                                 bottomButtonText:@"Try Again"
                                                                 destructiveIndex:NVLargeAlertIndexNone];
#pragma unused(largeAlert)
    }
}

- (void)largeAlertView:(NVLargeAlertView *)largeAlertView
   didTapButtonAtIndex:(NVLargeAlertIndex)buttonIndex
{
    if (buttonIndex == NVLargeAlertIndexBottomButton)
    {
        NVTextAlert *textAlert = [NVTextAlert showTextAlertinView:self.view
                                                         delegate:self
                                                            title:@"Password Required for Access to Load Data"];
        
        textAlert.keyboardType = UIKeyboardTypeNumberPad;
        textAlert.minimumCharacters = 0;
    }
    
    [largeAlertView hideLargeAlertView:YES];
}

@end