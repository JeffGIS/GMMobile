//  FindPropertyOwnerViewController.m
//  GMMobile

#import "FindPropertyOwnerViewController.h"
#import "PropertyData.h"
#import "CCodeLibrary/NVPopoverTableView.h"

@interface FindPropertyOwnerViewController () <UITextFieldDelegate,UITableViewDataSource,UITableViewDelegate,NVPopoverTableViewDelegate>

@property (nonatomic) NSMutableArray *propOwnerList;
@property (nonatomic) UIButton *returnButton, *limitButton;
@property (nonatomic) UITextField *propOwnerTF;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) UISwitch *multipleSwitch;
@property (nonatomic) UILabel *multipleLabel;
@property (nonatomic) CGFloat fontSize, cornerRadius;
@property LimitToOption limitToOption;
@property BOOL selectMultiple;

@end

@implementation FindPropertyOwnerViewController

+ (NSArray *)limitToOptions
{
    return @[@"No Limit", @"Map Bounds", @"Current City", @"Current County"];
}

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _limitToOption = [UserDefaults.defaults integerForKey:@"LimitToOption"];
    _selectMultiple = [UserDefaults.defaults boolForKey:@"SelectMultiple"];
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        _fontSize = 24.0, _cornerRadius = 4.0;
    
    else
        _fontSize = 36.0, _cornerRadius = 10.0;
    
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    [self setupTableView];
    [self setupButtons];
    [self setupTextField];
    [self setupSwitch];
    [self setupConstraints];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)prefersStatusBarHidden
{
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        return YES;
    
    else
        return NO;
}

- (void)setupTableView
{
    _tableView = UITableView.new;
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorColor = UIColor.blackColor;
    _tableView.backgroundColor = UserDefaults.defaults.green;
    _tableView.bounces = NO;
    _tableView.layer.borderColor = UIColor.blackColor.CGColor;
    _tableView.separatorInset = UIEdgeInsetsZero;
    
    CGFloat rowHeight = MAX((MAX(self.view.frame.size.width, self.view.bounds.size.height) / 16.0), 40.0);
    _tableView.rowHeight = rowHeight;
    _tableView.layer.borderWidth = (rowHeight / 20.0);
    _tableView.layer.cornerRadius = _cornerRadius;
    
    [self.view addSubview:_tableView];
}

- (void)setupButtons
{
    _returnButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _returnButton.translatesAutoresizingMaskIntoConstraints = NO;
    _returnButton.backgroundColor = UIColor.blackColor;
    _returnButton.titleLabel.font = [UIFont boldSystemFontOfSize:_fontSize];
    _returnButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    _returnButton.layer.cornerRadius = _cornerRadius;
    _returnButton.titleLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    
    [_returnButton setTitleColor:UIColor.whiteColor
                        forState:UIControlStateNormal];
    
    [_returnButton setTitleColor:UIColor.lightGrayColor
                        forState:UIControlStateHighlighted];
    
    [_returnButton setTitle:@"< Return"
                   forState:UIControlStateNormal];
    
    [_returnButton addTarget:self
                      action:@selector(returnButtonTapped:)
            forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_returnButton];
    
    _limitButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _limitButton.translatesAutoresizingMaskIntoConstraints = NO;
    _limitButton.backgroundColor = UIColor.blackColor;
    _limitButton.titleLabel.font = [UIFont boldSystemFontOfSize:_fontSize];
    _limitButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    _limitButton.layer.cornerRadius = _cornerRadius;
    _limitButton.titleLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    
    [_limitButton setTitleColor:UIColor.whiteColor
                       forState:UIControlStateNormal];
    
    [_limitButton setTitleColor:UIColor.lightGrayColor
                       forState:UIControlStateHighlighted];
    
    [self updateLimitButtonTitle];
    
    [_limitButton addTarget:self
                    action:@selector(limitButtonTapped:)
           forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_limitButton];
}

