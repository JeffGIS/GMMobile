//  FieldOptionsViewController.m
//  GMMobile

#import "FieldOptionsViewController.h"
#import "CCodeLibrary/UserDefaults.h"
#import "PropertyList.h"
#import "FieldList.h"
#import "CCodeLibrary/TableViewCellButton.h"
#import "CCodeLibrary/NVPopoverTableView.h"
#import "CCodeLibrary/NVPopoverSlider.h"

@interface FieldOptionsViewController () <NVPopoverSliderDelegate,
NVPopoverTableViewDelegate,UITextFieldDelegate,UIGestureRecognizerDelegate>

@property CGFloat rowHeight;
@property (nonatomic) UIImage *uncheckedBox, *checkedBox;
@property (nonatomic) UIFont *font, *headerFont, *detailFont;
@property (nonatomic) NSMutableArray *fieldRecords;
@property (nonatomic, copy) NSArray<FieldListRecord *> *fieldlist;
@property PropFieldType lastSelectedType;
@property (nonatomic) UITextField *titleTextField;
@property (nonatomic) UISegmentedControl *options;
@property (nonatomic) UIButton *trash, *plus, *list, *type;
@property BOOL longPressIsActive;
@property NSArray * fieldTypes;

@end

@implementation FieldOptionsViewController

- (void)dealloc
{
    NSLog(@"Field Options dealloc");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;

    _uncheckedBox = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"uncheckedBox"
                                                                                   ofType:@"png"]];
    
    _checkedBox = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"checkedBox"
                                                                                 ofType:@"png"]];
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        _rowHeight = 48.0;
        _font = [UIFont boldSystemFontOfSize:16.0];
        _detailFont = [UIFont boldSystemFontOfSize:12.0];
        _headerFont = [UIFont boldSystemFontOfSize:24.0];
    }
    
    else
    {
        _rowHeight = 64.0;
        _font = [UIFont boldSystemFontOfSize:26.0];
        _detailFont = [UIFont boldSystemFontOfSize:20.0];
        _headerFont = [UIFont boldSystemFontOfSize:40.0];
    }
    
    _fieldlist = [FieldList getFieldListRecords:YES];
    
    CGFloat imageInset = (_rowHeight / 8.0);
    UIEdgeInsets edgeInsets = UIEdgeInsetsMake(imageInset, imageInset, imageInset, imageInset);
    UIEdgeInsets textInsets = UIEdgeInsetsMake(imageInset*2, imageInset*2, imageInset*2, imageInset*2);

    _trash = [UIButton buttonWithType:UIButtonTypeCustom];
    _trash.translatesAutoresizingMaskIntoConstraints = NO;
    _trash.imageEdgeInsets = edgeInsets;
    
    [_trash setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"whiteTrashCan"
                                                                                    ofType:@"png"]]
            forState:UIControlStateNormal];
    
    [_trash addTarget:self
               action:@selector(trashTapped:)
     forControlEvents:UIControlEventTouchUpInside];
    
    _plus = [UIButton buttonWithType:UIButtonTypeCustom];
    _plus.translatesAutoresizingMaskIntoConstraints = NO;
    _plus.imageEdgeInsets = edgeInsets;
    
    [_plus setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"whitePlus"
                                                                                   ofType:@"png"]]
           forState:UIControlStateNormal];
    
    [_plus addTarget:self
              action:@selector(plusTapped:)
    forControlEvents:UIControlEventTouchUpInside];
    
    _list = [UIButton buttonWithType:UIButtonTypeCustom];
    _list.translatesAutoresizingMaskIntoConstraints = NO;
    _list.imageEdgeInsets = edgeInsets;
    
    [_list setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"whiteList"
                                                                                   ofType:@"png"]]
           forState:UIControlStateNormal];
    
    [_list addTarget:self
              action:@selector(listTapped:)
    forControlEvents:UIControlEventTouchUpInside];
    
    _titleTextField = UITextField.new;
    _titleTextField.translatesAutoresizingMaskIntoConstraints = NO;
    _titleTextField.delegate = self;
    _titleTextField.textAlignment = NSTextAlignmentCenter;
    _titleTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _titleTextField.textColor = UIColor.whiteColor;
    _titleTextField.adjustsFontSizeToFitWidth = YES;
    _titleTextField.tintColor = UIColor.lightGrayColor;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        _titleTextField.font = [UIFont boldSystemFontOfSize:20];
    
    else
        _titleTextField.font = [UIFont boldSystemFontOfSize:30];
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        _options = [[UISegmentedControl alloc] initWithItems:@[@"All", @"Sel"]];
    
    else
        _options = [[UISegmentedControl alloc] initWithItems:@[@"All", @"Selected"]];
    
    _options.translatesAutoresizingMaskIntoConstraints = NO;
    _options.tintColor = UIColor.whiteColor;
    _options.selectedSegmentIndex = 0;
    
    [_options addTarget:self
                 action:@selector(optionsTapped:)
       forControlEvents:UIControlEventValueChanged];
    [_options setHidden:YES];
    _type = [UIButton buttonWithType:UIButtonTypeCustom];
    _type.backgroundColor = UIColor.blackColor;
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        _type.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    
    else
        _type.titleLabel.font = [UIFont boldSystemFontOfSize:30];
    
    _type.titleLabel.adjustsFontSizeToFitWidth = YES;
    _type.titleLabel.textAlignment = NSTextAlignmentCenter;
    _type.titleLabel.backgroundColor = UIColor.whiteColor;
    _type.titleEdgeInsets  = textInsets;
    NSString * currentTypes = [UserDefaults.defaults stringForKey:@"FieldTypesToDisplay"];
    if (!currentTypes || !currentTypes.length)
        currentTypes = @"All Types";
    [_type setTitle:currentTypes forState:UIControlStateNormal];
    [_type setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [_type setTitleColor:UIColor.lightGrayColor forState:UIControlStateHighlighted];
    [_type setTitleEdgeInsets:textInsets];
    [_type setBackgroundColor:UIColor.whiteColor];

    [_type addTarget:self
              action:@selector(typeTapped:)
    forControlEvents:UIControlEventTouchUpInside];

    _type.translatesAutoresizingMaskIntoConstraints = NO;

    [self setupTableView];
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
    _tableView.layer.borderWidth = (_rowHeight / 24.0);
    _tableView.layer.cornerRadius = 10.0;
    _tableView.rowHeight = _rowHeight;
    _tableView.sectionHeaderHeight = _rowHeight;
    
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                       action:@selector(tvLongPressed:)];
    
    lpgr.delegate = self;
    [_tableView addGestureRecognizer:lpgr];
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return _fieldlist.count;
}

