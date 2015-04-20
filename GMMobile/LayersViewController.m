//  LayersViewController.m
//  GMMobile

#import "LayersViewController.h"
#import "ConfigurationControl.h"

@interface LayersViewController ()

@property (nonatomic) NSArray *layerList;
@property (nonatomic) CGFloat rowHeight;
@property (nonatomic) UIFont *font;
@property (nonatomic) NSInteger indentationLevel;

@end

@implementation LayersViewController
{
    NSInteger _autoZoomLevel[MAX_LAYER_NAME];
    UIStepper *_stepper[MAX_LAYER_NAME];
    UISegmentedControl *_segControl[MAX_LAYER_NAME];
    UILabel *_label[MAX_LAYER_NAME];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _layerList = ConfigurationControl.sharedInstance.getLayers;
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    
    UIFont *scFont = [UIFont boldSystemFontOfSize:18.0];
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:scFont
                                                           forKey:NSFontAttributeName];
    
    for (int i = 0; i < _layerList.count; i++)
    {
        _autoZoomLevel[i] = DEFAULT_ZOOM_LEVEL;
        
        _stepper[i] = [[UIStepper alloc] init];
        _stepper[i].value = _autoZoomLevel[i];
        _stepper[i].enabled = YES;
        _stepper[i].minimumValue = 1;
        _stepper[i].maximumValue = 21;
        _stepper[i].layer.cornerRadius = 4.0;
        _stepper[i].layer.borderWidth = 3.0;
        _stepper[i].layer.borderColor = UIColor.blackColor.CGColor;
        _stepper[i].tintColor = UIColor.blackColor;
        [[_stepper[i].subviews objectAtIndex:0] setTintColor:UIColor.redColor];
        [[_stepper[i].subviews objectAtIndex:1] setTintColor:UserDefaults.defaults.darkGreen];
        
        [_stepper[i] addTarget:self
                        action:@selector(stepperSelected:)
              forControlEvents:UIControlEventValueChanged];
        
        _label[i].text = [NSString stringWithFormat:@"Show at Zoom %d", DEFAULT_ZOOM_LEVEL];
        
        _segControl[i] = [[UISegmentedControl alloc] initWithItems:@[@"On", @"Off", @"Auto"]];
        _segControl[i].selectedSegmentIndex = GMLayerSettingAuto;
        _segControl[i].layer.borderColor = UIColor.blackColor.CGColor;
        _segControl[i].layer.borderWidth = 3.0;
        _segControl[i].layer.cornerRadius = 4.0;
        
        [_segControl[i] setTitleTextAttributes:attributes
                                      forState:UIControlStateNormal];
        
        [[_segControl[i].subviews objectAtIndex:0] setTintColor:UserDefaults.defaults.darkGreen];
        [[_segControl[i].subviews objectAtIndex:2] setTintColor:UIColor.redColor];
        [[_segControl[i].subviews objectAtIndex:1] setTintColor:UserDefaults.defaults.appleBlue];
        
        [_segControl[i] addTarget:self
                           action:@selector(segControlSelected:)
                 forControlEvents:UIControlEventValueChanged];
        
        _label[i] = [[UILabel alloc] init];
        
        _label[i].layer.cornerRadius = 4.0;
        _label[i].text = [NSString stringWithFormat:@"Show at Zoom %ld", (long)_autoZoomLevel[i]];
        _label[i].font = [UIFont boldSystemFontOfSize:16.0];
        _label[i].textAlignment = NSTextAlignmentCenter;
    }
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        _rowHeight = 60.0;
        _font = [UIFont boldSystemFontOfSize:22.0];
        _indentationLevel = 10;
    }
    
    else
    {
        _rowHeight = 76.0;
        _font = [UIFont boldSystemFontOfSize:36.0];
        _indentationLevel = 34;
    }
    
    [self setupTableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
    [_tableView reloadData];
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
    _tableView.sectionHeaderHeight = _rowHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView
viewForHeaderInSection:(NSInteger)section
{
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:
                            CGRectMake(0.0, 0.0, tableView.frame.size.width, _rowHeight)];
    
    headerLabel.font = _font;
    headerLabel.textColor = UIColor.whiteColor;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.text = @"Layers Manager";
    
    UIView *headerView = [[UIView alloc] initWithFrame:
                          CGRectMake(0.0, 0.0, tableView.frame.size.width, _rowHeight)];
    
    [headerView addSubview:headerLabel];
    headerView.backgroundColor = UIColor.blackColor;
    return headerView;
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
        cell.textLabel.numberOfLines = 2;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell.textLabel.textColor = UIColor.blackColor;
        cell.userInteractionEnabled = YES;
        cell.indentationLevel = _indentationLevel;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        CGFloat margin = 10.0;
        CGFloat xCount = margin;
        
        if (![cell.contentView.subviews containsObject:_segControl[indexPath.row]])
        {
            _segControl[indexPath.row].frame = CGRectMake(xCount, 12.0, 160.0, (cell.contentView.frame.size.height - 24.0));
            _segControl[indexPath.row].tag = indexPath.row;
            
            [cell.contentView addSubview:_segControl[indexPath.row]];
        }
        
        if (![cell.contentView.subviews containsObject:_stepper[indexPath.row]])
        {
            xCount += (_segControl[indexPath.row].frame.size.width + margin);
            
            _stepper[indexPath.row].frame = CGRectMake((xCount + 23.0), 12.0, 0.0, 0.0);
            _stepper[indexPath.row].tag = indexPath.row;
            
            [cell.contentView addSubview:_stepper[indexPath.row]];
        }
        
        if (![cell.contentView.subviews containsObject:_label[indexPath.row]])
        {
            _label[indexPath.row].frame = CGRectMake(xCount, 12.0 + _stepper[indexPath.row].frame.size.height,
                                                     140.0, _stepper[indexPath.row].frame.size.height);
            
            [cell.contentView addSubview:_label[indexPath.row]];
        }
    }
    
    else
    {
        cell.textLabel.text = @"No layers in List";
        cell.textLabel.textColor = UIColor.grayColor;
        cell.userInteractionEnabled = NO;
    }
    
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.font = _font;
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
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
}

