//  FindPropertyOwnerViewController.m
//  GMMobile

#import "FindPropertyOwnerViewController.h"
#import "CCodeLibrary/NVPopoverTableView.h"

@interface FindPropertyOwnerViewController () <UITextFieldDelegate,UITableViewDataSource,UITableViewDelegate,NVPopoverTableViewDelegate,UIGestureRecognizerDelegate>

@property (nonatomic) NSMutableArray *propOwnerList;
@property (nonatomic) NVConstrainedButton *returnButton, *limitButton, *actionButton;
@property (nonatomic) NVConstrainedTextField *propOwnerTF;
@property (nonatomic) NVConstrainedTableView *tableView;
@property (nonatomic) NVConstrainedSwitch *multipleSwitch;
@property (nonatomic) NVConstrainedLabel *multipleLabel, *countLabel;
@property (nonatomic) CGFloat fontSize, cornerRadius;
@property LimitToOption limitToOption;
@property ActionOption actionOption;
@property int lastRowTapped;

@end

@implementation FindPropertyOwnerViewController

+ (NSArray *)limitToOptions
{
    BoundaryData *bd = [[BoundaryData alloc] init];
    [bd setCityAndCounty];
    
    return @[@"No Limit", @"Current Display Bounds", [NSString stringWithFormat:@"Current City (%@)", CRAPI.sharedInstance.currentCity],
             [NSString stringWithFormat: @"Current County (%@)", CRAPI.sharedInstance.currentCountyName]];
}

+ (NSArray *)actionOptions
{
    NSMutableArray *options = NSMutableArray.array;
    [options addObject:@"Add to Map"];
    [options addObject:@"Clear and Add to Map"];
    [options addObject:@"Add to New Property List"];
    
    for (NSString *props in PropertyList.getPropertyLists)
        [options addObject:[NSString stringWithFormat:@"Add to %@", props]];
    
    return options.copy;
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
    _actionOption = [UserDefaults.defaults integerForKey:@"ActionOption"];
    _lastRowTapped = 0;
    
    if (_actionOption >= FindPropertyOwnerViewController.actionOptions.count)
    {
        _actionOption = (FindPropertyOwnerViewController.actionOptions.count - 1);
        [UserDefaults.defaults saveNSInteger:_actionOption forKey:@"ActionOption"];
    }
    
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
    CGFloat rowHeight = MAX((MAX(self.view.frame.size.width, self.view.bounds.size.height) / 16.0), 40.0);
    _tableView = NVConstrainedTableView.new;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.rowHeight = rowHeight;
    _tableView.layer.borderWidth = (rowHeight / 20.0);
    _tableView.layer.cornerRadius = _cornerRadius;
    _tableView.allowsMultipleSelection = [UserDefaults.defaults boolForKey:@"SelectMultiple"];
    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(tvLongPressed:)];
    lp.delegate = self;
    [_tableView addGestureRecognizer:lp];
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
    
    _actionButton = NVConstrainedButton.new;
    _actionButton.titleLabel.font = [UIFont boldSystemFontOfSize:_fontSize];
    _actionButton.layer.cornerRadius = _cornerRadius;
    [self updateActionButtonTitle];
    
    if (!_tableView.allowsMultipleSelection)
    {
        _actionButton.alpha = 0.4;
        _actionButton.enabled = NO;
    }
    
    [_actionButton addTarget:self
                      action:@selector(actionButtonTapped:)
            forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_actionButton];
}

- (void)updateLimitButtonTitle
{
    [_limitButton setTitle:[NSString stringWithFormat:@"Limit To: %@",
                            FindPropertyOwnerViewController.limitToOptions[_limitToOption]]
                  forState:UIControlStateNormal];
}

- (void)updateActionButtonTitle
{
    [_actionButton setTitle:[NSString stringWithFormat:@"Action: %@",
                             FindPropertyOwnerViewController.actionOptions[_actionOption]]
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
        [propData getOwnersMatchingString:propOwnerSearchText limitTo:_limitToOption];
        
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
                            (int)_propOwnerList.count, (int)_tableView.indexPathsForSelectedRows.count];
    }
    
    else
    {
        _countLabel.text = [NSString stringWithFormat:@"%i properties in list.",
                            (int)_propOwnerList.count];
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
    
    UIFont *font = [UIFont systemFontOfSize:24.0];
    _multipleLabel = NVConstrainedLabel.new;
    _multipleLabel.text = @"Select Multiple";
    _multipleLabel.font = font;
    
    _countLabel = NVConstrainedLabel.new;
    _countLabel.font = font;
    _countLabel.text = @" ";
    [self.view addSubview:_countLabel];
}

