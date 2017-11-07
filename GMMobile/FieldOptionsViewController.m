//  FieldOptionsViewController.m
//  GMMobile

#import "FieldOptionsViewController.h"
#import "CCodeLibrary/UserDefaults.h"
#import "PropertyList.h"
#import "FieldList.h"
#import "CCodeLibrary/TableViewCellButton.h"
#import "CCodeLibrary/NVPopoverTableView.h"
#import "CCodeLibrary/NVPopoverSlider.h"

@interface FieldOptionsViewController () <NVPopoverSliderDelegate,NVPopoverTableViewDelegate>

@property (nonatomic) CGFloat rowHeight;
@property (nonatomic) UIImage *uncheckedBox, *checkedBox;
@property (nonatomic) UIFont *font, *headerFont;
@property (nonatomic) NSMutableArray *fieldRecords;
@property (nonatomic) NSArray *fieldlist;
@property PropFieldType lastSelectedType;

@end

@implementation FieldOptionsViewController

- (void)dealloc
{
    NSLog(@"Boundary Database dealloc");
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
        _headerFont = [UIFont boldSystemFontOfSize:24.0];
    }
    
    else
    {
        _rowHeight = 64.0;
        _font = [UIFont boldSystemFontOfSize:26.0];
        _headerFont = [UIFont boldSystemFontOfSize:40.0];
    }
    
    _fieldlist = [FieldList getFieldListRecords:YES];
    
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
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return _fieldlist.count;
}

- (UIView *)tableView:(UITableView *)tableView
viewForHeaderInSection:(NSInteger)section
{
    UILabel *headerLabel = UILabel.new;
    headerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    headerLabel.font = _headerFont;
    headerLabel.textColor = UIColor.whiteColor;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    
    UIView *headerView = [[UIView alloc] initWithFrame:
                          CGRectMake(0.0, 0.0, tableView.frame.size.width, _rowHeight)];
    
    [headerView addSubview:headerLabel];
    [headerLabel constrainToView:headerView leading:0.0 trailing:0.0 top:0.0 bottom:0.0];
    headerView.backgroundColor = UIColor.blackColor;
    
    CGFloat imageInset = (_rowHeight / 8.0);
    UIEdgeInsets edgeInsets = UIEdgeInsetsMake(imageInset, imageInset, imageInset, imageInset);
    
    UIButton *trash = [UIButton buttonWithType:UIButtonTypeCustom];
    trash.translatesAutoresizingMaskIntoConstraints = NO;
    trash.imageEdgeInsets = edgeInsets;
    
    [trash setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"whiteTrashCan"
                                                                                   ofType:@"png"]]
           forState:UIControlStateNormal];
    
    [trash addTarget:self
              action:@selector(trashTapped:)
    forControlEvents:UIControlEventTouchUpInside];
    
    [headerView addSubview:trash];
    [trash constrainLeadingToAnchor:headerView.leadingAnchor];
    [trash constrainTopToAnchor:headerView.topAnchor];
    [trash constrainBottomToAnchor:headerView.bottomAnchor];
    [trash constrainWidthToConstant:_rowHeight];
    
    UIButton *plus = [UIButton buttonWithType:UIButtonTypeCustom];
    plus.translatesAutoresizingMaskIntoConstraints = NO;
    plus.imageEdgeInsets = edgeInsets;
    
    [plus setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"whitePlus"
                                                                                  ofType:@"png"]]
          forState:UIControlStateNormal];
    
    [plus addTarget:self
             action:@selector(plusTapped:)
   forControlEvents:UIControlEventTouchUpInside];
    
    [headerView addSubview:plus];
    [plus constrainTrailingToAnchor:headerView.trailingAnchor];
    [plus constrainTopToAnchor:headerView.topAnchor];
    [plus constrainBottomToAnchor:headerView.bottomAnchor];
    [plus constrainWidthToConstant:_rowHeight];
    
    UIButton *list = [UIButton buttonWithType:UIButtonTypeCustom];
    list.translatesAutoresizingMaskIntoConstraints = NO;
    list.imageEdgeInsets = edgeInsets;
    
    [list setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"whiteList"
                                                                                  ofType:@"png"]]
          forState:UIControlStateNormal];
    
    [list addTarget:self
             action:@selector(listTapped:)
   forControlEvents:UIControlEventTouchUpInside];
    
    [headerView addSubview:list];
    [list constrainTrailingToAnchor:plus.leadingAnchor];
    [list constrainTopToAnchor:headerView.topAnchor];
    [list constrainBottomToAnchor:headerView.bottomAnchor];
    [list constrainWidthToConstant:_rowHeight];
    
    UISegmentedControl *options = nil;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        options = [[UISegmentedControl alloc] initWithItems:@[@"All", @"Sel"]];
        headerLabel.text = @"Fields";
    }
    
    else
    {
        options = [[UISegmentedControl alloc] initWithItems:@[@"All", @"Selected"]];
        headerLabel.text = [FieldList getCurrentFieldListName];
    }
    
    options.translatesAutoresizingMaskIntoConstraints = NO;
    options.tintColor = UIColor.whiteColor;
    options.selectedSegmentIndex = 0;
    
    [options addTarget:self
                action:@selector(optionsTapped:)
      forControlEvents:UIControlEventValueChanged];
    
    [headerView addSubview:options];
    [options constrainLeadingToAnchor:trash.trailingAnchor];
    [options constrainCenterYToAnchor:headerView.centerYAnchor];
    
    return headerView;
}