- (UIView *)tableView:(UITableView *)tableView
viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:
                          CGRectMake(0.0, 0.0, tableView.frame.size.width, _rowHeight)];
    
    headerView.backgroundColor = UIColor.blackColor;
    
    if (![headerView.subviews containsObject:_trash])
    {
        [headerView addSubview:_trash];
        [_trash constrainLeadingToAnchor:headerView.leadingAnchor];
        [_trash constrainTopToAnchor:headerView.topAnchor];
        [_trash constrainBottomToAnchor:headerView.bottomAnchor];
        [_trash constrainWidthToConstant:_rowHeight];
    }
    
    if (![headerView.subviews containsObject:_plus])
    {
        [headerView addSubview:_plus];
        [_plus constrainTrailingToAnchor:headerView.trailingAnchor];
        [_plus constrainTopToAnchor:headerView.topAnchor];
        [_plus constrainBottomToAnchor:headerView.bottomAnchor];
        [_plus constrainWidthToConstant:_rowHeight];
    }
    
    if (![headerView.subviews containsObject:_list])
    {
        [headerView addSubview:_list];
        [_list constrainTrailingToAnchor:_plus.leadingAnchor];
        [_list constrainTopToAnchor:headerView.topAnchor];
        [_list constrainBottomToAnchor:headerView.bottomAnchor];
        [_list constrainWidthToConstant:_rowHeight];
    }
    
    if (![headerView.subviews containsObject:_options])
    {
        [headerView addSubview:_options];
        [_options constrainLeadingToAnchor:_trash.trailingAnchor];
        [_options constrainCenterYToAnchor:headerView.centerYAnchor];
        [_options constrainWidthToConstant:(_rowHeight * 3.0)];
        [_options constrainHeightToConstant:(_rowHeight * 0.6)];
    }
    
    if (![headerView.subviews containsObject:_type])
    {
        [headerView addSubview:_type];
        [_type constrainLeadingToAnchor:_trash.trailingAnchor];
        [_type constrainCenterYToAnchor:headerView.centerYAnchor];
        [_type constrainWidthToConstant:(_rowHeight * 3.0)];
        [_type constrainHeightToConstant:(_rowHeight * 0.6)];
    }
    
    if (![headerView.subviews containsObject:_titleTextField])
    {
        [headerView addSubview:_titleTextField];
        [_titleTextField constrainLeadingToAnchor:_options.trailingAnchor];
        [_titleTextField constrainTrailingToAnchor:_list.leadingAnchor];
        [_titleTextField constrainTopToAnchor:headerView.topAnchor];
        [_titleTextField constrainBottomToAnchor:headerView.bottomAnchor];
    }
    
    _titleTextField.text = FieldList.getCurrentFieldListName;
    
    return headerView;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (![textField.text isEqualToString:FieldList.getCurrentFieldListName])
        [FieldList renameCurrentFieldList:textField.text];
    
    [_tableView reloadData];
}

