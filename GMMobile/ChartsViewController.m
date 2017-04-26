//  ChartsViewController.m
//  NVMobile

#import "ChartsViewController.h"
#import "CCodeLibrary/UserDefaults.h"
#import "CCodeLibrary/CensusData.h"
#import "PropertyData.h"
#import "CCodeLibrary/NVDestinationOptions.h"
#import "CCodeLibrary/NVTextVC.h"
#import "CrimeList.h"
@import Charts;

@interface ChartsViewController () <NSURLSessionDataDelegate,NSURLSessionTaskDelegate,ChartViewDelegate,NVAlertViewDelegate>

@property (nonatomic) UIButton *returnButton;
@property (nonatomic) NSMutableArray <CandleChartDataEntry *> *candleDataArray;
@property (nonatomic) NSMutableDictionary *queryCounter;
@property (nonatomic) CandleStickChartView *routingCandleStickChart;
@property (nonatomic) NVColor *color;
@property (nonatomic, copy) NSArray<NSNumber *> *timeArray;
@property int currentSaleVal, durationCount, queryCount, numDays, numEntries;
@property ChartsViewType type;
@property (nonatomic) NVAlertView *alert;
@property (nonatomic) BarChartView *timeLineChart;
@property (nonatomic) ChartDataEntry *currentEntry;

@end

@implementation ChartsViewController

+ (instancetype)chartViewWithType:(ChartsViewType)type
{
    ChartsViewController *chartsVC = ChartsViewController.new;
    chartsVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    chartsVC.type = type;
    return chartsVC;
}

