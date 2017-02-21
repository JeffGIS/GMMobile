//  ChartsViewController.m
//  NVMobile

#import "ChartsViewController.h"
#import "CCodeLibrary/UserDefaults.h"
#import "CCodeLibrary/CensusData.h"
#import "CCodeLibrary/NVColor.h"
#import "PropertyData.h"
@import Charts;

@interface ChartsViewController ()

@property (nonatomic) UIButton *returnButton;
@property int currentSaleVal;
@property NSInteger type;

@end

@implementation ChartsViewController

+ (instancetype)chartViewWithType:(ChartsViewType)type
{
    ChartsViewController *chartsVC = ChartsViewController.new;
    chartsVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    chartsVC.type = type;
    return chartsVC;
}

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
    [_returnButton constrainTopToAnchor:self.view.topAnchor];
    
    switch (_type)
    {
        case ChartsViewTypePropReport:
            [self setupPropReport];
            break;
        case ChartsViewTypeCensusDataPie:
            [self setupPieCensusData];
            break;
        case ChartsViewTypeCensusDataBar:
            [self setupBarCensusData];
            break;
        case ChartsViewTypeCensusDataLine:
            break;
        default:
            break;
    }
}

- (void)setupPropReport
{
    CombinedChartView *chart = CombinedChartView.new;
    chart.translatesAutoresizingMaskIntoConstraints = NO;
    chart.xAxis.labelPosition = XAxisLabelPositionBottom;
    chart.backgroundColor = UIColor.whiteColor;
    chart.chartDescription.text = @"";
    chart.legend.font = [UIFont systemFontOfSize:16.0];
    
    [self.view addSubview:chart];
    [chart constrainLeadingToAnchor:self.view.leadingAnchor constant:20.0];
    [chart constrainTrailingToAnchor:self.view.trailingAnchor constant:-20.0];
    [chart constrainTopToAnchor:_returnButton.bottomAnchor];
    [chart constrainBottomToAnchor:self.view.bottomAnchor constant:-20.0];
    
    NSMutableArray *emvTotals = NSMutableArray.array;
    NSMutableArray *emvLands = NSMutableArray.array;
    NSMutableArray *emvBldgs = NSMutableArray.array;
    NSMutableArray *saleVals = NSMutableArray.array;
    NSMutableArray *totalTaxs = NSMutableArray.array;
    
    for (int i = (int)(_propHistoryArray.count - 1); i > -1; i--)
    {
        PropertyHistory *ph = (PropertyHistory *)_propHistoryArray[i];
        double year = (ph.year + 0.5);
        ChartDataEntry *emvTotalEntry = [[ChartDataEntry alloc] initWithX:year y:ph.emvTotal];
        ChartDataEntry *emvLandEntry = [[ChartDataEntry alloc] initWithX:year y:ph.emvLand];
        ChartDataEntry *emvBldgEntry = [[ChartDataEntry alloc] initWithX:year y:ph.emvBldg];
        ChartDataEntry *totalTax = [[ChartDataEntry alloc] initWithX:year y:ph.totalTax];
        
        [emvTotals addObject:emvTotalEntry];
        [emvLands addObject:emvLandEntry];
        [emvBldgs addObject:emvBldgEntry];
        [totalTaxs addObject:totalTax];
        
        if ((ph.saleVal > 0) && (ph.saleVal != _currentSaleVal))
        {
            _currentSaleVal = ph.saleVal;
            NSString *saleDateString = [NSString stringWithFormat:@"%i", ph.saledate];
            int year = [saleDateString substringToIndex:4].intValue;
            int month = [saleDateString substringWithRange:NSMakeRange(4, 2)].intValue;
            double saledate = year + (month / 12.0);
            
            if (saledate >= 2004.5)
            {
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
    emvTotalData.valueFormatter = chartFormatter;
    
    LineChartDataSet *emvLandData = [[LineChartDataSet alloc] initWithValues:emvLands label:@"Land EMV"];
    emvLandData.color = UIColor.greenColor;
    emvLandData.circleColor = UIColor.blackColor;
    emvLandData.circleHoleColor = UserDefaults.defaults.appleGray;
    emvLandData.lineWidth = 6.0;
    emvLandData.valueFormatter = chartFormatter;
    
    LineChartDataSet *emvBldgData = [[LineChartDataSet alloc] initWithValues:emvBldgs label:@"Building EMV"];
    emvBldgData.color = UIColor.redColor;
    emvBldgData.circleColor = UIColor.blackColor;
    emvBldgData.circleHoleColor = UserDefaults.defaults.appleGray;
    emvBldgData.lineWidth = 6.0;
    emvBldgData.valueFormatter = chartFormatter;
    
    BarChartDataSet *saleValData = [[BarChartDataSet alloc] initWithValues:saleVals label:@"Sale Values"];
    saleValData.color = [UIColor colorWithWhite:0.0 alpha:0.3];
    saleValData.valueFormatter = chartFormatter;
    
    LineChartDataSet *totalTaxData = [[LineChartDataSet alloc] initWithValues:totalTaxs label:@"Total Tax"];
    totalTaxData.color = UIColor.orangeColor;
    totalTaxData.circleColor = UIColor.blackColor;
    totalTaxData.circleHoleColor = UserDefaults.defaults.appleGray;
    totalTaxData.lineWidth = 6.0;
    totalTaxData.valueFormatter = chartFormatter;
    
    CombinedChartData *data = CombinedChartData.new;
    data.lineData = [[LineChartData alloc] initWithDataSets:@[(emvTotalData), (emvBldgData), (emvLandData), (totalTaxData)]];
    data.barData = [[BarChartData alloc] initWithDataSet:saleValData];
    chart.data = data;
    chart.xAxis.axisMinimum = (chart.chartXMin - 0.5);
    chart.xAxis.axisMaximum = (chart.chartXMax + 0.5);
}

- (void)setupPieCensusData
{
    PieChartView *chart = PieChartView.new;
    chart.translatesAutoresizingMaskIntoConstraints = NO;
    chart.backgroundColor = UIColor.whiteColor;
    chart.chartDescription.text = [NSString stringWithFormat:@"Age Distribution for Tract %@", _geoid];
    chart.chartDescription.font = [UIFont boldSystemFontOfSize:24.0];
    chart.legend.font = [UIFont systemFontOfSize:16.0];
    
    [self.view addSubview:chart];
    [chart constrainLeadingToAnchor:self.view.leadingAnchor constant:20.0];
    [chart constrainTrailingToAnchor:self.view.trailingAnchor constant:-20.0];
    [chart constrainTopToAnchor:_returnButton.bottomAnchor];
    [chart constrainBottomToAnchor:self.view.bottomAnchor constant:-20.0];
    
    CensusData *cd = CensusData.new;
    NSArray *values = [cd getCensusChartFieldValues:CAVMalesByAge areaType:@"TRACT" geoID:_geoid];
    NSMutableArray *valueArray = NSMutableArray.array;
    NSMutableArray *colorsArray = NSMutableArray.array;
    NSArray *darkColors = NVColor.darkColors;
    NSArray *mediumColors = NVColor.mediumColors;
    
    for (int i = 0; i < values.count; i++)
    {
        NSString *label = textBefore(values[i], @"\x03");
        double value = [textAfter(values[i], @"\x03") doubleValue];
        PieChartDataEntry *pcde = [[PieChartDataEntry alloc] initWithValue:value label:label];
        [valueArray addObject:pcde];
        
        if (i % 2)
            [colorsArray addObject:darkColors[i]];
        
        else
            [colorsArray addObject:mediumColors[i]];
    }
    
    PieChartDataSet *dataSet = [[PieChartDataSet alloc] initWithValues:valueArray.copy label:@""];
    dataSet.colors = colorsArray.copy;
    dataSet.valueFont = [UIFont systemFontOfSize:18.0];
    PieChartData *data = [[PieChartData alloc] initWithDataSet:dataSet];
    chart.data = data;
}

- (void)setupBarCensusData
{
    BarChartView *chart = BarChartView.new;
    chart.translatesAutoresizingMaskIntoConstraints = NO;
    chart.backgroundColor = UIColor.whiteColor;
    chart.chartDescription.text = [NSString stringWithFormat:@"Age Distribution for Tract %@", _geoid];
    chart.chartDescription.font = [UIFont boldSystemFontOfSize:24.0];
    chart.legend.font = [UIFont systemFontOfSize:16.0];
    
    [self.view addSubview:chart];
    [chart constrainLeadingToAnchor:self.view.leadingAnchor constant:20.0];
    [chart constrainTrailingToAnchor:self.view.trailingAnchor constant:-20.0];
    [chart constrainTopToAnchor:_returnButton.bottomAnchor];
    [chart constrainBottomToAnchor:self.view.bottomAnchor constant:-20.0];
    
    CensusData *cd = CensusData.new;
    NSArray *males = [cd getCensusChartFieldValues:CAVMalesByAge areaType:@"TRACT" geoID:_geoid];
    NSArray *females = [cd getCensusChartFieldValues:CAVFemalesByAge areaType:@"TRACT" geoID:_geoid];
    NSMutableArray *totalsArray = NSMutableArray.array;
    NSMutableArray *malesArray = NSMutableArray.array;
    NSMutableArray *femalesArray = NSMutableArray.array;
    
    for (int i = 0; i < males.count; i++)
    {
        NSString *label = textBefore(males[i], @"\x03");
        NSArray *tokens = [label componentsSeparatedByString:@" "];
        double last = [tokens[2] doubleValue];
        double age = 0;
        
        if ([tokens containsObject:@"to"])
        {
            double first = [tokens[0] doubleValue];
            age = ((first + last) / 2.0);
        }
        
        else
            age = (last + 2);
        
        double malesValue = [textAfter(males[i], @"\x03") doubleValue];
        double femalesValue = [textAfter(females[i], @"\x03") doubleValue];
        double totalValue = (malesValue + femalesValue);
        BarChartDataEntry *data = [[BarChartDataEntry alloc] initWithX:age y:totalValue];
        [totalsArray addObject:data];
        data = [[BarChartDataEntry alloc] initWithX:(age - 1) y:malesValue];
        [malesArray addObject:data];
        data = [[BarChartDataEntry alloc] initWithX:(age + 1) y:femalesValue];
        [femalesArray addObject:data];
    }
    
    BarChartDataSet *totalSet = [[BarChartDataSet alloc] initWithValues:totalsArray.copy label:@"Total"];
    totalSet.color = NVColor.darkGreenColor;
    BarChartDataSet *maleSet = [[BarChartDataSet alloc] initWithValues:malesArray.copy label:@"Male"];
    maleSet.color = NVColor.blueColor;
    BarChartDataSet *femaleSet = [[BarChartDataSet alloc] initWithValues:femalesArray.copy label:@"Female"];
    femaleSet.color = NVColor.deepPinkColor;
    BarChartData *data = [[BarChartData alloc] initWithDataSets:@[(totalSet), (maleSet), (femaleSet)]];
    data.barWidth = 1.0;
    data.drawValues = NO;
    chart.data = data;
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
