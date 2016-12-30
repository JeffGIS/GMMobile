//  FindPropertyOwnerViewController.m
//  GMMobile

#import "FindPropertyOwnerViewController.h"
#import "CCodeLibrary/NVPopoverTableView.h"

@interface FindPropertyOwnerViewController () <UITextFieldDelegate,UITableViewDataSource,UITableViewDelegate,NVPopoverTableViewDelegate>

@property (nonatomic) NSMutableArray *propOwnerList;
@property (nonatomic) NVConstrainedButton *returnButton, *limitButton;
@property (nonatomic) NVConstrainedTextField *propOwnerTF;
@property (nonatomic) NVConstrainedTableView *tableView;
@property (nonatomic) NVConstrainedSwitch *multipleSwitch;
@property (nonatomic) NVConstrainedLabel *multipleLabel, *countLabel;
@property (nonatomic) CGFloat fontSize, cornerRadius;
@property LimitToOption limitToOption;

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
    _tableView = NVConstrainedTableView.new;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    CGFloat rowHeight = MAX((MAX(self.view.frame.size.width, self.view.bounds.size.height) / 16.0), 40.0);
    _tableView.rowHeight = rowHeight;
    _tableView.layer.borderWidth = (rowHeight / 20.0);
    _tableView.layer.cornerRadius = _cornerRadius;
    _tableView.allowsMultipleSelection = [UserDefaults.defaults boolForKey:@"SelectMultiple"];
    
    [self.view addSubview:_tableView];
}

- (void)setupButtons
{
    _returnButton = NVConstrainedButton.new;
    _returnButton.titleLabel.font = [UIFont boldSystemFontOfSize:_fontSize];
    _returnButton.layer.cornerRadius = _cornerRadius;
    
    [_returnButton setTitle:@"< Return"
                   forState:UIControlStateNormal];
    
    [_returnButton addTarget:self
                      action:@selector(returnButtonTapped:)
            forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_returnButton];
    
    _limitButton = NVConstrainedButton.new;
    _limitButton.titleLabel.font = [UIFont boldSystemFontOfSize:_fontSize];
    _limitButton.layer.cornerRadius = _cornerRadius;
    
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
    _propOwnerTF = NVConstrainedTextField.new;
    _propOwnerTF.delegate = self;
    _propOwnerTF.layer.borderWidth = (_tableView.rowHeight / 20.0);
    _propOwnerTF.layer.cornerRadius = _cornerRadius;
    _propOwnerTF.font = [UIFont boldSystemFontOfSize:_fontSize];
    _propOwnerTF.autocapitalizationType = UITextAutocapitalizationTypeWords;
    _propOwnerTF.spellCheckingType = UITextSpellCheckingTypeNo;
    _propOwnerTF.autocorrectionType = UITextAutocorrectionTypeNo;
    
    NSString *propOwnerSearchText = [UserDefaults.defaults stringForKey:@"CurrentPropOwnerSearchText"];
    
    if ((propOwnerSearchText) || [propOwnerSearchText isEqualToString:@""])
    {
        CRAPI.sharedInstance.keepProcessing++;
        _propOwnerTF.text = propOwnerSearchText;
        PropertyData *propData = [[PropertyData alloc] init];
        propData.processingID = CRAPI.sharedInstance.keepProcessing;
        propData.delegate = self;
        [propData getOwnersMatchingString:propOwnerSearchText];
        
    }
    
    [_propOwnerTF addTarget:self
                     action:@selector(textFieldDidChange:)
           forControlEvents:UIControlEventEditingChanged];
    
    [self.view addSubview:_propOwnerTF];
}

- (void)reloadTable
{
    [_tableView reloadData];
    
    if (_tableView.allowsMultipleSelection)
    {
        _countLabel.text = [NSString stringWithFormat:@"%i properties in list, %i selected.",
                            _propOwnerList.count, _tableView.indexPathsForSelectedRows.count];
    }
    
    else
    {
        _countLabel.text = [NSString stringWithFormat:@"%i properties in list.",
                            _propOwnerList.count];
    }
}

- (void)matchingOwners:(NSMutableArray *)ownerArray
{
    _propOwnerList = ownerArray.copy;
    
    [self performSelectorOnMainThread:@selector(reloadTable)
                           withObject:nil
                        waitUntilDone:NO];
}