+ (instancetype)routingChartFromDestination:(CLLocationCoordinate2D)fromDestination
                              toDestination:(CLLocationCoordinate2D)toDestination
                                  startTime:(int)startTime
                                    endTime:(int)endTime
                                       span:(TimeArraySpan)span
                                   interval:(int)interval
                                      color:(NVColor *)color
{
    ChartsViewController *chartsVC = ChartsViewController.new;
    chartsVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    chartsVC.fromDestination = fromDestination;
    chartsVC.toDestination = toDestination;
    chartsVC.startTime = startTime;
    chartsVC.endTime = endTime;
    chartsVC.span = span;
    chartsVC.interval = interval;
    chartsVC.type = ChartsViewTypeRouting;
    chartsVC.color = color;
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
        case ChartsViewTypeRouting:
            [self setupRouting];
            break;
        case ChartsViewTypeTimeLine:
            [self setupTimeLine];
            break;
        default:
            break;
    }
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
    data.lineData = [[LineChartData alloc] initWithDataSets:@[emvTotalData, emvBldgData, emvLandData, totalTaxData]];
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
    chart.chartDescription.text = [NSString stringWithFormat:@"Age Distribution for %@ %@", _areaType,_geoid];
    chart.chartDescription.font = [UIFont boldSystemFontOfSize:24.0];
    chart.legend.font = [UIFont systemFontOfSize:16.0];
    chart.rotationEnabled = NO;
    
    [self.view addSubview:chart];
    [chart constrainLeadingToAnchor:self.view.leadingAnchor constant:20.0];
    [chart constrainTrailingToAnchor:self.view.trailingAnchor constant:-20.0];
    [chart constrainTopToAnchor:_returnButton.bottomAnchor];
    [chart constrainBottomToAnchor:self.view.bottomAnchor constant:-20.0];
    
    CensusData *cd = CensusData.new;
    NSArray *values = [cd getCensusChartFieldValues:CAVMalesByAge areaType:_areaType geoID:_geoid];
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
    CombinedChartView *chart = CombinedChartView.new;
    chart.translatesAutoresizingMaskIntoConstraints = NO;
    chart.backgroundColor = UIColor.whiteColor;
    chart.chartDescription.font = [UIFont boldSystemFontOfSize:24.0];
    chart.legend.font = [UIFont systemFontOfSize:16.0];
    chart.pinchZoomEnabled = NO;
    chart.dragEnabled = NO;
    chart.scaleXEnabled = NO;
    chart.scaleYEnabled = NO;
    
    [self.view addSubview:chart];
    [chart constrainLeadingToAnchor:self.view.leadingAnchor constant:20.0];
    [chart constrainTrailingToAnchor:self.view.trailingAnchor constant:-20.0];
    [chart constrainTopToAnchor:_returnButton.bottomAnchor];
    [chart constrainBottomToAnchor:self.view.bottomAnchor constant:-20.0];
    
    CensusData *cd = CensusData.new;
    NSArray *males = [cd getCensusChartFieldValues:CAVMalesByAge areaType:_areaType geoID:_geoid];
    NSArray *females = [cd getCensusChartFieldValues:CAVFemalesByAge areaType:_areaType geoID:_geoid];
    NSMutableArray *totalsArray = NSMutableArray.array;
    NSMutableArray *malesArray = NSMutableArray.array;
    NSMutableArray *femalesArray = NSMutableArray.array;
    double totalTotals = 0, totalMales = 0, totalFemales = 0;
    double totalSumAge = 0, malesSumAge = 0, femalesSumAge = 0;
    double largestValue = 0, barWidth = 1.5;
    
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
        largestValue = MAX(largestValue, totalValue);
        totalTotals += totalValue;
        totalMales += malesValue;
        totalFemales += femalesValue;
        totalSumAge += (totalValue * age);
        malesSumAge += (malesValue * age);
        femalesSumAge += (femalesValue * age);
        
        BarChartDataEntry *data = [[BarChartDataEntry alloc] initWithX:age y:totalValue];
        [totalsArray addObject:data];
        data = [[BarChartDataEntry alloc] initWithX:(age - barWidth) y:malesValue];
        [malesArray addObject:data];
        data = [[BarChartDataEntry alloc] initWithX:(age + barWidth) y:femalesValue];
        [femalesArray addObject:data];
    }
    
    double totalMean = (totalSumAge / totalTotals);
    double malesMean = (malesSumAge / totalMales);
    double femalesMean = (femalesSumAge / totalFemales);
    double topOfChart = (largestValue * 1.1);
    NSArray *meanDashPattern = @[([NSNumber numberWithInt:4]), ([NSNumber numberWithInt:2])];
    
    BarChartDataSet *totalSet = [[BarChartDataSet alloc] initWithValues:totalsArray.copy label:@"Total"];
    totalSet.color = NVColor.darkGreenColor;
    BarChartDataSet *maleSet = [[BarChartDataSet alloc] initWithValues:malesArray.copy label:@"Male"];
    maleSet.color = NVColor.blueColor;
    BarChartDataSet *femaleSet = [[BarChartDataSet alloc] initWithValues:femalesArray.copy label:@"Female"];
    femaleSet.color = NVColor.deepPinkColor;
    
    ChartDataEntry *totalMean1 = [[ChartDataEntry alloc] initWithX:totalMean y:topOfChart];
    ChartDataEntry *totalMean2 = [[ChartDataEntry alloc] initWithX:totalMean y:0];
    LineChartDataSet *totalMeanSet = [[LineChartDataSet alloc] initWithValues:@[totalMean1, totalMean2] label:@""];
    totalMeanSet.color = NVColor.darkGreenColor;
    totalMeanSet.lineWidth = 2.0;
    totalMeanSet.lineDashLengths = meanDashPattern;
    totalMeanSet.drawCirclesEnabled = NO;
    
    ChartDataEntry *malesMean1 = [[ChartDataEntry alloc] initWithX:malesMean y:topOfChart];
    ChartDataEntry *malesMean2 = [[ChartDataEntry alloc] initWithX:malesMean y:0];
    LineChartDataSet *malesMeanSet = [[LineChartDataSet alloc] initWithValues:@[malesMean1, malesMean2] label:@""];
    malesMeanSet.color = NVColor.blueColor;
    malesMeanSet.lineWidth = 2.0;
    malesMeanSet.lineDashLengths = meanDashPattern;
    malesMeanSet.drawCirclesEnabled = NO;
    
    ChartDataEntry *femalesMean1 = [[ChartDataEntry alloc] initWithX:femalesMean y:topOfChart];
    ChartDataEntry *femalesMean2 = [[ChartDataEntry alloc] initWithX:femalesMean y:0];
    LineChartDataSet *femalesMeanSet = [[LineChartDataSet alloc] initWithValues:@[femalesMean1, femalesMean2] label:@""];
    femalesMeanSet.color = NVColor.deepPinkColor;
    femalesMeanSet.lineWidth = 2.0;
    femalesMeanSet.lineDashLengths = meanDashPattern;
    femalesMeanSet.drawCirclesEnabled = NO;
    
    CombinedChartData *data = CombinedChartData.new;
    data.lineData = [[LineChartData alloc] initWithDataSets:@[totalMeanSet, malesMeanSet, femalesMeanSet]];
    data.barData = [[BarChartData alloc] initWithDataSets:@[totalSet, maleSet, femaleSet]];
    data.barData.barWidth = barWidth;
    data.drawValues = NO;
    chart.drawOrder = @[([NSNumber numberWithInt:(CombinedChartDrawOrderLine)]), ([NSNumber numberWithInt:CombinedChartDrawOrderBar])];
    chart.data = data;
    
    chart.xAxis.axisMinimum = (chart.chartXMin - barWidth);
    chart.xAxis.axisMaximum = (chart.chartXMax + barWidth);
    chart.xAxis.labelCount = 18;
    chart.leftAxis.axisMaximum = (largestValue * 1.1);
    chart.rightAxis.axisMaximum = chart.leftAxis.axisMaximum;
    chart.descriptionFont = [UIFont systemFontOfSize:20.0];
    chart.chartDescription.text = [NSString stringWithFormat:@"Age Distribution for %@ %@\nMales:%.0f, Females:%.0f, Total:%.0f",
                                   _areaType, _geoid, totalMales, totalFemales, totalTotals];
}

