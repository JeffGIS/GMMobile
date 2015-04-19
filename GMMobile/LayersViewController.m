//  LayersViewController.m
//  GMMobile

#import "LayersViewController.h"
#import "ConfigurationControl.h"

@interface LayersViewController ()

@end

@implementation LayersViewController
{
    NSArray * _layerList;
}

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
    _layerList = [[ConfigurationControl sharedInstance] getLayers];
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
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
    return [_layerList count];
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
        LayerObject* layer = (LayerObject*)_layerList[indexPath.row];
        cell.textLabel.text = layer.layerName;
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
        cell.textLabel.text = @"No layers in List";
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
    LayerObject *lo = _layerList[indexPath.row];
    int zoom = 0;
    if ([ConfigurationControl.sharedInstance layer:lo.layerID visibleAtZoom:CRAPI.sharedInstance.currentZoom])
        zoom = 22;
    [ConfigurationControl.sharedInstance setLayer:lo.layerID visibileAtZoom:zoom];
}

- (void)helpForTheme:(UIButton *)button
{
    NSString *theme = _layerList[button.tag];
    
    NSLog(@"Help requested for %@", theme);
}

- (void)tableView:(UITableView *)tableView
accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    NSString *theme = _layerList[indexPath.row];
    
    NSLog(@"Detail Disclosure requested for %@", theme);
}

@end