- (void)setupSwitch
{
    _multipleSwitch = NVConstrainedSwitch.new;
    _multipleSwitch.backgroundColor = UIColor.redColor;
    _multipleSwitch.layer.cornerRadius = 16.0;
    _multipleSwitch.on = _tableView.allowsMultipleSelection;
    
    [_multipleSwitch addTarget:self
                        action:@selector(multipleSwitchTapped:)
              forControlEvents:UIControlEventValueChanged];
    
    [self.view addSubview:_multipleSwitch];
    
    UIFont *font = [UIFont systemFontOfSize:24.0];
    
    _multipleLabel = NVConstrainedLabel.new;
    _multipleLabel.text = @"Select Multiple";
    _multipleLabel.font = font;
    [self.view addSubview:_multipleLabel];
    
    _countLabel = NVConstrainedLabel.new;
    _countLabel.font = font;
    _countLabel.text = @" ";
    [self.view addSubview:_countLabel];
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
    
    [_countLabel constrainLeadingToAnchor:self.view.leadingAnchor];
    [_countLabel constrainTrailingToAnchor:self.view.trailingAnchor];
    [_countLabel constrainTopToAnchor:_propOwnerTF.bottomAnchor];
    
    [_tableView constrainLeadingToAnchor:self.view.leadingAnchor constant:margin];
    [_tableView constrainTopToAnchor:_countLabel.bottomAnchor];
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
        _propOwnerList = nil;
        [_tableView reloadData];
    }
    
    else
    {
        CRAPI.sharedInstance.keepProcessing++;
        PropertyData *propData = [[PropertyData alloc] init];
        propData.processingID = CRAPI.sharedInstance.keepProcessing;
        propData.delegate = self;
        [propData getOwnersMatchingString:textField.text];
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
    
    if (_delegate && _tableView.allowsMultipleSelection && _tableView.indexPathsForSelectedRows.count)
    {
        if (_tableView.indexPathsForSelectedRows.count == 1)
        {
            NSIndexPath *indexPath = _tableView.indexPathsForSelectedRows[0];
            
            [_delegate findPropOwnerViewController:self
                                didSelectPropOwner:textBeforeTab(_propOwnerList[indexPath.row])
                                               PID:textBeforeTab(textAfterTab(_propOwnerList[indexPath.row]))];
        }
        
        else
        {
            NSMutableArray<PropertyRecord *> *prArray = NSMutableArray.array;
            
            for (NSIndexPath *indexPath in _tableView.indexPathsForSelectedRows)
            {
                NSString *pin = textBeforeTab(textAfterTab(_propOwnerList[indexPath.row]));
                NSString *propOwner = textBeforeTab(_propOwnerList[indexPath.row]);
                PropertyData *propData = PropertyData.new;
                LLPOINT point = [propData getPointForPID:pin];
                CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(point.lat, point.lon);
                
                PropertyRecord *propRec = [PropertyRecord propertyRecordWithPin:pin
                                                                      propOwner:propOwner
                                                                     coordinate:coord];
                
                [prArray addObject:propRec];
            }
            
            [_delegate findPropOwnerViewController:self
                            didSelectMultipleProps:prArray];
        }
    }
    
    else
    {
        [self dismissViewControllerAnimated:YES
                                 completion:nil];
    }
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
    [UserDefaults.defaults saveBool:theSwitch.on forKey:@"SelectMultiple"];
    _tableView.allowsMultipleSelection = theSwitch.on;
    
    if (!theSwitch.on)
    {
        [_returnButton setTitle:@"< Return"
                       forState:UIControlStateNormal];
        
        _countLabel.text = [NSString stringWithFormat:@"%i properties in list.",
                            _propOwnerList.count];
    }
    
    else
    {
        _countLabel.text = [NSString stringWithFormat:@"%i properties in list, %i selected.",
                            _propOwnerList.count, _tableView.indexPathsForSelectedRows.count];
    }
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
    
    if (tableView.allowsMultipleSelection)
    {
        [_returnButton setTitle:@"Go to Map"
                       forState:UIControlStateNormal];
        
        _countLabel.text = [NSString stringWithFormat:@"%i properties in list, %i selected.",
                            _propOwnerList.count, _tableView.indexPathsForSelectedRows.count];
    }
    
    else if (_delegate)
    {
        [_delegate findPropOwnerViewController:self
                            didSelectPropOwner:textBeforeTab(_propOwnerList[indexPath.row])
                                           PID:textBeforeTab(textAfterTab(_propOwnerList[indexPath.row]))];
    }
}

- (void)tableView:(UITableView *)tableView
didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!tableView.indexPathsForSelectedRows.count)
    {
        [_returnButton setTitle:@"< Return"
                       forState:UIControlStateNormal];
    }
    
    _countLabel.text = [NSString stringWithFormat:@"%i properties in list, %i selected.",
                        _propOwnerList.count, _tableView.indexPathsForSelectedRows.count];
}

@end