- (void)setupRouting
{
    _routingCandleStickChart = CandleStickChartView.new;
    _routingCandleStickChart.translatesAutoresizingMaskIntoConstraints = NO;
    _routingCandleStickChart.backgroundColor = UIColor.whiteColor;
    _routingCandleStickChart.legend.font = [UIFont systemFontOfSize:16.0];
    _routingCandleStickChart.hidden = YES;
    _routingCandleStickChart.pinchZoomEnabled = NO;
    _routingCandleStickChart.dragEnabled = NO;
    _routingCandleStickChart.scaleXEnabled = NO;
    _routingCandleStickChart.scaleYEnabled = NO;
    _routingCandleStickChart.chartDescription.text = @"";
    
    [self.view addSubview:_routingCandleStickChart];
    [_routingCandleStickChart constrainLeadingToAnchor:self.view.leadingAnchor constant:20.0];
    [_routingCandleStickChart constrainTrailingToAnchor:self.view.trailingAnchor constant:-20.0];
    [_routingCandleStickChart constrainTopToAnchor:_returnButton.bottomAnchor];
    [_routingCandleStickChart constrainBottomToAnchor:self.view.bottomAnchor constant:-20.0];
    
    _routingCandleStickChart.xAxis.axisMinimum = -0.5;
    _routingCandleStickChart.leftAxis.axisMinimum = _routingCandleStickChart.rightAxis.axisMinimum = 0.0;
    
    _timeArray = [NVDateRange getArrayOfTimesWithStartTime:_startTime
                                                   endTime:_endTime
                                                      span:_span
                                                  interval:_interval];
    
    switch (_span)
    {
        case TimeArraySpanNextDay:
        case TimeArraySpanNextWorkWeekDay:
            _numDays = 1;
            break;
        case TimeArraySpanNextWorkWeek:
            _numDays = 5;
            break;
        case TimeArraySpanNextWeek:
            _numDays = 7;
            break;
        default:
            break;
    }
    
    _numEntries = ((int)_timeArray.count / _numDays);
    _routingCandleStickChart.xAxis.axisMaximum = (_numEntries - 0.5);
    _candleDataArray = [NSMutableArray arrayWithCapacity:_numEntries];
    
    for (int i = 0; i < _numEntries; i++)
    {
        CandleChartDataEntry *zero = [[CandleChartDataEntry alloc] initWithX:i shadowH:0.0 shadowL:0.0 open:0.0 close:9999.0];
        [_candleDataArray addObject:zero];
    }
    
    _queryCounter = NSMutableDictionary.dictionary;
    _durationCount = _queryCount = 0;
    int initialQueries = MIN((int)_timeArray.count, MAX_QUERIES);
    
    for (int i = 0; i < initialQueries; i++)
    {
        NSURLSession *urlSession = self.defaultSession;
        NSURL *url = [self durationQueryURLWithTime:_timeArray[_queryCount].intValue];
        NSURLSessionDataTask *dataTask = [urlSession dataTaskWithURL:url];
        dataTask.taskDescription = [NSString stringWithFormat:@"%i", _queryCount];
        [dataTask resume];
        _queryCount++;
    }
}