- (void)updateLimitButtonTitle
{
    [_limitButton setTitle:[NSString stringWithFormat:@"Limit To: %@", FindPropertyOwnerViewController.limitToOptions[_limitToOption]]
                  forState:UIControlStateNormal];
}

- (void)setupTextField
{
    _propOwnerTF = UITextField.new;
    _propOwnerTF.translatesAutoresizingMaskIntoConstraints = NO;
    _propOwnerTF.delegate = self;
    _propOwnerTF.layer.borderColor = UIColor.blackColor.CGColor;
    _propOwnerTF.layer.borderWidth = (_tableView.rowHeight / 20.0);
    _propOwnerTF.layer.cornerRadius = _cornerRadius;
    _propOwnerTF.adjustsFontSizeToFitWidth = YES;
    _propOwnerTF.textColor = UIColor.blackColor;
    _propOwnerTF.font = [UIFont boldSystemFontOfSize:_fontSize];
    _propOwnerTF.backgroundColor = UIColor.whiteColor;
    _propOwnerTF.tintColor = UIColor.grayColor;
    _propOwnerTF.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    NSString *propOwnerSearchText = [UserDefaults.defaults stringForKey:@"CurrentPropOwnerSearchText"];
    
    if ((propOwnerSearchText) || [propOwnerSearchText isEqualToString:@""])
    {
        _propOwnerTF.text = propOwnerSearchText;
        _propOwnerList = [PropertyData.new getOwnersMatchingString:propOwnerSearchText];
        [_tableView reloadData];
    }
    
    [_propOwnerTF addTarget:self
                     action:@selector(textFieldDidChange:)
           forControlEvents:UIControlEventEditingChanged];
    
    [self.view addSubview:_propOwnerTF];
}

- (void)setupSwitch
{
    _multipleSwitch = UISwitch.new;
    _multipleSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    _multipleSwitch.tintColor = UIColor.redColor;
    _multipleSwitch.backgroundColor = UIColor.redColor;
    _multipleSwitch.layer.cornerRadius = 16.0;
    _multipleSwitch.on = _selectMultiple;
    
    [_multipleSwitch addTarget:self
                        action:@selector(multipleSwitchTapped:)
              forControlEvents:UIControlEventValueChanged];
    
    [self.view addSubview:_multipleSwitch];
    
    _multipleLabel = UILabel.new;
    _multipleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _multipleLabel.text = @"Select Multiple";
    _multipleLabel.backgroundColor = UIColor.clearColor;
    _multipleLabel.textColor = UIColor.whiteColor;
    _multipleLabel.font = [UIFont systemFontOfSize:_fontSize];
    _multipleLabel.adjustsFontSizeToFitWidth = YES;
    _multipleLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    
    [self.view addSubview:_multipleLabel];
}

- (void)setupConstraints
{
    CGFloat margin = 20.0, width = 160.0, height = 60.0;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        margin = 8.0, width = 100.0, height = 48.0;
    
    [_returnButton constrainLeadingToAnchor:self.view.leadingAnchor constant:margin];
    [_returnButton constrainTopToAnchor:self.view.topAnchor constant:margin];
    [_returnButton constrainWidthToConstant:width];
    [_returnButton constrainHeightToConstant:height];
    
    [_multipleLabel constrainLeadingToAnchor:_returnButton.trailingAnchor constant:margin];
    [_multipleLabel constrainBottomToAnchor:_returnButton.bottomAnchor];
    [_multipleLabel constrainWidthToConstant:(width * 0.8)];
    
    [_limitButton constrainTopToAnchor:self.view.topAnchor constant:margin];
    [_limitButton constrainLeadingToAnchor:_multipleLabel.trailingAnchor constant:margin];
    [_limitButton constrainTrailingToAnchor:self.view.trailingAnchor constant:-margin];
    [_limitButton constrainBottomToAnchor:_returnButton.bottomAnchor];
    
    [_multipleSwitch constrainCenterXToAnchor:_multipleLabel.centerXAnchor];
    [_multipleSwitch constrainTopToAnchor:_returnButton.topAnchor];
    [_multipleLabel constrainTopToAnchor:_multipleSwitch.bottomAnchor];
    
    [_propOwnerTF constrainLeadingToAnchor:self.view.leadingAnchor constant:margin];
    [_propOwnerTF constrainTopToAnchor:_returnButton.bottomAnchor constant:margin];
    [_propOwnerTF constrainTrailingToAnchor:self.view.trailingAnchor constant:-margin];
    [_propOwnerTF constrainHeightToConstant:height];
    
    [_tableView constrainLeadingToAnchor:self.view.leadingAnchor constant:margin];
    [_tableView constrainTopToAnchor:_propOwnerTF.bottomAnchor constant:margin];
    [_tableView constrainTrailingToAnchor:self.view.trailingAnchor constant:-margin];
    [_tableView constrainBottomToAnchor:self.view.bottomAnchor constant:-margin];
    
    UIView *leftMarginView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 10.0, height)];
    _propOwnerTF.leftView = leftMarginView;
    _propOwnerTF.leftViewMode = UITextFieldViewModeAlways;
}

