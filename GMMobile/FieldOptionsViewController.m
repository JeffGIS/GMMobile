//  FieldOptionsViewController.m
//  GMMobile

#import "FieldOptionsViewController.h"
#import "CCodeLibrary/UserDefaults.h"
#import "PropertyList.h"

@interface FieldOptionsViewController ()

@property (nonatomic) CGFloat rowHeight;
@property (nonatomic) UIImage *checkmark;
@property (nonatomic) UIFont *font;
@property (nonatomic) NSMutableArray *fieldNames;

@end

@implementation FieldOptionsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    _checkmark = UserDefaults.defaults.checkmark;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        _rowHeight = 48.0;
        _font = [UIFont boldSystemFontOfSize:20.0];
    }
    
    else
    {
        _rowHeight = 64.0;
        _font = [UIFont boldSystemFontOfSize:32.0];
    }
    
    PropertyList *proplist = [[PropertyList alloc] init];
    NSArray *fields = [proplist availablePropertyFields];
    
    _fieldNames = NSMutableArray.array;
    
    for (NSNumber *field in fields)
    {
        NSInteger ifield = field.integerValue;
        NSString *fieldName = [proplist propertyFieldName:ifield];
        [_fieldNames addObject:fieldName];
    }
    
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
    return _fieldNames.count;
}

- (UIView *)tableView:(UITableView *)tableView
viewForHeaderInSection:(NSInteger)section
{
    UILabel *headerLabel = UILabel.new;
    headerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    headerLabel.font = _font;
    headerLabel.textColor = UIColor.whiteColor;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.text = @"Select Data Fields";
    
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
    
    [trash.leadingAnchor constraintEqualToAnchor:headerView.leadingAnchor].active = YES;
    [trash.topAnchor constraintEqualToAnchor:headerView.topAnchor].active = YES;
    [trash.bottomAnchor constraintEqualToAnchor:headerView.bottomAnchor].active = YES;
    [trash.widthAnchor constraintEqualToConstant:_rowHeight].active = YES;
    
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
    
    [plus.trailingAnchor constraintEqualToAnchor:headerView.trailingAnchor].active = YES;
    [plus.topAnchor constraintEqualToAnchor:headerView.topAnchor].active = YES;
    [plus.bottomAnchor constraintEqualToAnchor:headerView.bottomAnchor].active = YES;
    [plus.widthAnchor constraintEqualToConstant:_rowHeight].active = YES;
    
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
    
    [list.trailingAnchor constraintEqualToAnchor:plus.leadingAnchor].active = YES;
    [list.topAnchor constraintEqualToAnchor:headerView.topAnchor].active = YES;
    [list.bottomAnchor constraintEqualToAnchor:headerView.bottomAnchor].active = YES;
    [list.widthAnchor constraintEqualToConstant:_rowHeight].active = YES;
    
    UISegmentedControl *options = [[UISegmentedControl alloc] initWithItems:@[@"All", @"Selected"]];
    options.translatesAutoresizingMaskIntoConstraints = NO;
    options.tintColor = UIColor.whiteColor;
    options.selectedSegmentIndex = 0;
    
    [options addTarget:self
                action:@selector(optionsTapped:)
      forControlEvents:UIControlEventValueChanged];
    
    [headerView addSubview:options];
    
    [options.leadingAnchor constraintEqualToAnchor:trash.trailingAnchor].active = YES;
    [options.centerYAnchor constraintEqualToAnchor:headerView.centerYAnchor].active = YES;
    
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
    
    cell.textLabel.text = _fieldNames[indexPath.row];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.textColor = UIColor.blackColor;
    cell.userInteractionEnabled = YES;
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.font = _font;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UIImageView *checkmarkView = [[UIImageView alloc] initWithImage:_checkmark];
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        checkmarkView.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
    
    else
        checkmarkView.frame = CGRectMake(0.0, 0.0, 60.0, 60.0);
    
    cell.accessoryView = checkmarkView;
    
    return cell;
}

@end