- (NSURL *)durationQueryURLWithTime:(int)time
{
    NSString *urlString = [NSString stringWithFormat:@"https://maps.google.com/maps/api/directions/json?"
                           "origin=%f,%f"
                           "&destination=%f,%f"
                           "&departure_time=%i"
                           "&key=%@",
                           _fromDestination.latitude, _fromDestination.longitude,
                           _toDestination.latitude, _toDestination.longitude,
                           time, GOOGLE_API_KEY];
    
    return [NSURL URLWithString:[urlString stringByAddingPercentEncodingWithAllowedCharacters:
                                 NSCharacterSet.URLQueryAllowedCharacterSet]];
}

- (NSURLSession *)defaultSession
{
    NSURLSessionConfiguration *config = NSURLSessionConfiguration.defaultSessionConfiguration;
    config.timeoutIntervalForRequest = 5.0;
    
    return [NSURLSession sessionWithConfiguration:config
                                         delegate:self
                                    delegateQueue:NSOperationQueue.currentQueue];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    [session invalidateAndCancel];
    NSInteger index = dataTask.taskDescription.integerValue;
    BOOL isValid = NO;
    
    if (data && data.length)
    {
        NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *searchString = @"duration_in_traffic";
        
        if (dataString && dataString.length && [dataString containsString:searchString])
        {
            dataString = textAfter(dataString, searchString);
            dataString = textBefore(dataString, @"}");
            dataString = textAfter(dataString, @"value\" : ");
            
            if (dataString.length)
            {
                double durationInSeconds;
                
                if ([[NSScanner scannerWithString:dataString] scanDouble:&durationInSeconds])
                {
                    CandleChartDataEntry *entry = _candleDataArray[index % _numEntries];
                    double duration = (durationInSeconds / 60.0);
                    
                    if (duration > 0.0)
                    {
                        entry.close = MIN(entry.close, duration);
                        entry.open = MAX(entry.open, duration);
                        entry.high = entry.open;
                        isValid = YES;
                        _durationCount++;
                        
                        if (_queryCount < _timeArray.count)
                        {
                            NSURLSession *urlSession = self.defaultSession;
                            NSURL *url = [self durationQueryURLWithTime:_timeArray[_queryCount].intValue];
                            NSURLSessionDataTask *dataTask = [urlSession dataTaskWithURL:url];
                            dataTask.taskDescription = [NSString stringWithFormat:@"%i", _queryCount];
                            [dataTask resume];
                            _queryCount++;
                        }
                        
                        else if (_durationCount >= _timeArray.count)
                        {
                            CandleChartDataSet *durationSet = [[CandleChartDataSet alloc] initWithValues:_candleDataArray.copy
                                                                                                   label:@"Driving Time (in minutes)"];
                            
                            durationSet.color = _color;
                            durationSet.shadowColor = UIColor.blackColor;
                            durationSet.shadowWidth = 5.0;
                            durationSet.drawValuesEnabled = NO;
                            CandleChartData *durationData = [[CandleChartData alloc] initWithDataSet:durationSet];
                            _routingCandleStickChart.data = durationData;
                            _routingCandleStickChart.hidden = NO;
                        }
                    }
                }
            }
        }
    }
    
    if (!isValid)
    {
        int iCount = 0;
        
        if ([_queryCounter.allKeys containsObject:dataTask.taskDescription])
        {
            NSNumber *count = (NSNumber *)[_queryCounter objectForKey:dataTask.taskDescription];
            iCount = (count.intValue + 1);
        }
        
        else
            iCount = 1;
        
        [_queryCounter setObject:[NSNumber numberWithInt:iCount] forKey:dataTask.taskDescription];
        
        if (iCount < 4)
        {
            NSURLSessionConfiguration *config = NSURLSessionConfiguration.defaultSessionConfiguration;
            config.timeoutIntervalForRequest = 5.0;
            
            NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:config
                                                                     delegate:self
                                                                delegateQueue:NSOperationQueue.currentQueue];
            
            NSURLSessionDataTask *theDataTask = [urlSession dataTaskWithURL:dataTask.currentRequest.URL.copy];
            theDataTask.taskDescription = [NSString stringWithFormat:@"%i", (int)index];
            [theDataTask resume];
        }
    }
}