- (void)setupConstraints
{
    CGFloat margin = 20.0, width = 160.0, height = 60.0;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        margin = 8.0, width = 100.0, height = 46.0;
    
    [_returnButton constrainLeadingToAnchor:self.view.leadingAnchor constant:margin];
    [_returnButton constrainTopToAnchor:self.view.topAnchor constant:margin];
    [_returnButton constrainWidthToConstant:width];
    [_returnButton constrainHeightToConstant:height];
    
    [_actionButton constrainLeadingToAnchor:_returnButton.trailingAnchor constant:(margin * 0.5)];
    [_actionButton constrainTopToAnchor:_returnButton.topAnchor];
    [_actionButton constrainTrailingToAnchor:self.view.trailingAnchor constant:-margin];
    [_actionButton constrainBottomToAnchor:_returnButton.bottomAnchor];
    
    NVConstrainedView *container = NVConstrainedView.new;
    container.layer.cornerRadius = _cornerRadius;
    [self.view addSubview:container];
    [container constrainLeadingToAnchor:_returnButton.leadingAnchor];
    [container constrainTopToAnchor:_returnButton.bottomAnchor constant:(margin * 0.5)];
    [container constrainTrailingToAnchor:_returnButton.trailingAnchor];
    [container constrainHeightToConstant:height * 1.25];
    
    [container addSubview:_multipleLabel];
    [_multipleLabel constrainBottomToAnchor:container.bottomAnchor constant:(-margin * 0.25)];
    [_multipleLabel constrainLeadingToAnchor:container.leadingAnchor constant:(margin * 0.5)];
    [_multipleLabel constrainTrailingToAnchor:container.trailingAnchor constant:(-margin * 0.5)];
    [container addSubview:_multipleSwitch];
    [_multipleSwitch constrainTopToAnchor:container.topAnchor constant:(margin * 0.5)];
    [_multipleSwitch constrainCenterXToAnchor:_multipleLabel.centerXAnchor];
    [_multipleLabel constrainTopToAnchor:_multipleSwitch.bottomAnchor constant:(margin * 0.25)];
    
    [_limitButton constrainLeadingToAnchor:_actionButton.leadingAnchor];
    [_limitButton constrainTrailingToAnchor:_actionButton.trailingAnchor];
    [_limitButton constrainTopToAnchor:container.topAnchor];
    [_limitButton constrainBottomToAnchor:container.bottomAnchor];

    [_propOwnerTF constrainLeadingToAnchor:_returnButton.leadingAnchor];
    [_propOwnerTF constrainTopToAnchor:container.bottomAnchor constant:(margin * 0.5)];
    [_propOwnerTF constrainTrailingToAnchor:_limitButton.trailingAnchor];
    [_propOwnerTF constrainHeightToConstant:height];
    
    [_countLabel constrainLeadingToAnchor:_returnButton.leadingAnchor];
    [_countLabel constrainTrailingToAnchor:_limitButton.trailingAnchor];
    [_countLabel constrainTopToAnchor:_propOwnerTF.bottomAnchor];
    
    [_tableView constrainLeadingToAnchor:_returnButton.leadingAnchor];
    [_tableView constrainTopToAnchor:_countLabel.bottomAnchor];
    [_tableView constrainTrailingToAnchor:_limitButton.trailingAnchor];
    [_tableView constrainBottomToAnchor:self.view.bottomAnchor constant:-margin];
    
    UIView *leftMarginView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 10.0, height)];
    _propOwnerTF.leftView = leftMarginView;
    _propOwnerTF.leftViewMode = UITextFieldViewModeAlways;
}

- (void)processText
{
    NSString *inputText = _propOwnerTF.text;
    
    if ([inputText isEqualToString:@""])
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
        [propData getOwnersMatchingString:inputText limitTo:_limitToOption];
        [_tableView reloadData];
    }
}

