//  LayersViewController.m
//  GMMobile

#import "LayersViewController.h"
#import "ConfigurationControl.h"

#define DEFAULT_ZOOM_LEVEL 12

@interface LayersViewController ()

@property (nonatomic) NSArray *layerList;
@property (nonatomic) CGFloat rowHeight, headerHeight, segControlWidth, stepperHeight;
@property (nonatomic) UIFont *font, *headerFont, *headerZoomFont;
@property (nonatomic) NSInteger indentationLevel;

@end

@implementation LayersViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        _rowHeight = 60.0;
        _font = [UIFont boldSystemFontOfSize:22.0];
        _headerFont = [UIFont boldSystemFontOfSize:28.0];
        _headerZoomFont = [UIFont boldSystemFontOfSize:18.0];
        _indentationLevel = 10;
        _segControlWidth = 120.0;
    }
    
    else
    {
        _rowHeight = 76.0;
        _font = [UIFont boldSystemFontOfSize:36.0];
        _headerFont = [UIFont boldSystemFontOfSize:44.0];
        _headerZoomFont = [UIFont boldSystemFontOfSize:28.0];
        _indentationLevel = 34;
        _segControlWidth = 160.0;
    }
    
    _headerHeight = (_rowHeight * 1.2);
    
    [self setupTableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
    _layerList = ConfigurationControl.sharedInstance.getLayers;
    
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
    _tableView.sectionHeaderHeight = _headerHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView
viewForHeaderInSection:(NSInteger)section
{
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:
                            CGRectMake(0.0, 0.0, tableView.frame.size.width, (_headerHeight * 0.6))];
    
    headerLabel.font = _headerFont;
    headerLabel.textColor = UIColor.whiteColor;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.text = @"Layers";
    
    UILabel *currentZoomLabel = [[UILabel alloc] initWithFrame:
                                 CGRectMake(0.0, (_headerHeight * 0.6),
                                            tableView.frame.size.width, (_headerHeight * 0.3))];
    
    currentZoomLabel.font = _headerZoomFont;
    currentZoomLabel.textColor = UIColor.whiteColor;
    currentZoomLabel.textAlignment = NSTextAlignmentCenter;
    currentZoomLabel.text = [NSString stringWithFormat:@"current zoom = %.1f", CRAPI.sharedInstance.currentZoom];
    
    UIView *headerView = [[UIView alloc] init];
    
    [headerView addSubview:headerLabel];
    [headerView addSubview:currentZoomLabel];
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
        
        BOOL containsSegControl = NO, containsStepper = NO, containsCellLabel = NO;
        
        for (UIView *subviews in cell.contentView.subviews)
        {
            if ([subviews isKindOfClass:UISegmentedControl.class])
                containsSegControl = YES;
            
            if ([subviews isKindOfClass:UIStepper.class])
                containsStepper = YES;
            
            if ([subviews isKindOfClass:TableViewCellLabel.class])
                containsCellLabel = YES;
        }
        
        UISegmentedControl *segControl;
        UIStepper *stepper;
        TableViewCellLabel *cellLabel;
        
        if (!containsSegControl)
        {
            UIFont *scFont = [UIFont boldSystemFontOfSize:18.0];
            
            NSDictionary *attributes = [NSDictionary dictionaryWithObject:scFont
                                                                   forKey:NSFontAttributeName];
            
            segControl = [[UISegmentedControl alloc] initWithItems:@[@"On", @"Off", @"Auto"]];
            
            segControl.frame = CGRectMake(xCount, 12.0, _segControlWidth,
                                          (cell.frame.size.height - 24.0));
            
            segControl.selectedSegmentIndex = GMLayerSettingAuto;
            segControl.layer.borderColor = UIColor.blackColor.CGColor;
            segControl.layer.borderWidth = 3.0;
            segControl.layer.cornerRadius = 4.0;
            
            [segControl setTitleTextAttributes:attributes
                                      forState:UIControlStateNormal];
            
            [[segControl.subviews objectAtIndex:0] setTintColor:UserDefaults.defaults.darkGreen];
            [[segControl.subviews objectAtIndex:2] setTintColor:UIColor.redColor];
            [[segControl.subviews objectAtIndex:1] setTintColor:UserDefaults.defaults.appleBlue];
            
            [segControl addTarget:self
                           action:@selector(segControlSelected:)
                 forControlEvents:UIControlEventValueChanged];
            
            segControl.tag = indexPath.row;

            [cell.contentView addSubview:segControl];
        }
        
        if (!containsStepper)
        {
            xCount += (_segControlWidth + margin);
            
            stepper = [[UIStepper alloc] initWithFrame:
                       CGRectMake((xCount + 23.0), 12.0, 0.0, 0.0)];
            
            _stepperHeight = stepper.frame.size.height;
            
            stepper.value = DEFAULT_ZOOM_LEVEL;
            stepper.enabled = YES;
            stepper.minimumValue = 1;
            stepper.maximumValue = 21;
            stepper.layer.cornerRadius = 4.0;
            stepper.layer.borderWidth = 3.0;
            stepper.layer.borderColor = UIColor.blackColor.CGColor;
            stepper.tintColor = UIColor.blackColor;
            [[stepper.subviews objectAtIndex:0] setTintColor:UIColor.redColor];
            [[stepper.subviews objectAtIndex:1] setTintColor:UserDefaults.defaults.darkGreen];
            
            stepper.tag = indexPath.row;
            
            [stepper addTarget:self
                        action:@selector(stepperSelected:)
              forControlEvents:UIControlEventValueChanged];
            
            [cell.contentView addSubview:stepper];
        }
        
        if (!containsCellLabel)
        {
            cellLabel = [[TableViewCellLabel alloc] initWithFrame:
                         CGRectMake(xCount, 12.0 + _stepperHeight, 140.0, _stepperHeight)];
            
            cellLabel.layer.cornerRadius = 4.0;
            cellLabel.tag = indexPath.row;
            cellLabel.text = [NSString stringWithFormat:@"Show at Zoom %d", DEFAULT_ZOOM_LEVEL];
            cellLabel.font = [UIFont boldSystemFontOfSize:16.0];
            cellLabel.textAlignment = NSTextAlignmentCenter;
            
            [cell.contentView addSubview:cellLabel];
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
    LayerObject *layer = _layerList[indexPath.row];
    int zoom = 0;
    
    if ([ConfigurationControl.sharedInstance layer:layer.layerID
                                     visibleAtZoom:CRAPI.sharedInstance.currentZoom])
    {
        zoom = 22;
    }
    
    [ConfigurationControl.sharedInstance setLayer:layer.layerID
                                   visibileAtZoom:zoom];
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
}

- (void)segControlSelected:(UISegmentedControl *)segControl
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:segControl.tag
                                                inSection:0];
    
    UIView *contentView = [_tableView cellForRowAtIndexPath:indexPath].contentView;
    
    for (UIStepper *stepper in contentView.subviews)
    {
        if ([stepper isKindOfClass:UIStepper.class] &&
            stepper.tag == segControl.tag)
        {
            switch (segControl.selectedSegmentIndex)
            {
                case GMLayerSettingOn:
                    [self layerWasTurnedOnAtIndex:segControl.tag];
                    
                    [self disableStepper:stepper
                                 setting:GMLayerSettingOn];
                    break;
                    
                case GMLayerSettingOff:
                    [self layerWasTurnedOffAtIndex:segControl.tag];
                    
                    [self disableStepper:stepper
                                 setting:GMLayerSettingOff];
                    break;
                    
                case GMLayerSettingAuto:
                    [self enableStepper:stepper];
                    
                    [self layerVisibilityWasSetToZoomLevel:stepper.value
                                                   atIndex:segControl.tag];
                    break;
            }
        }
    }
}