- (void)setupTimeLine
{
    _timeLineChart = BarChartView.new;
    _timeLineChart.translatesAutoresizingMaskIntoConstraints = NO;
    _timeLineChart.backgroundColor = UIColor.whiteColor;
    _timeLineChart.legend.font = [UIFont systemFontOfSize:16.0];
    _timeLineChart.chartDescription.text = @"";
    _timeLineChart.delegate = self;
    
    [self.view addSubview:_timeLineChart];
    [_timeLineChart constrainLeadingToAnchor:self.view.leadingAnchor constant:20.0];
    [_timeLineChart constrainTrailingToAnchor:self.view.trailingAnchor constant:-20.0];
    [_timeLineChart constrainTopToAnchor:_returnButton.bottomAnchor];
    [_timeLineChart constrainBottomToAnchor:self.view.bottomAnchor constant:-20.0];
    
    NSMutableArray<BarChartDataEntry *> *sunEntryArray = NSMutableArray.array;
    NSMutableArray<BarChartDataEntry *> *monEntryArray = NSMutableArray.array;
    NSMutableArray<BarChartDataEntry *> *tuesEntryArray = NSMutableArray.array;
    NSMutableArray<BarChartDataEntry *> *wedEntryArray = NSMutableArray.array;
    NSMutableArray<BarChartDataEntry *> *thursEntryArray = NSMutableArray.array;
    NSMutableArray<BarChartDataEntry *> *friEntryArray = NSMutableArray.array;
    NSMutableArray<BarChartDataEntry *> *satEntryArray = NSMutableArray.array;
    
    for (TimeLine *tl in _timeLineArray)
    {
        BarChartDataEntry *tlDataEntry = [[BarChartDataEntry alloc] initWithX:tl.time y:tl.value];
        tlDataEntry.data = [NSNumber numberWithInt:tl.refno];
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        calendar.locale = NSLocale.currentLocale;
        calendar.timeZone = NSTimeZone.localTimeZone;
        
        NSDateComponents *components = [calendar components:NSCalendarUnitWeekday
                                                   fromDate:[NSDate dateWithTimeIntervalSince1970:tl.time]];
        
        switch (components.weekday)
        {
            case WeekDaySunday:
                [sunEntryArray addObject:tlDataEntry];
                break;
            case WeekDayMonday:
                [monEntryArray addObject:tlDataEntry];
                break;
            case WeekDayTuesday:
                [tuesEntryArray addObject:tlDataEntry];
                break;
            case WeekDayWednesday:
                [wedEntryArray addObject:tlDataEntry];
                break;
            case WeekDayThursday:
                [thursEntryArray addObject:tlDataEntry];
                break;
            case WeekDayFriday:
                [friEntryArray addObject:tlDataEntry];
                break;
            case WeekDaySaturday:
                [satEntryArray addObject:tlDataEntry];
                break;
            default:
                break;
        }
    }
    
    BarChartDataSet *sunDataSet = [[BarChartDataSet alloc] initWithValues:sunEntryArray label:@"Sunday"];
    sunDataSet.color = UIColor.blueColor;
    BarChartDataSet *monDataSet = [[BarChartDataSet alloc] initWithValues:monEntryArray label:@"Monday"];
    monDataSet.color = UIColor.redColor;
    BarChartDataSet *tuesDataSet = [[BarChartDataSet alloc] initWithValues:tuesEntryArray label:@"Tuesday"];
    tuesDataSet.color = UIColor.greenColor;
    BarChartDataSet *wedDataSet = [[BarChartDataSet alloc] initWithValues:wedEntryArray label:@"Wednesday"];
    wedDataSet.color = UIColor.orangeColor;
    BarChartDataSet *thursDataSet = [[BarChartDataSet alloc] initWithValues:thursEntryArray label:@"Thursday"];
    thursDataSet.color = UIColor.purpleColor;
    BarChartDataSet *friDataSet = [[BarChartDataSet alloc] initWithValues:friEntryArray label:@"Friday"];
    friDataSet.color = UIColor.yellowColor;
    BarChartDataSet *satDataSet = [[BarChartDataSet alloc] initWithValues:satEntryArray label:@"Saturday"];
    satDataSet.color = UIColor.brownColor;
    
    BarChartData *tlData = [[BarChartData alloc] initWithDataSets:@[sunDataSet, monDataSet, tuesDataSet,
                                                                    wedDataSet, thursDataSet, friDataSet, satDataSet]];
    
    tlData.barWidth =  ((tlData.xMax - tlData.xMin) / 100.0);
    _timeLineChart.data = tlData;
}

