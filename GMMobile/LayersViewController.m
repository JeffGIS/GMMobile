//  LayersViewController.m
//  GMMobile

#import "LayersViewController.h"
#import "ConfigurationControl.h"

@interface LayersViewController ()

@property (nonatomic) NSArray *layerList;
@property (nonatomic) CGFloat rowHeight;

@end

@implementation LayersViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _layerList = ConfigurationControl.sharedInstance.getLayers;
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    _rowHeight = MAX((MAX(self.view.frame.size.width, self.view.bounds.size.height) / 12.0), 60.0);
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
    _tableView.rowHeight = _rowHeight;
    _tableView.layer.borderWidth = (_rowHeight / 24.0);
    _tableView.layer.cornerRadius = 10.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return _layerList.count;
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
    
    if ([_layerList count] != 0)
    {
        LayerObject *layer = (LayerObject *)_layerList[indexPath.row];
        cell.textLabel.text = layer.layerName;
        cell.textLabel.textColor = UIColor.blackColor;
        cell.userInteractionEnabled = YES;
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
    
    else
    {
        cell.textLabel.text = @"No layers in List";
        cell.textLabel.textColor = UIColor.grayColor;
        cell.userInteractionEnabled = NO;
    }
    
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:(_rowHeight / 2.2)];
    return cell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    LayerObject *lo = _layerList[indexPath.row];
    int zoom = 0;
    if ([ConfigurationControl.sharedInstance layer:lo.layerID
                                     visibleAtZoom:CRAPI.sharedInstance.currentZoom])
    {
        zoom = 22;
    }
    
    [ConfigurationControl.sharedInstance setLayer:lo.layerID
                                   visibileAtZoom:zoom];
}

- (void)tableView:(UITableView *)tableView
accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    NSString *theme = _layerList[indexPath.row];
    NSLog(@"Detail Disclosure requested for %@", theme);
}

@end