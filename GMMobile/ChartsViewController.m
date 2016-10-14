//  ChartsViewController.m
//  NVMobile

#import "ChartsViewController.h"
#import "CCodeLibrary/UserDefaults.h"
#import "PropertyData.h"
@import Charts;

@interface ChartsViewController ()

@property (nonatomic) LineChartView *chart;
@property (nonatomic) UIButton *returnButton;

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
    
    _chart = LineChartView.new;
    _chart.translatesAutoresizingMaskIntoConstraints = NO;
    _chart.xAxis.labelPosition = XAxisLabelPositionBottom;
    _chart.backgroundColor = UIColor.whiteColor;
    _chart.descriptionText = @"";
    [self.view addSubview:_chart];
    [_chart constrainLeadingToAnchor:self.view.leadingAnchor constant:20.0];
    [_chart constrainTrailingToAnchor:self.view.trailingAnchor constant:-20.0];
    [_chart constrainTopToAnchor:_returnButton.bottomAnchor];
    [_chart constrainBottomToAnchor:self.view.bottomAnchor constant:-20.0];
    
    NSMutableArray *emvTotal = NSMutableArray.array;
    NSMutableArray *emvLand = NSMutableArray.array;
    NSMutableArray *emvBldg = NSMutableArray.array;
    NSMutableArray *saleVal = NSMutableArray.array;
    
    for (int i = 0; i < _propHistoryArray.count; i++)
    {
        PropertyHistory *ph = (PropertyHistory *)_propHistoryArray[i];
        ChartDataEntry *emvTotalEntry = [[ChartDataEntry alloc] initWithX:ph.year y:MAX(ph.emvTotal, 0.0)];
        ChartDataEntry *emvLandEntry = [[ChartDataEntry alloc] initWithX:ph.year y:MAX(ph.emvLand, 0.0)];
        ChartDataEntry *emvBldgEntry = [[ChartDataEntry alloc] initWithX:ph.year y:MAX(ph.emvBldg, 0.0)];
        ChartDataEntry *saleValEntry = [[ChartDataEntry alloc] initWithX:ph.year y:MAX(ph.saleVal, 0.0)];
        [emvTotal addObject:emvTotalEntry];
        [emvLand addObject:emvLandEntry];
        [emvBldg addObject:emvBldgEntry];
        [saleVal addObject:saleValEntry];
    }
    
    NSNumberFormatter *numFormatter = NSNumberFormatter.new;
    numFormatter.numberStyle = kCFNumberFormatterCurrencyStyle;
    numFormatter.maximumFractionDigits = 0;
    ChartDefaultValueFormatter *chartFormatter = ChartDefaultValueFormatter.new;
    chartFormatter.formatter = numFormatter;
    
    LineChartDataSet *emvTotalData = [[LineChartDataSet alloc] initWithValues:emvTotal label:@"Total EMV"];
    emvTotalData.color = UIColor.blueColor;
    emvTotalData.circleColor = UIColor.blackColor;
    emvTotalData.lineWidth = 6.0;
    emvTotalData.valueFormatter = chartFormatter;
    LineChartDataSet *emvLandData = [[LineChartDataSet alloc] initWithValues:emvLand label:@"Land EMV"];
    emvLandData.color = UIColor.greenColor;
    emvLandData.circleColor = UIColor.blackColor;
    emvLandData.lineWidth = 6.0;
    emvLandData.valueFormatter = chartFormatter;
    LineChartDataSet *emvBldgData = [[LineChartDataSet alloc] initWithValues:emvBldg label:@"Building EMV"];
    emvBldgData.color = UIColor.redColor;
    emvBldgData.circleColor = UIColor.blackColor;
    emvBldgData.lineWidth = 6.0;
    emvBldgData.valueFormatter = chartFormatter;
    LineChartDataSet *saleValData = [[LineChartDataSet alloc] initWithValues:saleVal label:@"Sale Value"];
    saleValData.color = UIColor.orangeColor;
    saleValData.circleColor = UIColor.blackColor;
    saleValData.lineWidth = 6.0;
    saleValData.valueFormatter = chartFormatter;
    
    LineChartData *data = [[LineChartData alloc] initWithDataSets:@[(emvTotalData), (emvLandData), (emvBldgData), (saleValData)]];
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
