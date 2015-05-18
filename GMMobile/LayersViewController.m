//  LayersViewController.m
//  GMMobile

#import "LayersViewController.h"
#import "ConfigurationControl.h"

#define DEFAULT_ZOOM_LEVEL 12

@interface LayersViewController ()

@property (nonatomic) NSArray *layerList;
@property (nonatomic) CGFloat rowHeight, headerHeight, segControlWidth, stepperHeight, cellLabelWidth;
@property (nonatomic) UIFont *font, *headerFont, *headerZoomFont;
@property (nonatomic) NSInteger indentationLevel;
@property (nonatomic, copy) NSString *headerTitle;
@property BOOL isDrilledDown, isFirstTime;
@property (nonatomic) HardCodedConfigs lastSelectedApp;

@end

@implementation LayersViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _headerTitle = @"Layers";
    _isFirstTime = YES;
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    _isDrilledDown = NO;
    _lastSelectedApp = ConfigurationControl.sharedInstance.currentApp;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        _rowHeight = 60.0;
        _font = [UIFont boldSystemFontOfSize:22.0];
        _headerFont = [UIFont boldSystemFontOfSize:28.0];
        _headerZoomFont = [UIFont boldSystemFontOfSize:18.0];
        _indentationLevel = 10;
        _segControlWidth = 120.0;
        _cellLabelWidth = 100.0;
    }
    
    else
    {
        _rowHeight = 76.0;
        _font = [UIFont boldSystemFontOfSize:36.0];
        _headerFont = [UIFont boldSystemFontOfSize:44.0];
        _headerZoomFont = [UIFont boldSystemFontOfSize:28.0];
        _indentationLevel = 38;
        _segControlWidth = 160.0;
        _cellLabelWidth = 140.0;
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
    if (!_isDrilledDown)
        _layerList = ConfigurationControl.sharedInstance.getLayers;
    
    if (_isFirstTime || _lastSelectedApp != ConfigurationControl.sharedInstance.currentApp)
    {
        [self initializeTableViewComponentValues];
        _lastSelectedApp = ConfigurationControl.sharedInstance.currentApp;
        _isFirstTime = NO;
        [_tableView reloadData];
    }
}

- (void)initializeTableViewComponentValues
{
    for (int i = 0; i < _layerList.count; i++)
    {
        LayerObject *layer = (LayerObject *)_layerList[i];
        layer.segControlIndex = GMLayerSettingAuto;
        layer.stepperEnabled = YES;
        layer.cellButtonColor = UserDefaults.defaults.darkGreen;
        layer.zoomLevel = DEFAULT_ZOOM_LEVEL;
    }
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
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = UIColor.blackColor;
    
    UIButton *headerBackButton;
    
    if (_isDrilledDown)
    {
        CGFloat buttonSize = (_headerHeight - 36.0);
        
        headerBackButton = [[UIButton alloc] initWithFrame:
                            CGRectMake(12.0, 18.0, buttonSize, buttonSize)];
        
        headerBackButton.backgroundColor = UIColor.whiteColor;
        
        [headerBackButton setImage:[UIImage imageWithContentsOfFile:
                                    [NSBundle.mainBundle pathForResource:@"backArrow"
                                                                  ofType:@"png"]]
                          forState:UIControlStateNormal];
        
        [headerBackButton setImage:[UIImage imageWithContentsOfFile:
                                    [NSBundle.mainBundle pathForResource:@"backArrowHighlighted"
                                                                  ofType:@"png"]]
                          forState:UIControlStateHighlighted];
        
        headerBackButton.layer.cornerRadius = 10.0;
        
        [headerBackButton addTarget:self
                             action:@selector(tableViewReturn:)
                   forControlEvents:UIControlEventTouchUpInside];
        
        [headerView addSubview:headerBackButton];
    }
    
    CGFloat headerLabelOriginX = (headerBackButton.frame.origin.x +
                                  headerBackButton.frame.size.width);
    
    TableViewCellLabel *headerLabel = [[TableViewCellLabel alloc] initWithFrame:
                                       CGRectMake(headerLabelOriginX, 0.0,
                                                  (tableView.frame.size.width - (headerLabelOriginX * 2.0)),
                                                  (_headerHeight * 0.6))];
    
    headerLabel.font = _headerFont;
    headerLabel.textColor = UIColor.whiteColor;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.text = _headerTitle;
    
    [headerView addSubview:headerLabel];
    
    TableViewCellLabel *currentZoomLabel = [[TableViewCellLabel alloc] initWithFrame:
                                            CGRectMake(headerLabelOriginX, (_headerHeight * 0.6),
                                                       (tableView.frame.size.width - (headerLabelOriginX * 2.0)),
                                                       (_headerHeight * 0.3))];
    
    currentZoomLabel.font = _headerZoomFont;
    currentZoomLabel.textColor = UIColor.whiteColor;
    currentZoomLabel.textAlignment = NSTextAlignmentCenter;
    
    currentZoomLabel.text = [NSString stringWithFormat:@"current zoom = %.1f",
                             CRAPI.sharedInstance.currentZoom];
    
    [headerView addSubview:currentZoomLabel];
    
    return headerView;
}

