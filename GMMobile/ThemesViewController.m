//  ThemesViewController.m
//  GMMobile

#import "ThemesViewController.h"
#import "ConfigurationControl.h"

@interface ThemesViewController ()

@property (nonatomic) NSArray *appList;

@end

@implementation ThemesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _appList = [ConfigurationControl sharedInstance].appList;
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    [self setupTableView];
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
    
    CGFloat rowHeight = MAX((MAX(self.view.frame.size.width, self.view.bounds.size.height) / 12.0), 60.0);
    _tableView.rowHeight = rowHeight;
    _tableView.layer.borderWidth = (rowHeight / 24.0);
    _tableView.layer.cornerRadius = 10.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return [[ConfigurationControl sharedInstance].appList count];
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
    
    if ([_appList count] != 0)
    {
        ApplicationObject *app = (ApplicationObject *)_appList[indexPath.row];
        cell.textLabel.text = app.appName;
        cell.textLabel.textColor = UIColor.blackColor;
        cell.userInteractionEnabled = YES;
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        
        UIButton *helpButton = [[UIButton alloc] initWithFrame:CGRectMake((cell.frame.size.height * 0.15),
                                                                          (cell.frame.size.height * 0.15),
                                                                          (cell.frame.size.height * 0.7),
                                                                          (cell.frame.size.height * 0.7))];
        
        [helpButton setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"help"
                                                                                            ofType:@"png"]]
                    forState:UIControlStateNormal];
        
        [cell addSubview:helpButton];
        helpButton.tag = indexPath.row;
        
        [helpButton addTarget:self
                       action:@selector(helpForTheme:)
             forControlEvents:UIControlEventTouchUpInside];
    }
    
    else
    {
        cell.textLabel.text = @"No Apps in List";
        cell.textLabel.textColor = UIColor.grayColor;
        cell.userInteractionEnabled = NO;
    }
    
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:(tableView.rowHeight / 2.2)];
    cell.indentationLevel = 1;
    cell.indentationWidth = cell.frame.size.height;
    return cell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ApplicationObject *app = _appList[indexPath.row];
    
    [ConfigurationControl.sharedInstance setApp:app.appID];
}

- (void)helpForTheme:(UIButton *)button
{
    NSString *theme = _appList[button.tag];
    
    NSLog(@"Help requested for %@", theme);
}

- (void)tableView:(UITableView *)tableView
accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    NSString *theme = _appList[indexPath.row];
    
    NSLog(@"Detail Disclosure requested for %@", theme);
}

@end