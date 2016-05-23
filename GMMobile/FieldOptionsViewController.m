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
        _rowHeight = 60.0;
        _font = [UIFont boldSystemFontOfSize:22.0];
    }
    
    else
    {
        _rowHeight = 76.0;
        _font = [UIFont boldSystemFontOfSize:36.0];
    }
    
    PropertyList *proplist = [[PropertyList alloc] init];
    NSArray *fields = [proplist availablePropertyFields];
    
    _fieldNames = [[NSMutableArray alloc] init];
    
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
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:
                            CGRectMake(0.0, 0.0, tableView.frame.size.width, _rowHeight)];
    
    headerLabel.font = _font;
    headerLabel.textColor = UIColor.whiteColor;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.text = @"Select Data Fields";
    
    UIView *headerView = [[UIView alloc] initWithFrame:
                          CGRectMake(0.0, 0.0, tableView.frame.size.width, _rowHeight)];
    
    [headerView addSubview:headerLabel];
    headerView.backgroundColor = UIColor.blackColor;
    
    return headerView;
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