- (void)tableViewReturn:(UIButton *)button
{
    _layerList = ConfigurationControl.sharedInstance.getLayers;
    [self initializeTableViewComponentValues];
    _isDrilledDown = NO;
    _headerTitle = @"Layers";
    [_tableView reloadData];
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:@"Cell"];
    }
    
    NSInteger row = indexPath.row;
    
    if (_layerList.count != 0)
    {
        LayerObject *layer = (LayerObject *)_layerList[row];
        cell.textLabel.text = layer.layerName;
        cell.textLabel.numberOfLines = 2;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell.textLabel.textColor = UIColor.blackColor;
        cell.indentationLevel = _indentationLevel;
        
        if (layer.hasSymbols)
        {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
        
        else
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        if (_isDrilledDown)
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        CGFloat margin = 10.0, topMargin = 12.0;
        CGFloat cornerRadius = 4.0, borderWidth = 3.0;
        CGFloat xCount = margin;
        
        BOOL containsSegControl = NO, containsStepper = NO;
        BOOL containsCellLabel = NO, containsCellButton = NO;
        
        for (UIView *subviews in cell.contentView.subviews)
        {
            if ([subviews isKindOfClass:UISegmentedControl.class])
                containsSegControl = YES;
            
            if ([subviews isKindOfClass:UIStepper.class])
                containsStepper = YES;
            
            if ([subviews isKindOfClass:TableViewCellLabel.class])
                containsCellLabel = YES;
            
            if ([subviews isKindOfClass:TableViewCellButton.class])
                containsCellButton = YES;
            
            subviews.tag = indexPath.row;
        }
        
        UISegmentedControl *segControl;
        UIStepper *stepper;
        TableViewCellLabel *cellLabel;
        TableViewCellButton *cellButton;
        
        if (!containsSegControl)
        {
            UIFont *scFont = [UIFont boldSystemFontOfSize:18.0];
            
            NSDictionary *attributes = [NSDictionary dictionaryWithObject:scFont
                                                                   forKey:NSFontAttributeName];
            
            segControl = [[UISegmentedControl alloc] initWithItems:@[@"On", @"Off", @"Auto"]];
            
            segControl.frame = CGRectMake(xCount, topMargin, _segControlWidth,
                                          (cell.frame.size.height - (topMargin * 2.0)));
            
            segControl.layer.borderColor = UIColor.blackColor.CGColor;
            segControl.layer.borderWidth = borderWidth;
            segControl.layer.cornerRadius = cornerRadius;
            segControl.tintColor = UIColor.blackColor;
            segControl.selectedSegmentIndex = layer.segControlIndex;
            segControl.tag = row;
            
            [segControl setTitleTextAttributes:attributes
                                      forState:UIControlStateNormal];
            
            [segControl addTarget:self
                           action:@selector(segControlSelected:)
                 forControlEvents:UIControlEventValueChanged];
            
            [cell.contentView addSubview:segControl];
        }
        
        else for (UISegmentedControl *segControls in cell.contentView.subviews)
        {
            if ([segControls isKindOfClass:UISegmentedControl.class])
                segControls.selectedSegmentIndex = layer.segControlIndex;
        }
        
        xCount += (_segControlWidth + margin);
        
        if (!containsStepper)
        {
            stepper = [[UIStepper alloc] initWithFrame:
                       CGRectMake((xCount + 23.0), topMargin, 0.0, 0.0)];
            
            _stepperHeight = stepper.frame.size.height;
            
            stepper.minimumValue = 1;
            stepper.maximumValue = 21;
            stepper.layer.cornerRadius = cornerRadius;
            stepper.layer.borderWidth = borderWidth;
            stepper.tag = row;
            
            stepper.value = layer.zoomLevel;
            stepper.enabled = layer.stepperEnabled;
            
            if (layer.segControlIndex != GMLayerSettingAuto)
            {
                stepper.enabled = NO;
                stepper.layer.borderColor = UIColor.grayColor.CGColor;
                stepper.tintColor = UIColor.grayColor;
            }
            
            else
            {
                stepper.enabled = YES;
                stepper.layer.borderColor = UIColor.blackColor.CGColor;
                stepper.tintColor = UIColor.blackColor;
            }
            
            [stepper addTarget:self
                        action:@selector(stepperSelected:)
              forControlEvents:UIControlEventValueChanged];
            
            [cell.contentView addSubview:stepper];
        }
        
        else for (UIStepper *steppers in cell.contentView.subviews)
        {
            if ([steppers isKindOfClass:UIStepper.class])
            {
                steppers.value = layer.zoomLevel;
                steppers.enabled = layer.stepperEnabled;
                
                if (layer.segControlIndex != GMLayerSettingAuto)
                {
                    steppers.enabled = NO;
                    steppers.layer.borderColor = UIColor.grayColor.CGColor;
                    steppers.tintColor = UIColor.grayColor;
                }
                
                else
                {
                    steppers.enabled = YES;
                    steppers.layer.borderColor = UIColor.blackColor.CGColor;
                    steppers.tintColor = UIColor.blackColor;
                }
            }
        }
        
        if (!containsCellLabel)
        {
            cellLabel = [[TableViewCellLabel alloc] initWithFrame:
                         CGRectMake(xCount, (topMargin + _stepperHeight), _cellLabelWidth, _stepperHeight)];
            
            cellLabel.layer.cornerRadius = cornerRadius;
            cellLabel.font = [UIFont boldSystemFontOfSize:16.0];
            cellLabel.textAlignment = NSTextAlignmentCenter;
            cellLabel.tag = row;
            
            cellLabel.text = [NSString stringWithFormat:@"Show at Zoom %ld", (long)layer.zoomLevel];
            
            if (layer.segControlIndex != GMLayerSettingAuto)
            {
                cellLabel.textColor = UIColor.grayColor;
                
                if (layer.segControlIndex == GMLayerSettingOn)
                    cellLabel.text = @"ON";
                
                else
                    cellLabel.text = @"OFF";
            }
            
            else
                cellLabel.textColor = UIColor.blackColor;
            
            [cell.contentView addSubview:cellLabel];
        }
        
        else for (TableViewCellLabel *cellLabels in cell.contentView.subviews)
        {
            if ([cellLabels isKindOfClass:TableViewCellLabel.class])
            {
                cellLabels.text = [NSString stringWithFormat:@"Show at Zoom %ld", (long)layer.zoomLevel];
                
                if (layer.segControlIndex != GMLayerSettingAuto)
                {
                    cellLabels.textColor = UIColor.grayColor;
                    
                    if (layer.segControlIndex == GMLayerSettingOn)
                        cellLabels.text = @"ON";
                    
                    else
                        cellLabels.text = @"OFF";
                }
                
                else
                    cellLabels.textColor = UIColor.blackColor;
            }
        }
        
        xCount += (_cellLabelWidth + margin);
            
        if (!containsCellButton)
        {
            cellButton = [[TableViewCellButton alloc] initWithFrame:
                          CGRectMake(xCount, topMargin, 40.0,
                                     (cell.frame.size.height - (topMargin * 2.0)))];
            
            [cellButton setImage:[UserDefaults.defaults imageWithColor:UserDefaults.defaults.appleGray
                                                              andFrame:cellButton.frame]
                        forState:UIControlStateHighlighted];
            
            cellButton.layer.cornerRadius = cornerRadius;
            cellButton.layer.masksToBounds = YES;
            cellButton.tag = row;
            cellButton.layer.borderWidth = borderWidth;
            cellButton.layer.borderColor = UIColor.blackColor.CGColor;
            cellButton.backgroundColor = layer.cellButtonColor;
            cellButton.opaque = YES;
            
            [cellButton addTarget:self
                           action:@selector(cellButtonSelected:)
                 forControlEvents:UIControlEventTouchUpInside];
            
            [cell.contentView addSubview:cellButton];
        }
        
        else for (TableViewCellButton *cellButtons in cell.contentView.subviews)
        {
            if ([cellButtons isKindOfClass:TableViewCellButton.class])
                cellButtons.backgroundColor = layer.cellButtonColor;
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
    
    if (layer.hasSymbols)
    {
        _isDrilledDown = YES;
        _headerTitle = layer.layerName;
        _layerList = [ConfigurationControl.sharedInstance getSymbolsForLayer:layer.layerID];
        [self initializeTableViewComponentValues];
        [_tableView reloadData];
    }
    
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

- (void)cellButtonSelected:(TableViewCellButton *)cellButton
{
    [self performSegueWithIdentifier:@"ShowLayerOverrides"
                              sender:self];
}

- (void)enableStepper:(UIStepper *)stepper
{
    if (!stepper.enabled)
    {
        stepper.enabled = YES;
        stepper.layer.borderColor = UIColor.blackColor.CGColor;
        stepper.tintColor = UIColor.blackColor;
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
    layer.stepperEnabled = NO;
    layer.segControlIndex = GMLayerSettingOn;
    
    [ConfigurationControl.sharedInstance setLayer:layer.layerID
                                   visibileAtZoom:0];
}

- (void)layerWasTurnedOffAtIndex:(NSInteger)index
{
    LayerObject *layer = (LayerObject *)_layerList[index];
    layer.stepperEnabled = NO;
    layer.segControlIndex = GMLayerSettingOff;
    
    [ConfigurationControl.sharedInstance setLayer:layer.layerID
                                   visibileAtZoom:22];
}

- (void)layerVisibilityWasSetToZoomLevel:(NSInteger)zoomLevel
                                 atIndex:(NSInteger)index
{
    LayerObject *layer = (LayerObject *)_layerList[index];
    layer.zoomLevel = zoomLevel;
    layer.stepperEnabled = YES;
    layer.segControlIndex = GMLayerSettingAuto;
    
    [ConfigurationControl.sharedInstance setLayer:layer.layerID
                                   visibileAtZoom:zoomLevel];
}

@end