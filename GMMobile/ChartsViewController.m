//  ChartsViewController.m
//  NVMobile

#import "ChartsViewController.h"
#import "CCodeLibrary/UserDefaults.h"
#import "PropertyData.h"
@import Charts;

@interface ChartsViewController ()

@property (nonatomic) CombinedChartView *chart;
@property (nonatomic) UIButton *returnButton;
@property int currentSaleVal;

@end

@implementation ChartsViewController

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.view = view;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UserDefaults.defaults.appleGray;
    _currentSaleVal = 0;
    
    _returnButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _returnButton.translatesAutoresizingMaskIntoConstraints = NO;
    _returnButton.titleLabel.font = [UIFont boldSystemFontOfSize:32.0];
    _returnButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    _returnButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [_returnButton setTitle:@"< Return" forState:UIControlStateNormal];
    [_returnButton setTitleColor:UserDefaults.defaults.appleBlue forState:UIControlStateNormal];
    [_returnButton setTitleColor:UIColor.grayColor forState:UIControlStateHighlighted];
    
    [_returnButton addTarget:self
                      action:@selector(returnButtonTapped:)
            forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_returnButton];
    [_returnButton constrainLeadingToAnchor:self.view.leadingAnchor constant:20.0];
    [_returnButton constrainTopToAnchor:self.view.topAnchor constant:8.0];
    
    _chart = CombinedChartView.new;
    _chart.translatesAutoresizingMaskIntoConstraints = NO;
    _chart.xAxis.labelPosition = XAxisLabelPositionBottom;
    _chart.backgroundColor = UIColor.whiteColor;
    _chart.descriptionText = @"";
    [self.view addSubview:_chart];
    [_chart constrainLeadingToAnchor:self.view.leadingAnchor constant:20.0];
    [_chart constrainTrailingToAnchor:self.view.trailingAnchor constant:-20.0];
    [_chart constrainTopToAnchor:_returnButton.bottomAnchor];
    [_chart constrainBottomToAnchor:self.view.bottomAnchor constant:-20.0];
    
    NSMutableArray *emvTotals = NSMutableArray.array;
    NSMutableArray *emvLands = NSMutableArray.array;
    NSMutableArray *emvBldgs = NSMutableArray.array;
    NSMutableArray *saleVals = NSMutableArray.array;
    
    for (int i = 0; i < _propHistoryArray.count; i++)
    {
        PropertyHistory *ph = (PropertyHistory *)_propHistoryArray[i];
        ChartDataEntry *emvTotalEntry = [[ChartDataEntry alloc] initWithX:ph.year y:ph.emvTotal];
        ChartDataEntry *emvLandEntry = [[ChartDataEntry alloc] initWithX:ph.year y:ph.emvLand];
        ChartDataEntry *emvBldgEntry = [[ChartDataEntry alloc] initWithX:ph.year y:ph.emvBldg];
        [emvTotals addObject:emvTotalEntry];
        [emvLands addObject:emvLandEntry];
        [emvBldgs addObject:emvBldgEntry];
        
        if ((ph.saleVal > 0) && (ph.saleVal != _currentSaleVal))
        {
            _currentSaleVal = ph.saleVal;
            NSString *saleDateString = [NSString stringWithFormat:@"%i", ph.saledate];
            int year = [saleDateString substringToIndex:4].intValue;
            
            if (year > 2003)
            {
                int month = [saleDateString substringWithRange:NSMakeRange(4, 2)].intValue;
                double saledate = year + (month / 12.0);
                
                BarChartDataEntry *saleValEntry = [[BarChartDataEntry alloc] initWithX:saledate y:_currentSaleVal];
                [saleVals addObject:saleValEntry];
            }
        }
    }
    
    NSNumberFormatter *numFormatter = NSNumberFormatter.new;
    numFormatter.numberStyle = kCFNumberFormatterCurrencyStyle;
    numFormatter.maximumFractionDigits = 0;
    ChartDefaultValueFormatter *chartFormatter = ChartDefaultValueFormatter.new;
    chartFormatter.formatter = numFormatter;
    
    LineChartDataSet *emvTotalData = [[LineChartDataSet alloc] initWithValues:emvTotals label:@"Total EMV"];
    emvTotalData.color = UIColor.blueColor;
    emvTotalData.circleColor = UIColor.blackColor;
    emvTotalData.circleHoleColor = UserDefaults.defaults.appleGray;
    emvTotalData.lineWidth = 6.0;
    emvTotalData.drawCubicEnabled = YES;
    emvTotalData.valueFormatter = chartFormatter;
    LineChartDataSet *emvLandData = [[LineChartDataSet alloc] initWithValues:emvLands label:@"Land EMV"];
    emvLandData.color = UIColor.greenColor;
    emvLandData.circleColor = UIColor.blackColor;
    emvLandData.circleHoleColor = UserDefaults.defaults.appleGray;
    emvLandData.lineWidth = 6.0;
    emvLandData.drawCubicEnabled = YES;
    emvLandData.valueFormatter = chartFormatter;
    LineChartDataSet *emvBldgData = [[LineChartDataSet alloc] initWithValues:emvBldgs label:@"Building EMV"];
    emvBldgData.color = UIColor.redColor;
    emvBldgData.circleColor = UIColor.blackColor;
    emvBldgData.circleHoleColor = UserDefaults.defaults.appleGray;
    emvBldgData.lineWidth = 6.0;
    emvBldgData.drawCubicEnabled = YES;
    emvBldgData.valueFormatter = chartFormatter;
    BarChartDataSet *saleValData = [[BarChartDataSet alloc] initWithValues:saleVals label:@"Sale Values"];
    saleValData.color = [UIColor colorWithWhite:0.0 alpha:0.3];
    saleValData.valueFormatter = chartFormatter;
    
    CombinedChartData *data = CombinedChartData.new;
    data.lineData = [[LineChartData alloc] initWithDataSets:@[(emvTotalData), (emvLandData), (emvBldgData)]];
    data.barData = [[BarChartData alloc] initWithDataSet:saleValData];
    _chart.data = data;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)returnButtonTapped:(UIButton *)button
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
