//  NVMetroSettingsVC.m
//  NVMobile

#import "NVMetroSettingsVC.h"
#import "CCodeLibrary/UserDefaults.h"
#import "CCodeLibrary/NVPopoverTableView.h"

@interface NVMetroSettingsVC () <NVPopoverTableViewDelegate>

@property (nonatomic) CGFloat cornerRadius;

@end

@implementation NVMetroSettingsVC

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    _cornerRadius = 10.0;
    
    CGFloat margin = 20.0, bigFont = 36.0, littleFont = 28.0;
    UIView *topView = UIView.new;
    topView.translatesAutoresizingMaskIntoConstraints = NO;
    topView.backgroundColor = UserDefaults.defaults.appleGray;
    topView.layer.cornerRadius = _cornerRadius;
    
    [self.view addSubview:topView];
    [topView constrainTopToAnchor:self.view.topAnchor constant:margin];
    [topView constrainLeadingToAnchor:self.view.leadingAnchor constant:margin];
    [topView constrainTrailingToAnchor:self.view.trailingAnchor constant:-margin];
    
    UIView *bottomView = UIView.new;
    bottomView.translatesAutoresizingMaskIntoConstraints = NO;
    bottomView.backgroundColor = UserDefaults.defaults.appleGray;
    bottomView.layer.cornerRadius = _cornerRadius;
    
    [self.view addSubview:bottomView];
    [bottomView constrainTopToAnchor:topView.bottomAnchor constant:margin];
    [bottomView constrainLeadingToAnchor:self.view.leadingAnchor constant:margin];
    [bottomView constrainTrailingToAnchor:self.view.trailingAnchor constant:-margin];
    [bottomView constrainBottomToAnchor:self.view.bottomAnchor constant:-margin];
    [bottomView constrainHeightToAnchor:topView.heightAnchor multiplier:0.5];
    
    UILabel *topLabel = UILabel.new;
    topLabel.text = @"Choropleth Parameters";
    [self setupLabel:topLabel fontSize:bigFont];
    topLabel.textAlignment = NSTextAlignmentCenter;
    
    UILabel *bottomLabel = UILabel.new;
    bottomLabel.text = @"Spreadsheet Display Parameters";
    [self setupLabel:bottomLabel fontSize:bigFont];
    bottomLabel.textAlignment = NSTextAlignmentCenter;
    
    UILabel *featureLabel = UILabel.new;
    featureLabel.text = @"Feature:";
    [self setupLabel:featureLabel fontSize:littleFont];
    
    UILabel *valueLabel = UILabel.new;
    valueLabel.text = @"Value:";
    [self setupLabel:valueLabel fontSize:littleFont];
    
    UILabel *overUnderLabel = UILabel.new;
    overUnderLabel.text = @"Over/Under:";
    [self setupLabel:overUnderLabel fontSize:littleFont];
    
    UILabel *colorSchemeLabel = UILabel.new;
    colorSchemeLabel.text = @"Color Scheme:";
    [self setupLabel:colorSchemeLabel fontSize:littleFont];
    
    UILabel *textLabel = UILabel.new;
    textLabel.text = @"Text:";
    [self setupLabel:textLabel fontSize:littleFont];
    
    UIButton *featureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [featureButton setTitle:@" Parcels " forState:UIControlStateNormal];
    [self setupButton:featureButton fontSize:littleFont];
    
    UIButton *valueButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [valueButton setTitle:@" Total Tax " forState:UIControlStateNormal];
    [self setupButton:valueButton fontSize:littleFont];
    
    UIButton *colorSchemeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [colorSchemeButton setTitle:@" Red / Blue " forState:UIControlStateNormal];
    [self setupButton:colorSchemeButton fontSize:littleFont];
    
    UIButton *textButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [textButton setTitle:@" Taxpayer / Total EMT " forState:UIControlStateNormal];
    [self setupButton:textButton fontSize:littleFont];
    
    UISwitch *overUnderSwitch = UISwitch.new;
    overUnderSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    overUnderSwitch.tintColor = UIColor.redColor;
    overUnderSwitch.onTintColor = UIColor.greenColor;
    overUnderSwitch.on = YES;
    
    [overUnderSwitch addTarget:self
                        action:@selector(overUnderSwitchTapped:)
              forControlEvents:UIControlEventValueChanged];
    
    UISegmentedControl *segControl =
    [[UISegmentedControl alloc] initWithItems:@[@"Pin Map", @"Tags", @"Shaded Areas"]];
    
    segControl.translatesAutoresizingMaskIntoConstraints = NO;
    segControl.tintColor = UIColor.blackColor;
    segControl.selectedSegmentIndex = 0;
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont boldSystemFontOfSize:littleFont]};
    [segControl setTitleTextAttributes:attributes forState:UIControlStateNormal];
    
    [segControl addTarget:self
                   action:@selector(segControlTapped:)
         forControlEvents:UIControlEventValueChanged];
    
    for (int i = 1; i < 9; i++)
    {
        UIView *view = UIView.new;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        view.layer.borderColor = UserDefaults.defaults.appleBlue.CGColor;
        view.layer.borderWidth = 1.0;
        view.tag = i;
        
        if (i < 7)
        {
            [topView addSubview:view];
            [view constrainLeadingToAnchor:topView.leadingAnchor];
            [view constrainTrailingToAnchor:topView.trailingAnchor];
        }
        
        else
        {
            [bottomView addSubview:view];
            [view constrainLeadingToAnchor:bottomView.leadingAnchor];
            [view constrainTrailingToAnchor:bottomView.trailingAnchor];
        }
        
        switch (i)
        {
            case 1:
                [view addSubview:topLabel];
                [topLabel constrainToView:view leading:0.0 trailing:0.0 top:0.0 bottom:0.0];
                [view constrainTopToAnchor:topView.topAnchor];
                break;
            
            case 2:
                [view addSubview:featureLabel];
                [featureLabel constrainCenterYToAnchor:view.centerYAnchor];
                [featureLabel constrainTrailingToAnchor:view.centerXAnchor constant:-margin];
                [view addSubview:featureButton];
                [featureButton constrainCenterYToAnchor:view.centerYAnchor];
                [featureButton constrainLeadingToAnchor:view.centerXAnchor constant:margin];
                featureButton.tag = i;
                [view constrainTopToAnchor:[topView viewWithTag:i-1].bottomAnchor];
                [view constrainHeightToAnchor:[topView viewWithTag:i-1].heightAnchor];
                break;
                
            case 3:
                [view addSubview:valueLabel];
                [valueLabel constrainCenterYToAnchor:view.centerYAnchor];
                [valueLabel constrainTrailingToAnchor:view.centerXAnchor constant:-margin];
                [view addSubview:valueButton];
                [valueButton constrainCenterYToAnchor:view.centerYAnchor];
                [valueButton constrainLeadingToAnchor:view.centerXAnchor constant:margin];
                valueButton.tag = i;
                [view constrainTopToAnchor:[topView viewWithTag:i-1].bottomAnchor];
                [view constrainHeightToAnchor:[topView viewWithTag:i-1].heightAnchor];
                break;
                
            case 4:
                [view addSubview:overUnderLabel];
                [overUnderLabel constrainCenterYToAnchor:view.centerYAnchor];
                [overUnderLabel constrainTrailingToAnchor:view.centerXAnchor constant:-margin];
                [view addSubview:overUnderSwitch];
                [overUnderSwitch constrainCenterYToAnchor:view.centerYAnchor];
                [overUnderSwitch constrainLeadingToAnchor:view.centerXAnchor constant:margin];
                [view constrainTopToAnchor:[topView viewWithTag:i-1].bottomAnchor];
                [view constrainHeightToAnchor:[topView viewWithTag:i-1].heightAnchor];
                break;
                
            case 5:
                [view addSubview:colorSchemeLabel];
                [colorSchemeLabel constrainCenterYToAnchor:view.centerYAnchor];
                [colorSchemeLabel constrainTrailingToAnchor:view.centerXAnchor constant:-margin];
                [view addSubview:colorSchemeButton];
                [colorSchemeButton constrainCenterYToAnchor:view.centerYAnchor];
                [colorSchemeButton constrainLeadingToAnchor:view.centerXAnchor constant:margin];
                colorSchemeButton.tag = i;
                [view constrainTopToAnchor:[topView viewWithTag:i-1].bottomAnchor];
                [view constrainHeightToAnchor:[topView viewWithTag:i-1].heightAnchor];
                break;
                
            case 6:
                [view addSubview:textLabel];
                [textLabel constrainCenterYToAnchor:view.centerYAnchor];
                [textLabel constrainTrailingToAnchor:view.centerXAnchor constant:-margin];
                [view addSubview:textButton];
                [textButton constrainCenterYToAnchor:view.centerYAnchor];
                [textButton constrainLeadingToAnchor:view.centerXAnchor constant:margin];
                textButton.tag = i;
                [view constrainTopToAnchor:[topView viewWithTag:i-1].bottomAnchor];
                [view constrainHeightToAnchor:[topView viewWithTag:i-1].heightAnchor];
                [view constrainBottomToAnchor:topView.bottomAnchor];
                break;
                
            case 7:
                [view addSubview:bottomLabel];
                [bottomLabel constrainToView:view leading:0.0 trailing:0.0 top:0.0 bottom:0.0];
                [view constrainTopToAnchor:bottomView.topAnchor];
                break;
                
            case 8:
                [view constrainTopToAnchor:[bottomView viewWithTag:i-1].bottomAnchor];
                [view constrainHeightToAnchor:[bottomView viewWithTag:i-1].heightAnchor];
                [view constrainBottomToAnchor:bottomView.bottomAnchor];
                [view addSubview:segControl];
                [segControl constrainCenterXToAnchor:view.centerXAnchor];
                [segControl constrainTopToAnchor:view.centerYAnchor constant:-margin];
                [segControl constrainBottomToAnchor:view.centerYAnchor constant:margin];
                break;
                
            default:
                break;
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setupLabel:(UILabel *)label
          fontSize:(CGFloat)fontSize
{
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        fontSize /= 1.8;
    
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.backgroundColor = UIColor.clearColor;
    label.font = [UIFont boldSystemFontOfSize:fontSize];
    label.textAlignment = NSTextAlignmentRight;
    label.textColor = UIColor.blackColor;
}

- (void)setupButton:(UIButton *)button
           fontSize:(CGFloat)fontSize
{
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        fontSize /= 1.8;
    
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.backgroundColor = UIColor.blackColor;
    button.layer.cornerRadius = _cornerRadius;
    button.titleLabel.textAlignment = NSTextAlignmentLeft;
    button.titleLabel.font = [UIFont boldSystemFontOfSize:fontSize];
    
    [button setTitleColor:UIColor.whiteColor
                 forState:UIControlStateNormal];
    
    [button setTitleColor:UIColor.lightGrayColor
                 forState:UIControlStateHighlighted];
    
    [button addTarget:self
               action:@selector(settingsButtonTapped:)
     forControlEvents:UIControlEventTouchUpInside];
}

- (void)settingsButtonTapped:(UIButton *)button
{
    NSString *keyword = @"";
    
    switch (button.tag)
    {
        case 2:
            keyword = @"Feature";
            break;
            
        case 3:
            keyword = @"Value";
            break;
            
        case 5:
            keyword = @"Color Scheme";
            break;
            
        case 6:
            keyword = @"Text";
            break;
            
        default:
            break;
    }
    
    NVPopoverTableView *nvptv =
    [NVPopoverTableView showPopoverTableViewInView:self.view
                                          delegate:self
                                             title:[NSString stringWithFormat:@"%@ Options", keyword]
                                         textArray:@[(button.titleLabel.text)]
                                     includeCancel:YES];
    
    nvptv.tag = button.tag;
}

- (void)popoverTableView:(NVPopoverTableView *)popoverTableView
    didSelectRowWithText:(NSString *)text
                 atIndex:(NSInteger)index
{
    switch (popoverTableView.tag)
    {
        case 2://feature
            break;
            
        case 3://value
            break;
            
        case 5://color scheme
            break;
            
        case 6://text
            break;
            
        default:
            break;
    }
    
    [popoverTableView hide:YES];
}

- (void)popoverTableViewDidCancel:(NVPopoverTableView *)popoverTableView
{
    [popoverTableView hide:YES];
}

- (void)overUnderSwitchTapped:(UISwitch *)theSwitch
{
    
}

- (void)segControlTapped:(UISegmentedControl *)segControl
{
    
}

@end