- (void)trashTapped:(UIButton *)button
{
    
}

- (void)plusTapped:(UIButton *)button
{
    
}

- (void)listTapped:(UIButton *)button
{
    NSArray * fieldLists = [FieldList getFieldLists];
    [NVPopoverTableView showPopoverTableViewInView:self.view
                                          delegate:self
                                             title:@"Field Selection Lists"
                                         textArray:fieldLists
                                     includeCancel:YES];
    return;

}

- (void)popoverTableView:(NVPopoverTableView *)popoverTableView
    didSelectRowWithText:(NSString *)text
                 atIndex:(NSInteger)index
{
    [popoverTableView hide:YES];
    
}

- (void)popoverTableViewDidCancel:(NVPopoverTableView *)popoverTableView
{
    [popoverTableView hide:YES];
}



- (void)optionsTapped:(UIButton *)button
{
    
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
    
    for (TableViewCellButton *buttons in cell.subviews)
    {
        if ([buttons isKindOfClass:TableViewCellButton.class])
            [buttons removeFromSuperview];
    }
    
    for (TableViewCellLabel *labels in cell.subviews)
    {
        if ([labels isKindOfClass:TableViewCellLabel.class])
            [labels removeFromSuperview];
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
    
    TableViewCellLabel *label = TableViewCellLabel.new;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.adjustsFontSizeToFitWidth = YES;
    label.textColor = UIColor.blackColor;
    label.text = flr.name;
    label.font = _font;
    
    [cell addSubview:label];
    [label constrainTopToAnchor:cell.topAnchor];
    [label constrainBottomToAnchor:cell.bottomAnchor];
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        [label constrainLeadingToAnchor:cell.leadingAnchor constant:inset];
    
    else
        [label constrainLeadingToAnchor:cell.leadingAnchor constant:(inset * 2.0)];
    
    if (selected)
    {
        [checkBox setImage:_checkedBox
                  forState:UIControlStateNormal];
        
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
            weight.titleLabel.font = _font;
            
            [weight setTitle:[NSString stringWithFormat:@"%i", flr.weight]
                    forState:UIControlStateNormal];
            
            [weight setTitleColor:UIColor.blackColor
                         forState:UIControlStateNormal];
            
            [weight setTitleColor:UIColor.lightGrayColor
                         forState:UIControlStateHighlighted];
            
            [cell addSubview:weight];
            
            [weight addTarget:self
                       action:@selector(weightTapped:)
             forControlEvents:UIControlEventTouchUpInside];
            
            [weight constrainTrailingToAnchor:checkBox.leadingAnchor];
            [weight constrainCenterYToAnchor:cell.centerYAnchor];
            [weight constrainHeightToConstant:(_rowHeight * 0.75)];
            
            if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
                [weight constrainWidthToConstant:(_rowHeight * 0.85)];
            
            else
                [weight constrainWidthToConstant:(_rowHeight * 1.15)];
            
            [label constrainTrailingToAnchor:weight.leadingAnchor];
        }
    }
    
    else
    {
        [checkBox setImage:_uncheckedBox
                  forState:UIControlStateNormal];
        
        [label constrainTrailingToAnchor:checkBox.leadingAnchor];
    }
    
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

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row = (int)indexPath.row;
    FieldListRecord *flr = _fieldlist[row];
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
    if (_lastSelectedType && row > 0 && flr.sequence > 0)
    {
        int fromseq = [FieldList getSequenceFor:_lastSelectedType];
        [FieldList setSequenceFor:_lastSelectedType
                             from:fromseq
                               to:row+1];
        _fieldlist = [FieldList getFieldListRecords:YES];
        
        [_tableView reloadData];
    }

}

@end
