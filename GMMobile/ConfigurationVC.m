//  ConfigurationVC.m
//  NVMobile

#import "ConfigurationVC.h"
#import "NVMetroSettings.h"
#import "CCodeLibrary/UserDefaults.h"

@interface ConfigurationVC () <UITableViewDelegate,UITableViewDataSource>

@property CGFloat rowHeight, margin;
@property (nonatomic) UIFont *font, *headerFont, *zoomLevelsFont;
@property (nonatomic) UITableView *tableView, *zoomLevelsTV;
@property (nonatomic) NSMutableArray *configurations;
@property (nonatomic, copy) NSArray<NSNumber *> *zoomLevels;

@end

@implementation ConfigurationVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    _configurations = NSMutableArray.array;
    [_configurations addObject:@"Basic Parcel Text\nNo Coloring|0"];
    [_configurations addObject:@"Basic Parcel Text\nColoring by Total EMV|1"];
    [_configurations addObject:@"Last Sale Text\nColoring by Last Sale Price|2"];
    [_configurations addObject:@"Build Date Text\nColoring by Build Date|3"];
    [_configurations addObject:@"Owner Name Text\nColoring by Homestead Status|4"];
    [_configurations addObject:@"Land Value Text\nColoring By Land Value per Acre|5"];
    [_configurations addObject:@"Owner/Land EMV/Acres/Land EMV Text\nColoring By Land Value per Acre|6"];
    
    _zoomLevels = @[@21,@20,@19,@18,@17,@16,@15,@14,@13,@12,@11,@10,@9];
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        _rowHeight = 48.0;
        _font = [UIFont boldSystemFontOfSize:16.0];
        _headerFont = [UIFont boldSystemFontOfSize:24.0];
        _zoomLevelsFont = [UIFont systemFontOfSize:14.0];
        _margin = 8.0;
    }
    
    else
    {
        _rowHeight = 64.0;
        _font = [UIFont boldSystemFontOfSize:26.0];
        _headerFont = [UIFont boldSystemFontOfSize:40.0];
        _zoomLevelsFont = [UIFont systemFontOfSize:22.0];
        _margin = 20.0;
    }
    
    [self setupTableViews];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)setupTableViews
{
    _zoomLevelsTV = UITableView.new;
    [self setupTableView:_zoomLevelsTV];
    [_zoomLevelsTV constrainLeadingToAnchor:self.view.leadingAnchor constant:_margin];
    [_zoomLevelsTV constrainTopToAnchor:self.view.topAnchor constant:_margin];
    [_zoomLevelsTV constrainBottomToAnchor:self.view.bottomAnchor constant:-_margin];
    [_zoomLevelsTV constrainWidthToConstant:_rowHeight];
    
    _tableView = UITableView.new;
    [self setupTableView:_tableView];
    [_tableView constrainLeadingToAnchor:_zoomLevelsTV.trailingAnchor];
    [_tableView constrainTopToAnchor:_zoomLevelsTV.topAnchor];
    [_tableView constrainBottomToAnchor:_zoomLevelsTV.bottomAnchor];
    [_tableView constrainTrailingToAnchor:self.view.trailingAnchor constant:-_margin];
}

- (void)setupTableView:(UITableView *)tableView
{
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.separatorInset = UIEdgeInsetsZero;
    tableView.separatorColor = UIColor.blackColor;
    tableView.backgroundColor = UserDefaults.defaults.green;
    tableView.bounces = NO;
    tableView.layer.borderColor = UIColor.blackColor.CGColor;
    tableView.layer.borderWidth = (_rowHeight / 24.0);
    [self.view addSubview:tableView];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    if (tableView == _tableView)
        return _configurations.count;
    
    else
        return _zoomLevels.count;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == _tableView)
        return _rowHeight;
    
    else
        return (tableView.frame.size.height / MAX(_zoomLevels.count, 1));
}

- (CGFloat)tableView:(UITableView *)tableView
heightForHeaderInSection:(NSInteger)section
{
    if (tableView == _tableView)
        return _rowHeight;
    
    else
        return 0.0;
}

- (UIView *)tableView:(UITableView *)tableView
viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:
                          CGRectMake(0.0, 0.0, tableView.frame.size.width, _rowHeight)];
    
    headerView.backgroundColor = UIColor.blackColor;
    
    if (tableView == _tableView)
    {
        UILabel *headerLabel = UILabel.new;
        headerLabel.translatesAutoresizingMaskIntoConstraints = NO;
        headerLabel.font = _headerFont;
        headerLabel.textColor = UIColor.whiteColor;
        headerLabel.textAlignment = NSTextAlignmentCenter;
        headerLabel.text = @"Configurations";
        
        [headerView addSubview:headerLabel];
        [headerLabel constrainToView:headerView leading:0.0 trailing:0.0 top:0.0 bottom:0.0];
        
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
    }
    
    return headerView;
}

- (void)plusTapped:(UIButton *)button
{
    
}