- (void)textFieldDidChange:(UITextField *)textField
{
    if ([textField.text isEqualToString:@""])
    {
        [_propOwnerList removeAllObjects];
        [_tableView reloadData];
    }
    
    else
    {
        PropertyData *propData = [[PropertyData alloc] init];
        
        _propOwnerList = [propData getOwnersMatchingString:textField.text];
        [_tableView reloadData];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self dismissTextField];
    return NO;
}

- (void)returnButtonTapped:(UIButton *)button
{
    [self dismissTextField];
    
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}
    
- (void)limitButtonTapped:(UIButton *)button
{
    NVPopoverTableView *nvptv = [NVPopoverTableView showPopoverTableViewInView:self.view
                                                                      delegate:self
                                                                         title:@"Limit To Options"
                                                                     textArray:FindPropertyOwnerViewController.limitToOptions
                                                                 includeCancel:YES];
#pragma unused(nvptv)
}

- (void)popoverTableViewDidCancel:(NVPopoverTableView *)popoverTableView
{
    [popoverTableView hide:YES];
}

- (void)popoverTableView:(NVPopoverTableView *)popoverTableView
    didSelectRowWithText:(NSString *)text
                 atIndex:(NSInteger)index
{
    [popoverTableView hide:YES];
    
    _limitToOption = (LimitToOption)index;
    [UserDefaults.defaults saveNSInteger:index forKey:@"LimitToOption"];
    [self updateLimitButtonTitle];
}

- (void)multipleSwitchTapped:(UISwitch *)theSwitch
{
    _selectMultiple = theSwitch.on;
    [UserDefaults.defaults saveBool:theSwitch.on forKey:@"SelectMultiple"];
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
    static NSString *cellIdentifier = @"CustomCell";
    
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:cellIdentifier];
    }
    
    if (_propOwnerList.count != 0)
    {
        cell.textLabel.text = textBeforeTab(_propOwnerList[indexPath.row]);
        cell.detailTextLabel.text = textAfterLastTab(_propOwnerList[indexPath.row]);
        cell.textLabel.textColor = UIColor.blackColor;
        cell.detailTextLabel.textColor = UIColor.blackColor;
        cell.userInteractionEnabled = YES;
    }
    
    else
    {
        cell.textLabel.text = @"No Property Owners match current search text";
        cell.detailTextLabel.text = @"No Property Owners match current search text";
        cell.textLabel.textColor = UIColor.grayColor;
        cell.detailTextLabel.textColor = UIColor.grayColor;
        cell.userInteractionEnabled = NO;
    }
    
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.detailTextLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:(tableView.rowHeight / 2.0)];
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
        [_delegate findPropOwnerViewController:self
                            didSelectPropOwner:textBeforeTab(_propOwnerList[indexPath.row])
                                           PID:textBeforeTab(textAfterTab(_propOwnerList[indexPath.row]))];
    }
}

@end
