//  MarkerInfoWindow.m
//  GMMobile

#import "MarkerInfoWindow.h"

@interface MarkerInfoWindow ()

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *snippetLabel;
@property (nonatomic) UIButton *optionsButton;
@property (nonatomic) UIButton *propReportButton;

@end

@implementation MarkerInfoWindow

- (id)init
{
    self = [super init];
    
    CGFloat height = 48.0, width = 264.0, margin = 4.0;
    
    if (self)
    {
        self.alpha = 0.9;
        self.backgroundColor = UIColor.whiteColor;
        self.frame = CGRectMake(0.0, 0.0, width, height);
        self.layer.cornerRadius = 6.0;
        self.layer.borderColor = UIColor.lightGrayColor.CGColor;
        self.layer.borderWidth = 0.5;
        
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake
                       (height, margin, (width - (height * 2.0)),
                        ((height - (margin * 2.0)) / 2.0))];
        
        _titleLabel.textColor = UIColor.blackColor;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont systemFontOfSize:16.0];
        [self addSubview:_titleLabel];
        
        _snippetLabel = [[UILabel alloc] initWithFrame:CGRectMake
                         (height, (height / 2.0), (width - (height * 2.0)),
                          ((height - (margin * 2.0)) / 2.0))];
        
        _snippetLabel.textColor = UIColor.blackColor;
        _snippetLabel.textAlignment = NSTextAlignmentCenter;
        _snippetLabel.font = [UIFont systemFontOfSize:10.0];
        [self addSubview:_snippetLabel];
        
        _optionsButton = [[UIButton alloc] initWithFrame:CGRectMake
                          (margin, margin, (height - (margin * 2.0)),
                           (height - (margin * 2.0)))];
        
        [_optionsButton setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"list"
                                                                                                ofType:@"png"]]
                        forState:UIControlStateNormal];
        
        [_optionsButton addTarget:self
                           action:@selector(optionsSelected:)
                 forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:_optionsButton];
        
        _propReportButton = [[UIButton alloc] initWithFrame:CGRectMake
                             (((width - height) + margin), margin, (height - (margin * 2.0)),
                              (height - (margin * 2.0)))];
        
        [_propReportButton setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"arrow"
                                                                                                   ofType:@"png"]]
                           forState:UIControlStateNormal];
        
        [_propReportButton addTarget:self
                              action:@selector(propReportSelected:)
                    forControlEvents:UIControlEventTouchUpInside];
        
        _propReportButton.imageEdgeInsets = UIEdgeInsetsMake(2.0, 2.0, 2.0, 2.0);
        [self addSubview:_propReportButton];
        
        UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(markerInfoSwiped:)];
        
        swipe.direction = UISwipeGestureRecognizerDirectionLeft|UISwipeGestureRecognizerDirectionRight;
        [self addGestureRecognizer:swipe];
    }
    
    return self;
}

- (void)setTitle:(NSString *)title
{
    _titleLabel.text = title;
}

- (void)setSnippet:(NSString *)snippet
{
    _snippetLabel.text = snippet;
}

- (void)optionsSelected:(UIButton *)button
{
    if (_delegate)
    {
        [_delegate markerInfoWindowDidSelectOptions:_titleLabel.text
                                             coords:_position
                                               type:_type];
    }
}

- (void)propReportSelected:(UIButton *)button
{
    if (_delegate)
    {
        [_delegate markerInfoWindowDidSelectPropReport:_titleLabel.text
                                                coords:_position
                                                  type:_type];
    }
}

- (void)markerInfoSwiped:(UISwipeGestureRecognizer *)gesture
{
    if (_delegate)
        [_delegate markerInfoWindowWasSwiped];
}

@end