- (void)trashTapped:(UIButton *)button
{
    
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == _tableView)
    {
        int iOpt = textAfter(_configurations[indexPath.row],@"|").intValue;
        NSArray *optionsList = nil;
        NVMetroSettings.sharedInstance.currentAdjustmentValue = CPAdjustRawCounts;
        NVMetroSettings.sharedInstance.skipZero = FALSE;
        
        switch (iOpt)
        {
            default:
            case 0://Basic Parcel Text\nNo Coloring
                NVMetroSettings.sharedInstance.currentFeature = CPFParcels;
                optionsList = [NVMetroSettings.sharedInstance valuesForFeature:CPFParcels];
                [NVMetroSettings.sharedInstance setCurrentValue:0];
                optionsList = [NVMetroSettings.sharedInstance textValuesForFeature:CPFParcels];
                //NVMetroSettings.sharedInstance.currentTextOption = optionsList[2];
                [NVMetroSettings.sharedInstance currentTextSelection:2];
                break;
            case 1://Basic Parcel Text\nColoring by Total EMV
                NVMetroSettings.sharedInstance.currentFeature = CPFParcels;
                optionsList = [NVMetroSettings.sharedInstance valuesForFeature:CPFParcels];
                [NVMetroSettings.sharedInstance setCurrentValue:2];
                optionsList = [NVMetroSettings.sharedInstance textValuesForFeature:CPFParcels];
                //NVMetroSettings.sharedInstance.currentTextOption = optionsList[2];
                [NVMetroSettings.sharedInstance currentTextSelection:2];
                //NVMetroSettings.sharedInstance.currentAdjustmentValue = CPAdjustThousandsOfDollars;
                break;
            case 2://Last Sale Text\nColoring by Last Sale Price
                NVMetroSettings.sharedInstance.currentFeature = CPFParcels;
                optionsList = [NVMetroSettings.sharedInstance valuesForFeature:CPFParcels];
                [NVMetroSettings.sharedInstance setCurrentValue:5];
                optionsList = [NVMetroSettings.sharedInstance textValuesForFeature:CPFParcels];
                //NVMetroSettings.sharedInstance.currentTextOption = optionsList[5];
                [NVMetroSettings.sharedInstance currentTextSelection:5];
                NVMetroSettings.sharedInstance.skipZero = TRUE;
                break;
            case 3://Build Date Text\nColoring by Build Date
                NVMetroSettings.sharedInstance.currentFeature = CPFParcels;
                optionsList = [NVMetroSettings.sharedInstance valuesForFeature:CPFParcels];
                [NVMetroSettings.sharedInstance setCurrentValue:7];
                optionsList = [NVMetroSettings.sharedInstance textValuesForFeature:CPFParcels];
                //NVMetroSettings.sharedInstance.currentTextOption = optionsList[5];
                [NVMetroSettings.sharedInstance currentTextSelection:6];
                NVMetroSettings.sharedInstance.skipZero = TRUE;
                break;
            case 4://Owner Name Text\nColoring by Homestead Status
                NVMetroSettings.sharedInstance.currentFeature = CPFParcels;
                optionsList = [NVMetroSettings.sharedInstance valuesForFeature:CPFParcels];
                [NVMetroSettings.sharedInstance setCurrentValue:6];
                optionsList = [NVMetroSettings.sharedInstance textValuesForFeature:CPFParcels];
                //NVMetroSettings.sharedInstance.currentTextOption = optionsList[5];
                [NVMetroSettings.sharedInstance currentTextSelection:5];
                break;
            case 5://Land Value Text\nColoring By Land Value per Acre
                NVMetroSettings.sharedInstance.currentFeature = CPFParcels;
                optionsList = [NVMetroSettings.sharedInstance valuesForFeature:CPFParcels];
                [NVMetroSettings.sharedInstance setCurrentValue:4];
                optionsList = [NVMetroSettings.sharedInstance textValuesForFeature:CPFParcels];
                //NVMetroSettings.sharedInstance.currentTextOption = optionsList[5];
                [NVMetroSettings.sharedInstance currentTextSelection:3];
                NVMetroSettings.sharedInstance.currentAdjustmentValue = CPAdjustCountPerAcre;
                break;
            case 6://Owner/Land EMV/Acres/Land EMV Text\nColoring By Land Value per Acre
                NVMetroSettings.sharedInstance.currentFeature = CPFParcels;
                optionsList = [NVMetroSettings.sharedInstance valuesForFeature:CPFParcels];
                [NVMetroSettings.sharedInstance setCurrentValue:4];
                optionsList = [NVMetroSettings.sharedInstance textValuesForFeature:CPFParcels];
                //NVMetroSettings.sharedInstance.currentTextOption = optionsList[5];
                [NVMetroSettings.sharedInstance currentTextSelection:4];
                NVMetroSettings.sharedInstance.currentAdjustmentValue = CPAdjustCountPerAcre;
                break;
        }
    }
    
    else
    {
        
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"CustomCell";
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (tableView == _tableView)
    {
        if (!cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:cellIdentifier];
        }
        
        NSString *label = textBefore(_configurations[indexPath.row],@"|");
        cell.textLabel.text = textBefore(label,@"\n");
        cell.detailTextLabel.text = textAfter(label,@"\n");
        cell.textLabel.font = _font;
    }
    
    else
    {
        if (!cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:cellIdentifier];
        }
        
        cell.textLabel.text = _zoomLevels[indexPath.row].stringValue;
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.font = _zoomLevelsFont;
    }
    
    cell.textLabel.textColor = UIColor.blackColor;
    cell.backgroundColor = UIColor.whiteColor;
    
    return cell;
}

@end