- (void)textFieldDidChange:(UITextField *)textField
{
    [self processText];
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
        switch (_actionOption)
        {
            case ActionOptionAddToMap:
                
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
                                    didSelectMultipleProps:prArray.copy];
                }
                
                break;
            case ActionOptionAddToNewPropList:
            {
                [PropertyList createNewPropertyList];
                PropertyList *pl = PropertyList.new;
                for (NSIndexPath *indexPath in _tableView.indexPathsForSelectedRows)
                {
                    NSString *pin = textBeforeTab(textAfterTab(_propOwnerList[indexPath.row]));
                    [pl addParcelToPropertyList:pin popover:nil];
                }
                [self dismissViewControllerAnimated:YES
                                         completion:nil];
                
            }
                break;
            case ActionOptionClearAndAddToMap:
                break;
            default:
                break;
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
    nvptv.identifier = @"LimitTo";
}

- (void)actionButtonTapped:(UIButton *)button
{
    NVPopoverTableView *nvptv = [NVPopoverTableView showPopoverTableViewInView:self.view
                                                                      delegate:self
                                                                         title:@"Action Options"
                                                                     textArray:FindPropertyOwnerViewController.actionOptions
                                                                 includeCancel:YES];
    nvptv.identifier = @"Action";
}

- (void)popoverTableViewDidCancel:(NVPopoverTableView *)popoverTableView
{
    [popoverTableView hide:YES];
}

- (void)popoverTableView:(NVPopoverTableView *)popoverTableView
    didSelectRowWithText:(NSString *)text
                 atIndex:(NSInteger)index
{
    if ([popoverTableView.identifier isEqualToString:@"LimitTo"])
    {
        _limitToOption = (LimitToOption)index;
        [UserDefaults.defaults saveNSInteger:index forKey:@"LimitToOption"];
        [self updateLimitButtonTitle];
        [self processText];
    }
    
    else
    {
        _actionOption = (ActionOption)index;
        [UserDefaults.defaults saveNSInteger:index forKey:@"ActionOption"];
        [self updateActionButtonTitle];
    }
    
    [popoverTableView hide:YES];
}

- (void)multipleSwitchTapped:(UISwitch *)theSwitch
{
    [UserDefaults.defaults saveBool:theSwitch.on forKey:@"SelectMultiple"];
    _tableView.allowsMultipleSelection = theSwitch.on;
    
    if (!theSwitch.on)
    {
        [_returnButton setTitle:@"< Return" forState:UIControlStateNormal];
        _actionButton.alpha = 0.4;
        _actionButton.enabled = NO;
        
        _countLabel.text = [NSString stringWithFormat:@"%lu properties in list.",
                            (unsigned long)_propOwnerList.count];
    }
    
    else
    {
        _actionButton.alpha = 1.0;
        _actionButton.enabled = YES;
        
        _countLabel.text = [NSString stringWithFormat:@"%i properties in list, %i selected.",
                            (int)_propOwnerList.count, (int)_tableView.indexPathsForSelectedRows.count];
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
    cell.layer.borderColor = UIColor.blackColor.CGColor;
    cell.layer.borderWidth = 1.0;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self dismissTextField];
    _lastRowTapped = (int)indexPath.row;
    
    if (tableView.allowsMultipleSelection)
    {
        [_returnButton setTitle:@"Take Action" forState:UIControlStateNormal];
        
        _countLabel.text = [NSString stringWithFormat:@"%i properties in list, %i selected.",
                            (int)_propOwnerList.count, (int)_tableView.indexPathsForSelectedRows.count];
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
    _lastRowTapped = (int)indexPath.row;
    
    if (!tableView.indexPathsForSelectedRows.count)
        [_returnButton setTitle:@"< Return" forState:UIControlStateNormal];
    
    _countLabel.text = [NSString stringWithFormat:@"%i properties in list, %i selected.",
                        (int)_propOwnerList.count, (int)_tableView.indexPathsForSelectedRows.count];
}

- (void)tvLongPressed:(UILongPressGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        CGPoint point = [gesture locationInView:gesture.view];
        int row = (point.y / _tableView.rowHeight);
        int start = MIN(row, _lastRowTapped);
        int stop  = MAX(row, _lastRowTapped);
        NSArray<NSIndexPath *> *selectedRows = _tableView.indexPathsForSelectedRows;
        
        for (int i = start; i <= stop; i++)
        {
            if (i == _lastRowTapped)
                continue;
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            
            if ([selectedRows containsObject:indexPath])
                [_tableView deselectRowAtIndexPath:indexPath animated:NO];
            
            else
                [_tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        
        _lastRowTapped = 0;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end