- (void)stepperSelected:(UIStepper *)stepper
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:stepper.tag
                                                inSection:0];
    
    UIView *contentView = [_tableView cellForRowAtIndexPath:indexPath].contentView;
    
    for (TableViewCellLabel *cellLabel in contentView.subviews)
    {
        if ([cellLabel isKindOfClass:TableViewCellLabel.class] &&
            cellLabel.tag == stepper.tag)
        {
            cellLabel.text = [NSString stringWithFormat:@"Show at Zoom %ld",
                              (long)stepper.value];
        }
    }
    
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
        stepper.value = DEFAULT_ZOOM_LEVEL;
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:stepper.tag
                                                    inSection:0];
        
        UIView *contentView = [_tableView cellForRowAtIndexPath:indexPath].contentView;
        
        for (TableViewCellLabel *cellLabel in contentView.subviews)
        {
            if ([cellLabel isKindOfClass:TableViewCellLabel.class] &&
                cellLabel.tag == stepper.tag)
            {
                cellLabel.textColor = UIColor.blackColor;
                
                cellLabel.text = [NSString stringWithFormat:@"Show at Zoom %d",
                                  DEFAULT_ZOOM_LEVEL];
            }
        }
    }
}

- (void)disableStepper:(UIStepper *)stepper
               setting:(GMLayerSetting)setting
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:stepper.tag
                                                inSection:0];
    
    UIView *contentView = [_tableView cellForRowAtIndexPath:indexPath].contentView;
    
    for (TableViewCellLabel *cellLabel in contentView.subviews)
    {
        if ([cellLabel isKindOfClass:TableViewCellLabel.class] &&
            cellLabel.tag == stepper.tag)
        {
            if (setting == GMLayerSettingOn)
                cellLabel.text = @"ON";
            
            else
                cellLabel.text = @"OFF";
        }
    }
    
    if (stepper.enabled)
    {
        stepper.enabled = NO;
        stepper.layer.borderColor = UIColor.grayColor.CGColor;
        stepper.tintColor = UIColor.grayColor;
        [[stepper.subviews objectAtIndex:0] setTintColor:UIColor.grayColor];
        [[stepper.subviews objectAtIndex:1] setTintColor:UIColor.grayColor];
        
        for (TableViewCellLabel *cellLabel in contentView.subviews)
        {
            if ([cellLabel isKindOfClass:TableViewCellLabel.class] &&
                cellLabel.tag == stepper.tag)
            {
                cellLabel.textColor = UIColor.grayColor;
            }
        }
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    [_tableView reloadData];
}

- (void)layerWasTurnedOnAtIndex:(NSInteger)index
{
    LayerObject *layer = (LayerObject *)_layerList[index];
    
    [ConfigurationControl.sharedInstance setLayer:layer.layerID
                                   visibileAtZoom:0];
}

- (void)layerWasTurnedOffAtIndex:(NSInteger)index
{
    LayerObject *layer = (LayerObject *)_layerList[index];
    
    [ConfigurationControl.sharedInstance setLayer:layer.layerID
                                   visibileAtZoom:22];
}

- (void)layerVisibilityWasSetToZoomLevel:(NSInteger)zoomLevel
                                 atIndex:(NSInteger)index
{
    LayerObject *layer = (LayerObject *)_layerList[index];
    
    [ConfigurationControl.sharedInstance setLayer:layer.layerID
                                   visibileAtZoom:zoomLevel];
}

@end