- (void)trashTapped:(UIButton *)button
{
    NSString *title = [NSString stringWithFormat:@"Are you sure you want to delete %@?",
                       FieldList.getCurrentFieldListName];
    
    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                      delegate:self
                                                         title:title
                                               buttonTextArray:@[@"YES", @"NO"]
                                              destructiveIndex:1];
    
    alert.identifier = @"FieldListDeletePrompt";
}

- (void)alertView:(NVAlertView *)alertView
didTapButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView.identifier isEqualToString:@"FieldListDeletePrompt"])
    {
        if (buttonIndex == 0)
        {
            [FieldList deleteCurrentFieldList];
            _fieldlist = [FieldList getFieldListRecords:YES];
            [_tableView reloadData];
        }
    }
    
    [alertView hideLargeAlertView:YES];
}

- (void)plusTapped:(UIButton *)button
{
    NSMutableArray *fieldLists = FieldList.getFieldLists.mutableCopy;
    [fieldLists insertObject:@"Create from Empty Field List" atIndex:0];
    
    NVPopoverTableView *nvptv =
    [NVPopoverTableView showPopoverTableViewInView:self.view
                                          delegate:self
                                             title:@"Select Field List and Copy as New List"
                                         textArray:fieldLists.copy
                                     includeCancel:YES];
    
    nvptv.identifier = @"CopyToNewList";
}

- (void)listTapped:(UIButton *)button
{
    NVPopoverTableView *nvptv =
    [NVPopoverTableView showPopoverTableViewInView:self.view
                                          delegate:self
                                             title:@"Select Field List"
                                         textArray:FieldList.getFieldLists
                                     includeCancel:YES];
    
    nvptv.identifier = @"SelectFromList";
}

- (void)popoverTableView:(NVPopoverTableView *)popoverTableView
    didSelectRowWithText:(NSString *)text
                 atIndex:(NSInteger)index
{
    if ([popoverTableView.identifier isEqualToString:@"FieldTypes"])
    {
        [_type setTitle:text forState:UIControlStateNormal];
        [UserDefaults.defaults saveString:text forKey:@"FieldTypesToDisplay"];
    }
    else if ([popoverTableView.identifier isEqualToString:@"CopyToNewList"])
    {
        [FieldList createNewFieldList];
        
        if (index)
        {
            for (FieldListRecord *flr in _fieldlist)
            {
                if (flr.sequence > 1)
                {
                    [FieldList setSequenceFor:flr.type
                                         from:0
                                           to:flr.sequence];
                }
            }
        }
    }
    
    else if ([popoverTableView.identifier isEqualToString:@"SelectFromList"])
        [FieldList setCurrentFieldList:text];
    
    _fieldlist = [FieldList getFieldListRecords:YES];
    [_tableView reloadData];
    [popoverTableView hide:YES];
}

- (void)popoverTableViewDidCancel:(NVPopoverTableView *)popoverTableView
{
    [popoverTableView hide:YES];
}

- (void)optionsTapped:(UIButton *)button
{
    return;
}