- (void)chartValueSelected:(ChartViewBase *)chartView
                     entry:(ChartDataEntry *)entry
                 highlight:(ChartHighlight *)highlight
{
    if (![self.view.subviews containsObject:_alert])
    {
        int refno = [(NSNumber *)entry.data intValue];
        
        if (refno != 0)
        {
            NSString *title = [NSString stringWithFormat:@"Chart tapped at refno:\n%i", refno];
            NSArray *buttonTextArray = @[@"Cancel", @"Display Crime Report"];
            
            if ([CrimeList incidentInCurrentCrimeList:refno])
                buttonTextArray = @[@"Cancel", @"Display Crime Report", @"Remove from List"];
            
            else if (refno < 0)
            {
                title = @"Chart tapped at present time.";
                buttonTextArray = @[@"OK"];
            }
            
            _alert = [NVAlertView showLargeAlertViewinView:self.view
                                                  delegate:self
                                                     title:title
                                           buttonTextArray:buttonTextArray
                                          destructiveIndex:1];
            _alert.tag = refno;
            _currentEntry = entry;
        }
    }
}

- (void)alertView:(NVAlertView *)alertView
didTapButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex)
    {
        case 1:{//display report
            NSString *reportText = [CrimeData reportForControlNumber:alertView.tag];
            NVTextVC *textVC = [[NVTextVC alloc] initWithText:reportText fontSize:16.0];
            NSArray *searchStrings = _currentSpreadsheet.retrieveSearchStrings;
            
            textVC.redSubstring = @"";
            
            if (searchStrings.count > 0)
                textVC.redSubstring = searchStrings[0];
            
            textVC.greenSubstring = @"";
            
            if (searchStrings.count > 1)
                textVC.greenSubstring = searchStrings[1];
            
            textVC.blueSubstring = @"";
            
            if (searchStrings.count > 2)
                textVC.blueSubstring = searchStrings[2];
            
            [self presentViewController:textVC animated:YES completion:nil];
            break;}
        case 2://remove from list
            if ([CrimeList incidentInCurrentCrimeList:(int)alertView.tag])
            {
                if ([CrimeList removeIncidentInCurrentCrimeList:(int)alertView.tag])
                {
                    for (ChartDataSet *set in _timeLineChart.barData.dataSets)
                    {
                        if ([set contains:_currentEntry])
                        {
                            if ([set removeEntry:_currentEntry])
                                [_timeLineChart setNeedsDisplay];
                        }
                    }
                }
            }
            
            break;
        default:break;
    }
    
    [alertView hideLargeAlertView:YES];
}

@end
