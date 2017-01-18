//  NVMetroSettingsVC.m
//  NVMobile

#import "NVMetroSettingsVC.h"
#import "CCodeLibrary/UserDefaults.h"
#import "CCodeLibrary/NVPopoverTableView.h"

@interface NVMetroSettingsVC () <NVPopoverTableViewDelegate>

@property (nonatomic) UIButton *featureButton, *valueButton, *adjButton, *textButton;
@property NSArray *optionsList;


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
    CGFloat cornerRadius = 10.0, margin = 16.0, bigFont = 36.0, littleFont = 28.0;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        margin = 6.0, bigFont = 20.0, littleFont = 18.0, cornerRadius = 4.0;
    
    UIView *topView = UIView.new;
    topView.translatesAutoresizingMaskIntoConstraints = NO;
    topView.backgroundColor = UserDefaults.defaults.appleGray;
    topView.layer.cornerRadius = cornerRadius;
    
    [self.view addSubview:topView];
    [topView constrainTopToAnchor:self.view.topAnchor constant:margin];
    [topView constrainLeadingToAnchor:self.view.leadingAnchor constant:margin];
    [topView constrainTrailingToAnchor:self.view.trailingAnchor constant:-margin];
    
    UIView *bottomView = UIView.new;
    bottomView.translatesAutoresizingMaskIntoConstraints = NO;
    bottomView.backgroundColor = UserDefaults.defaults.appleGray;
    bottomView.layer.cornerRadius = cornerRadius;
    
    [self.view addSubview:bottomView];
    [bottomView constrainTopToAnchor:topView.bottomAnchor constant:margin];
    [bottomView constrainLeadingToAnchor:self.view.leadingAnchor constant:margin];
    [bottomView constrainTrailingToAnchor:self.view.trailingAnchor constant:-margin];
    [bottomView constrainBottomToAnchor:self.view.bottomAnchor constant:-margin];
    [bottomView constrainHeightToAnchor:topView.heightAnchor multiplier:0.25];
    
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
    
    UILabel *adjLabel = UILabel.new;
    adjLabel.text = @"Adjustment:";
    [self setupLabel:adjLabel fontSize:littleFont];
    
    UILabel *overUnderLabel = UILabel.new;
    overUnderLabel.text = @"Over/Under:";
    [self setupLabel:overUnderLabel fontSize:littleFont];
    
    UILabel *colorSchemeLabel = UILabel.new;
    colorSchemeLabel.text = @"Color Scheme:";
    [self setupLabel:colorSchemeLabel fontSize:littleFont];
    
    UILabel *transparencyLabel = UILabel.new;
    transparencyLabel.text = @"Transparency:";
    [self setupLabel:transparencyLabel fontSize:littleFont];
    
    UILabel *textLabel = UILabel.new;
    textLabel.text = @"Text:";
    [self setupLabel:textLabel fontSize:littleFont];
    
    _featureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_featureButton setTitle:paddedString([NVMetroSettings.sharedInstance currentFeatureText]) forState:UIControlStateNormal];
    [self setupButton:_featureButton fontSize:littleFont];
    
    _valueButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_valueButton setTitle:paddedString([NVMetroSettings.sharedInstance currentValueText]) forState:UIControlStateNormal];
    [self setupButton:_valueButton fontSize:littleFont];
    
    _adjButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_adjButton setTitle:paddedString([NVMetroSettings.sharedInstance currentAdjustmentText]) forState:UIControlStateNormal];
    [self setupButton:_adjButton fontSize:littleFont];
    
    UIButton *colorSchemeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [colorSchemeButton setTitle:paddedString(@"Red / Blue") forState:UIControlStateNormal];
    [self setupButton:colorSchemeButton fontSize:littleFont];
    
    _textButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_textButton setTitle:paddedString(@"Taxpayer / Total EMT") forState:UIControlStateNormal];
    [self setupButton:_textButton fontSize:littleFont];
    
    UISlider *transparencySlider = UISlider.new;
    transparencySlider.translatesAutoresizingMaskIntoConstraints = NO;
    transparencySlider.continuous = NO;
    
    [transparencySlider addTarget:self
                           action:@selector(transparencySliderChanged:)
                 forControlEvents:UIControlEventValueChanged];
    
    UISwitch *overUnderSwitch = UISwitch.new;
    overUnderSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    overUnderSwitch.tintColor = UIColor.redColor;
    overUnderSwitch.onTintColor = UIColor.greenColor;
    overUnderSwitch.on = NO;
    
    [overUnderSwitch addTarget:self
                        action:@selector(overUnderSwitchTapped:)
              forControlEvents:UIControlEventValueChanged];
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont boldSystemFontOfSize:littleFont]};
    
    UISegmentedControl *controlClassSC =
    [[UISegmentedControl alloc] initWithItems:@[@"Equal Ranges", @"Equal Counts"]];
    
    controlClassSC.translatesAutoresizingMaskIntoConstraints = NO;
    controlClassSC.tintColor = UIColor.blackColor;
    controlClassSC.selectedSegmentIndex = NVMetroSettings.sharedInstance.themeClassType;
    [controlClassSC setTitleTextAttributes:attributes forState:UIControlStateNormal];
    
    [controlClassSC addTarget:self
                       action:@selector(controlClassSCTapped:)
             forControlEvents:UIControlEventValueChanged];
    
    UISegmentedControl *displayParamsSC =
    [[UISegmentedControl alloc] initWithItems:@[@"Pin Map", @"Tags", @"Shaded Areas"]];
    
    displayParamsSC.translatesAutoresizingMaskIntoConstraints = NO;
    displayParamsSC.tintColor = UIColor.blackColor;
    displayParamsSC.selectedSegmentIndex = 0;
    [displayParamsSC setTitleTextAttributes:attributes forState:UIControlStateNormal];
    
    [displayParamsSC addTarget:self
                        action:@selector(displayParamsSCTapped:)
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
                [featureLabel constrainLeadingToAnchor:view.leadingAnchor constant:margin];
                [view addSubview:_featureButton];
                [_featureButton constrainCenterYToAnchor:view.centerYAnchor];
                [_featureButton constrainLeadingToAnchor:featureLabel.trailingAnchor constant:margin];
                [_featureButton.trailingAnchor constraintLessThanOrEqualToAnchor:view.trailingAnchor constant:(-margin * 0.5)].active = YES;
                _featureButton.tag = 22;
                [featureLabel constrainCenterYToAnchor:_featureButton.centerYAnchor];
                [view constrainTopToAnchor:[topView viewWithTag:i-1].bottomAnchor];
                [view constrainHeightToAnchor:[topView viewWithTag:i-1].heightAnchor multiplier:1.75];
                break;
                
            case 3:
                [view addSubview:valueLabel];
                [valueLabel constrainLeadingToAnchor:view.leadingAnchor constant:margin];
                [view addSubview:_valueButton];
                [_valueButton constrainBottomToAnchor:view.centerYAnchor];
                [_valueButton constrainLeadingToAnchor:valueLabel.trailingAnchor constant:margin];
                [_valueButton.trailingAnchor constraintLessThanOrEqualToAnchor:view.trailingAnchor constant:(-margin * 0.5)].active = YES;
                _valueButton.tag = 33;
                [valueLabel constrainCenterYToAnchor:_valueButton.centerYAnchor];
                [view addSubview:adjLabel];
                [adjLabel constrainLeadingToAnchor:view.leadingAnchor constant:margin];
                [view addSubview:_adjButton];
                [_adjButton constrainBottomToAnchor:view.bottomAnchor constant:(-margin * 0.4)];
                [_adjButton constrainLeadingToAnchor:adjLabel.trailingAnchor constant:margin];
                [_adjButton.trailingAnchor constraintLessThanOrEqualToAnchor:view.trailingAnchor constant:(-margin * 0.5)].active = YES;
                _adjButton.tag = 44;
                [adjLabel constrainCenterYToAnchor:_adjButton.centerYAnchor];
                [view constrainTopToAnchor:[topView viewWithTag:i-1].bottomAnchor];
                [view constrainHeightToAnchor:[topView viewWithTag:i-1].heightAnchor multiplier:1.5];
                break;
                
            case 4:
                [view addSubview:overUnderLabel];
                [overUnderLabel constrainLeadingToAnchor:view.leadingAnchor constant:margin];
                [overUnderLabel constrainCenterYToAnchor:view.centerYAnchor];
                [view addSubview:overUnderSwitch];
                [overUnderSwitch constrainLeadingToAnchor:overUnderLabel.trailingAnchor constant:margin];
                [overUnderSwitch constrainCenterYToAnchor:view.centerYAnchor];
                [view addSubview:controlClassSC];
                [controlClassSC constrainTrailingToAnchor:view.trailingAnchor constant:-margin];
                [controlClassSC constrainCenterYToAnchor:view.centerYAnchor];
                [controlClassSC constrainHeightToConstant:bigFont];
                [view constrainTopToAnchor:[topView viewWithTag:i-1].bottomAnchor];
                [view constrainHeightToAnchor:[topView viewWithTag:i-2].heightAnchor];
                break;
                
            case 5:
                [view addSubview:colorSchemeLabel];
                [colorSchemeLabel constrainLeadingToAnchor:view.leadingAnchor constant:margin];
                [view addSubview:colorSchemeButton];
                [colorSchemeButton constrainBottomToAnchor:view.centerYAnchor constant:(-margin * 0.4)];
                [colorSchemeButton constrainLeadingToAnchor:colorSchemeLabel.trailingAnchor constant:margin];
                [colorSchemeButton.trailingAnchor constraintLessThanOrEqualToAnchor:view.trailingAnchor constant:(-margin * 0.4)].active = YES;
                colorSchemeButton.tag = 55;
                [colorSchemeLabel constrainCenterYToAnchor:colorSchemeButton.centerYAnchor];
                [view addSubview:transparencyLabel];
                [transparencyLabel constrainLeadingToAnchor:view.leadingAnchor constant:margin];
                [transparencyLabel constrainTopToAnchor:view.centerYAnchor constant:(margin * 0.4)];
                [view addSubview:transparencySlider];
                [transparencySlider constrainLeadingToAnchor:transparencyLabel.trailingAnchor constant:margin];
                [transparencySlider constrainTrailingToAnchor:view.trailingAnchor constant:-margin];
                [transparencySlider constrainTopToAnchor:transparencyLabel.topAnchor];
                [view constrainTopToAnchor:[topView viewWithTag:i-1].bottomAnchor];
                [view constrainHeightToAnchor:[topView viewWithTag:i-1].heightAnchor multiplier:1.25];
                break;
                
            case 6:
                [view addSubview:textLabel];
                [textLabel constrainLeadingToAnchor:view.leadingAnchor constant:margin];
                [view addSubview:_textButton];
                [_textButton constrainCenterYToAnchor:view.centerYAnchor];
                [_textButton constrainLeadingToAnchor:textLabel.trailingAnchor constant:margin];
                [_textButton.trailingAnchor constraintLessThanOrEqualToAnchor:view.trailingAnchor constant:(-margin * 0.5)].active = YES;
                _textButton.tag = 66;
                [textLabel constrainCenterYToAnchor:_textButton.centerYAnchor];
                [view constrainTopToAnchor:[topView viewWithTag:i-1].bottomAnchor];
                [view constrainHeightToAnchor:[topView viewWithTag:i-2].heightAnchor];
                [view constrainBottomToAnchor:topView.bottomAnchor];
                break;
                
            case 7:
                [view addSubview:bottomLabel];
                [bottomLabel constrainToView:view leading:0.0 trailing:0.0 top:0.0 bottom:0.0];
                [view constrainTopToAnchor:bottomView.topAnchor];
                break;
                
            case 8:
                [view constrainTopToAnchor:[bottomView viewWithTag:i-1].bottomAnchor];
                [view constrainHeightToAnchor:[bottomView viewWithTag:i-1].heightAnchor multiplier:1.5];
                [view constrainBottomToAnchor:bottomView.bottomAnchor];
                [view addSubview:displayParamsSC];
                [displayParamsSC constrainCenterXToAnchor:view.centerXAnchor];
                [displayParamsSC constrainCenterYToAnchor:view.centerYAnchor];
                [displayParamsSC constrainHeightToConstant:bigFont];
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

- (BOOL)prefersStatusBarHidden
{
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        return YES;
    
    else
        return NO;
}

- (void)setupLabel:(UILabel *)label
          fontSize:(CGFloat)fontSize
{
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.backgroundColor = UIColor.clearColor;
    label.font = [UIFont boldSystemFontOfSize:fontSize];
    label.textAlignment = NSTextAlignmentRight;
    label.textColor = UIColor.blackColor;
}

- (void)setupButton:(UIButton *)button
           fontSize:(CGFloat)fontSize
{
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.titleLabel.textAlignment = NSTextAlignmentLeft;
    button.titleLabel.backgroundColor = UIColor.blackColor;
    button.titleLabel.font = [UIFont boldSystemFontOfSize:fontSize];
    button.titleLabel.numberOfLines = 0;
    button.titleLabel.layer.masksToBounds = NO;
    button.titleLabel.layer.shadowColor = UIColor.blackColor.CGColor;
    button.titleLabel.layer.shadowRadius = 0.0;
    button.titleLabel.layer.shadowOpacity = 1.0;
    button.titleLabel.layer.shadowOffset = CGSizeMake(-6.0, 0.0);
    button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    
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
    BOOL multipleSelect = NO;
    
    switch (button.tag)
    {
        case 22:
            keyword = @"Feature";
            _optionsList = NVMetroSettings.sharedInstance.features;
            break;
            
        case 33:
            keyword = @"Value";
            _optionsList = [NVMetroSettings.sharedInstance valuesForFeature:NVMetroSettings.sharedInstance.currentFeature];
            multipleSelect = YES;
            break;
            
        case 44:
            keyword = @"Adjustment";
            _optionsList = NVMetroSettings.sharedInstance.adjustmentOptions;
            break;
            
        case 55:
            keyword = @"Color Scheme";
            _optionsList = @[@"Red/Blue", @"Amelia's Favorite Colors", @"Really Dumb Colors"];
            break;
            
        case 66:
            keyword = @"Text";
            _optionsList = NVMetroSettings.sharedInstance.currentTextOptions;
            break;
            
        default:
            break;
    }
    
    NVPopoverTableView *nvptv =
    [NVPopoverTableView showPopoverTableViewInView:self.view
                                          delegate:self
                                             title:[NSString stringWithFormat:@"%@ Options", keyword]
                                         textArray:_optionsList
                                     includeCancel:YES];
    
    nvptv.allowsMultipleSelection = multipleSelect;
    nvptv.tag = button.tag;
}

- (void)popoverTableView:(NVPopoverTableView *)popoverTableView
    didSelectRowWithText:(NSString *)text
                 atIndex:(NSInteger)index
{
    switch (popoverTableView.tag)
    {
        case 22://feature
            NVMetroSettings.sharedInstance.currentFeature = index;
            [_featureButton setTitle:paddedString([NVMetroSettings.sharedInstance currentFeatureText]) forState:UIControlStateNormal];
            [_valueButton setTitle:paddedString([NVMetroSettings.sharedInstance currentValueText]) forState:UIControlStateNormal];
            break;
            
        case 33://value
            [NVMetroSettings.sharedInstance setCurrentValue:index];
            [_valueButton setTitle:paddedString([NVMetroSettings.sharedInstance currentValueText]) forState:UIControlStateNormal];
            break;
            
        case 44://adjustment
            NVMetroSettings.sharedInstance.currentAdjustmentValue = index;
            [_adjButton setTitle:paddedString([NVMetroSettings.sharedInstance currentAdjustmentText]) forState:UIControlStateNormal];

            break;
            
        case 55://color scheme
            break;
            
        case 66://text
        {
            NSString * option = _optionsList[index];
            NSString * textIndex = textAfter(option, @"\x04");
            

            [NVMetroSettings.sharedInstance currentTextSelection:(int)textIndex.integerValue];
            [_textButton setTitle:paddedString([NVMetroSettings.sharedInstance currentAdjustmentText]) forState:UIControlStateNormal];
        }
            break;
            
        default:
            break;
    }
    
    [popoverTableView hide:YES];
}

- (void)popoverTableView:(NVPopoverTableView *)popoverTableView
didReturnWithSelectedRows:(NSArray *)selectedRows
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
    NVMetroSettings.sharedInstance.overUnder = theSwitch.on;
}

- (void)displayParamsSCTapped:(UISegmentedControl *)segControl
{
    
}

- (void)controlClassSCTapped:(UISegmentedControl *)segControl
{
    NVMetroSettings.sharedInstance.themeClassType = (int)segControl.selectedSegmentIndex;
}

- (void)pctPopSCTapped:(UISegmentedControl *)segControl
{
    
}

- (void)transparencySliderChanged:(UISlider *)slider
{
    NVMetroSettings.sharedInstance.themeTransparency = slider.value;
}

@end