- (void)typeTapped:(UIButton *)button
{
    _fieldTypes = @[@"All Types",@"Property",@"Demographic",@"Land Use",@"Voting",@"Other"];
    NVPopoverTableView *nvptv = [NVPopoverTableView showPopoverTableViewInView:self.view
                                                                          delegate:self
                                                                             title:@"Select Field Types"
                                                                         textArray:_fieldTypes
                                                                     includeCancel:YES];
    nvptv.identifier = @"FieldTypes";

    return;
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
    
    for (TableViewCellButton *buttons in cell.subviews)
    {
        if ([buttons isKindOfClass:TableViewCellButton.class])
            [buttons removeFromSuperview];
    }
    
    FieldListRecord *flr = _fieldlist[indexPath.row];

    BOOL selected = flr.sequence;
    CGFloat inset = (_rowHeight * 0.1);
    
    TableViewCellButton *checkBox = TableViewCellButton.new;
    checkBox.translatesAutoresizingMaskIntoConstraints = NO;
    checkBox.imageEdgeInsets = UIEdgeInsetsMake(inset, inset, inset, inset);
    checkBox.tag = indexPath.row;
    
    [checkBox addTarget:self
                 action:@selector(checkboxTapped:)
       forControlEvents:UIControlEventTouchUpInside];
    
    [cell addSubview:checkBox];
    [checkBox constrainTrailingToAnchor:cell.trailingAnchor];
    [checkBox constrainHeightToConstant:_rowHeight];
    [checkBox constrainWidthToConstant:_rowHeight];
    
    cell.textLabel.text = textBeforeParentheses(flr.name);
    cell.textLabel.font = _font;
    cell.textLabel.textColor = UIColor.blackColor;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    
    cell.detailTextLabel.text = textInsideParentheses(flr.name).uppercaseString;
    cell.detailTextLabel.font = _detailFont;
    cell.detailTextLabel.textColor = UIColor.blackColor;
    cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    
    if (selected)
    {
        [checkBox setImage:_checkedBox forState:UIControlStateNormal];
        
        if (flr.allowsWeight)
        {
            TableViewCellButton *weight = TableViewCellButton.new;
            weight.translatesAutoresizingMaskIntoConstraints = NO;
            weight.backgroundColor = UserDefaults.defaults.appleGray;
            weight.layer.cornerRadius = 4.0;
            weight.layer.borderColor = UIColor.blackColor.CGColor;
            weight.layer.borderWidth = 1.0;
            weight.tag = indexPath.row;
            weight.titleLabel.textAlignment = NSTextAlignmentCenter;
            weight.titleLabel.font = _detailFont;
            
            [weight setTitle:[NSString stringWithFormat:@"%i", flr.weight]
                    forState:UIControlStateNormal];
            
            [weight setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
            [weight setTitleColor:UIColor.lightGrayColor forState:UIControlStateHighlighted];
            
            [cell addSubview:weight];
            
            [weight addTarget:self
                       action:@selector(weightTapped:)
             forControlEvents:UIControlEventTouchUpInside];
            
            [weight constrainTrailingToAnchor:checkBox.leadingAnchor];
            [weight constrainCenterYToAnchor:cell.centerYAnchor];
            [weight constrainHeightToConstant:(_rowHeight * 0.75)];
        }
    }
    
    else
        [checkBox setImage:_uncheckedBox forState:UIControlStateNormal];
    if (flr.insertAfter)
    {
        UIImage * image = [UIImage imageNamed:@"digitize.png"];
        cell.imageView.image = image;
        _lastSelectedType = flr.type;
    }
    else
        cell.imageView.image = nil;

    return cell;
}

- (void)weightTapped:(UIButton *)button
{
    FieldListRecord *flr = _fieldlist[button.tag];
    NSString *title = [NSString stringWithFormat:@"Weight for %@", flr.name];
    
    NVPopoverSlider *nvps = [NVPopoverSlider showPopoverSliderInView:self.view
                                                            minValue:-100.0
                                                            maxValue:100.0
                                                          startValue:button.titleLabel.text.intValue
                                                            delegate:self
                                                                 tag:button.tag
                                                               title:title];
#pragma unused(nvps)
}

- (void)popoverSliderDidCancel:(NVPopoverSlider *)popoverSlider
{
    [popoverSlider hidePopoverSliderView:YES];
}

- (void)popoverSlider:(NVPopoverSlider *)popoverSlider
       didReturnValue:(double)value
                  tag:(NSInteger)tag
{
    [popoverSlider hidePopoverSliderView:YES];
    FieldListRecord *flr = _fieldlist[tag];

    [FieldList setWeightFor:flr.type
                         to:(int)round(value)];
    
    _fieldlist = [FieldList getFieldListRecords:YES];
    [_tableView reloadData];
}

- (void)checkboxTapped:(UIButton *)button
{
    int row = (int)button.tag;
    FieldListRecord *flr = _fieldlist[row];
    
    if (flr.sequence != 1)
    {
        _lastSelectedType = flr.type;
        
        [FieldList setSequenceFor:flr.type
                             from:flr.sequence
                               to:0];
        
        _fieldlist = [FieldList getFieldListRecords:YES];
        [_tableView reloadData];
    }
}

- (void)cellLongPressed:(int)row
{
    FieldListRecord *flr = _fieldlist[row];
    
    _lastSelectedType = flr.type;
    
    [FieldList setInsertAfterTo:flr.type];
    
    _fieldlist = [FieldList getFieldListRecords:YES];
    [_tableView reloadData];
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!_longPressIsActive)
    {
        int row = (int)indexPath.row;
        FieldListRecord *flr = _fieldlist[row];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        if (row > 0 && flr.sequence > 0)
        {
            int fromseq = flr.sequence;
            int newseq = [FieldList getInsertSequence];
            [FieldList setSequenceFor:flr.type
                                 from:fromseq
                                   to:newseq];
            
            _fieldlist = [FieldList getFieldListRecords:YES];
            [_tableView reloadData];
        }
    }
}

- (void)tvLongPressed:(UILongPressGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        _longPressIsActive = YES;
        CGPoint point = [gesture locationInView:_tableView];
        
        NSIndexPath *indexPath = [_tableView indexPathForRowAtPoint:point];
        [self cellLongPressed:(int)indexPath.row];
    }
    
    else if (gesture.state == UIGestureRecognizerStateEnded)
        _longPressIsActive = NO;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return ([gestureRecognizer locationInView:_tableView].y > _rowHeight);
}

@end