- (void)segControlSelected:(UISegmentedControl *)segControl
{
    switch (segControl.selectedSegmentIndex)
    {
        case GMLayerSettingOn:
            [self layerWasTurnedOnAtIndex:segControl.tag];
            
            [self disableStepper:_stepper[segControl.tag]
                         setting:GMLayerSettingOn];
            break;
            
        case GMLayerSettingOff:
            [self layerWasTurnedOffAtIndex:segControl.tag];
            
            [self disableStepper:_stepper[segControl.tag]
                         setting:GMLayerSettingOff];
            break;
            
        case GMLayerSettingAuto:
            [self enableStepper:_stepper[segControl.tag]];
            
            [self layerVisibilityWasSetToZoomLevel:_stepper[segControl.tag].value
                                           atIndex:segControl.tag];
            break;
    }
}

- (void)stepperSelected:(UIStepper *)stepper
{
    _autoZoomLevel[stepper.tag] = (NSInteger)stepper.value;
    
    _label[stepper.tag].text = [NSString stringWithFormat:@"Show at Zoom %ld",
                                (long)_autoZoomLevel[stepper.tag]];
    
    [self layerVisibilityWasSetToZoomLevel:stepper.value
                                   atIndex:stepper.tag];
}

- (void)enableStepper:(UIStepper *)stepper
{
    if (!stepper.enabled)
    {
        stepper.enabled = YES;
        stepper.layer.borderColor = UIColor.blackColor.CGColor;
        stepper.tintColor = UIColor.blackColor;
        [[stepper.subviews objectAtIndex:0] setTintColor:UIColor.redColor];
        [[stepper.subviews objectAtIndex:1] setTintColor:UserDefaults.defaults.darkGreen];
        
        _label[stepper.tag].textColor = UIColor.blackColor;
        _autoZoomLevel[stepper.tag] = DEFAULT_ZOOM_LEVEL;
        
        _label[stepper.tag].text = [NSString stringWithFormat:@"Show at Zoom %ld",
                                    (long)_autoZoomLevel[stepper.tag]];
        
        stepper.value = (double)_autoZoomLevel[stepper.tag];
    }
}

- (void)disableStepper:(UIStepper *)stepper
               setting:(GMLayerSetting)setting
{
    if (setting == GMLayerSettingOn)
        _label[stepper.tag].text = @"ON";
    
    else
        _label[stepper.tag].text = @"OFF";
    
    if (stepper.enabled)
    {
        stepper.enabled = NO;
        stepper.layer.borderColor = UIColor.grayColor.CGColor;
        stepper.tintColor = UIColor.grayColor;
        [[stepper.subviews objectAtIndex:0] setTintColor:UIColor.grayColor];
        [[stepper.subviews objectAtIndex:1] setTintColor:UIColor.grayColor];
        
        _label[stepper.tag].textColor = UIColor.grayColor;
        _autoZoomLevel[stepper.tag] = 0;
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    [_tableView reloadData];
}

- (void)layerWasTurnedOnAtIndex:(NSInteger)index
{
    NSLog(@"Layer Turned ON at Index %ld",
          (long)index);
}

- (void)layerWasTurnedOffAtIndex:(NSInteger)index
{
    NSLog(@"Layer Turned OFF at Index %ld",
          (long)index);
}

- (void)layerVisibilityWasSetToZoomLevel:(NSInteger)zoomLevel
                                 atIndex:(NSInteger)index
{
    NSLog(@"Layer Visibility Set to %ld at Index %ld",
          (long)zoomLevel, (long)index);
}

@end