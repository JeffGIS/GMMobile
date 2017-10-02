//  ConfigurationVC.m
//  NVMobile

#import "ConfigurationVC.h"
#import "NVMetroSettings.h"
#import "CCodeLibrary/UserDefaults.h"

@interface ConfigurationVC () <UITableViewDelegate,UITableViewDataSource>

@property CGFloat rowHeight, margin;
@property (nonatomic) UIFont *font, *headerFont;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSMutableArray *configurations;

@end

@implementation ConfigurationVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    _configurations = NSMutableArray.array;
    [_configurations addObject:@"Basic Parcel Text|0"];
    [_configurations addObject:@"Parcel Text With Coloring by Total EMV|1"];
    [_configurations addObject:@"Last Sale Text With Coloring by Last Sale Price|2"];
    [_configurations addObject:@"Build Date Text With Coloring by Build Date|3"];
    [_configurations addObject:@"Owner Name Text With Coloring by Homestead Status|4"];
    [_configurations addObject:@"Land Value per Acre Text With Coloring By Land Value per Acre|5"];
    [_configurations addObject:@"Owner/Land EMV/Acres/Land EMV per Acre Text With Coloring By Land Value per Acre|6"];
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        _rowHeight = 48.0;
        _font = [UIFont boldSystemFontOfSize:16.0];
        _headerFont = [UIFont boldSystemFontOfSize:24.0];
        _margin = 8.0;
    }
    
    else
    {
        _rowHeight = 64.0;
        _font = [UIFont boldSystemFontOfSize:26.0];
        _headerFont = [UIFont boldSystemFontOfSize:40.0];
        _margin = 20.0;
    }
    
    [self setupTableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)setupTableView
{
    _tableView = UITableView.new;
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
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
    [self.view addSubview:_tableView];
    [_tableView constrainToView:self.view leading:_margin trailing:-_margin top:_margin bottom:-_margin];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return _configurations.count;
}

- (UIView *)tableView:(UITableView *)tableView
viewForHeaderInSection:(NSInteger)section
{
    UILabel *headerLabel = UILabel.new;
    headerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    headerLabel.font = _headerFont;
    headerLabel.textColor = UIColor.whiteColor;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.text = @"Configurations";
    
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
    UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
    int iOpt = (int)cell.tag;
    NSArray * optionsList = nil;
    switch (iOpt)
    {
        default:
        case 0:
            NVMetroSettings.sharedInstance.currentFeature = CPFParcels;
            optionsList = [NVMetroSettings.sharedInstance valuesForFeature:CPFParcels];
            [NVMetroSettings.sharedInstance setCurrentValue:0];
            NVMetroSettings.sharedInstance.currentAdjustmentValue = CPAdjustRawCounts;
            optionsList = [NVMetroSettings.sharedInstance textValuesForFeature:CPFParcels];
            //NVMetroSettings.sharedInstance.currentTextOption = optionsList[2];
            [NVMetroSettings.sharedInstance currentTextSelection:2];

            break;
        case 1:
            NVMetroSettings.sharedInstance.currentFeature = CPFParcels;
            optionsList = [NVMetroSettings.sharedInstance valuesForFeature:CPFParcels];
            [NVMetroSettings.sharedInstance setCurrentValue:2];
            NVMetroSettings.sharedInstance.currentAdjustmentValue = CPAdjustRawCounts;
            optionsList = [NVMetroSettings.sharedInstance textValuesForFeature:CPFParcels];
            //NVMetroSettings.sharedInstance.currentTextOption = optionsList[2];
            [NVMetroSettings.sharedInstance currentTextSelection:2];

            break;
        case 2:
            NVMetroSettings.sharedInstance.currentFeature = CPFParcels;
            optionsList = [NVMetroSettings.sharedInstance valuesForFeature:CPFParcels];
            [NVMetroSettings.sharedInstance setCurrentValue:5];
            NVMetroSettings.sharedInstance.currentAdjustmentValue = CPAdjustRawCounts;
            optionsList = [NVMetroSettings.sharedInstance textValuesForFeature:CPFParcels];
            //NVMetroSettings.sharedInstance.currentTextOption = optionsList[5];
            [NVMetroSettings.sharedInstance currentTextSelection:5];

            break;
        case 6://Owner/Land EMV/Acres/Land EMV per Acre
            NVMetroSettings.sharedInstance.currentFeature = CPFParcels;
            optionsList = [NVMetroSettings.sharedInstance valuesForFeature:CPFParcels];
            [NVMetroSettings.sharedInstance setCurrentValue:2];
            NVMetroSettings.sharedInstance.currentAdjustmentValue = CPAdjustRawCounts;
            optionsList = [NVMetroSettings.sharedInstance textValuesForFeature:CPFParcels];
            //NVMetroSettings.sharedInstance.currentTextOption = optionsList[5];
            [NVMetroSettings.sharedInstance currentTextSelection:5];
            
            break;
    }
}
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"CustomCell";
    
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellIdentifier];
    }
    
    cell.textLabel.text = textBefore (_configurations[indexPath.row],@"|");
    cell.tag = textAfter(_configurations[indexPath.row],@"|").integerValue;
    cell.textLabel.textColor = UIColor.blackColor;
    cell.textLabel.font = _font;
    cell.backgroundColor = UIColor.whiteColor;
    
    return cell;
}

@end
