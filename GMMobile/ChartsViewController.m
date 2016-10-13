//  ChartsViewController.m
//  NVMobile

#import "ChartsViewController.h"
#import "CCodeLibrary/UserDefaults.h"
#import "PropertyData.h"
@import Charts;

@interface ChartsViewController ()

@property (nonatomic) BarChartView *barChart;
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
    
    _barChart = BarChartView.new;
    _barChart.translatesAutoresizingMaskIntoConstraints = NO;
    _barChart.xAxis.labelPosition = XAxisLabelPositionBottom;
    _barChart.backgroundColor = UIColor.whiteColor;
    _barChart.descriptionText = @"";
    [self.view addSubview:_barChart];
    [_barChart constrainLeadingToAnchor:self.view.leadingAnchor constant:20.0];
    [_barChart constrainTrailingToAnchor:self.view.trailingAnchor constant:-20.0];
    [_barChart constrainTopToAnchor:_returnButton.bottomAnchor];
    [_barChart constrainBottomToAnchor:self.view.bottomAnchor constant:-20.0];
    
    NSMutableArray *dataEntries = NSMutableArray.array;
    
    for (int i = 0; i < _propHistoryArray.count; i++)
    {
        PropertyHistory *ph = (PropertyHistory *)_propHistoryArray[i];
        BarChartDataEntry *dataEntry = [[BarChartDataEntry alloc] initWithX:ph.year y:ph.emvTotal];
        [dataEntries addObject:dataEntry];
    }
    
    BarChartDataSet *dataSet = [[BarChartDataSet alloc] initWithValues:dataEntries label:@"Estimated Market Value"];
    dataSet.colors = ChartColorTemplates.colorful;
    
    BarChartData *data = [[BarChartData alloc] initWithDataSet:dataSet];
    _barChart.data = data;
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
