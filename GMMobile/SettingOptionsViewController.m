//  SettingOptionsViewController.m
//  GMMobile

#import "SettingOptionsViewController.h"
#import "ConfigurationControl.h"
#import "CCodeLibrary/NVCalibrationController.h"
#import "CCodeLibrary/GSSiPopoverView.h"
#import <CommonCrypto/CommonDigest.h>
#import "CCodeLibrary/UserDefaults.h"
#import "AppDelegate.h"
#import "ReaderViewController.h"
@import MediaPlayer;
@import GLKit;
#import "CCodeLibrary/NVCalendarVC.h"
#import "CCodeLibrary/NVSynchronizeVC.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@interface SettingOptionsViewController () <ReaderViewControllerDelegate,GLKViewDelegate,NVSynchronizeDelegate>

@property (nonatomic, copy) NSArray *contents, *images;
@property (nonatomic) NVContactPicker *nvcp;
@property (nonatomic) FTPDataPush *push;
@property (nonatomic, copy) NSArray *products;
@property (nonatomic, copy) NSString *iapFilePath;
@property (nonatomic) MPMoviePlayerController *mpController;
@property (nonatomic) GLKView *glView;
@property (nonatomic) CADisplayLink *displayLink;
@property (nonatomic) GLKBaseEffect *effect;
@property (nonatomic) EAGLContext *context;
@property (nonatomic) GLuint vertexArray, vertexBuffer, indexBuffer;
@property (nonatomic) CGFloat rotation;
@property (nonatomic) UIImageView *hotspotView;
@property (nonatomic) vec3 *vecGrid;
@property (nonatomic) int len;
@property (nonatomic) CrimeData *cd;

@end

@implementation SettingOptionsViewController

- (void)setupHotspotTest
{
    const char *filepath = [NSBundle.mainBundle pathForResource:@"hotspottest"
                                                         ofType:@"bin"].UTF8String;
    
    FILE *fid = fopen(filepath, "rb");
    
    if (fid)
    {
        int height = 0, width = 0;
        fread(&height, sizeof(int), 1, fid);
        fread(&width, sizeof(int), 1, fid);
        _len = (width * height);
        BYTE *pgrid = malloc(_len * sizeof(BYTE) + 4);
        fread(pgrid, sizeof(BYTE), _len, fid);
        fclose(fid);
        
        _vecGrid = malloc(_len * sizeof(vec3) + 4);
        
        for (int i = 0; i < _len; i++)
        {
            float column = floorf(i / (float)width);
            float row = (float)(i - (column * width));
            
            _vecGrid[i].x = (float)(((row / (width - 1)) * 4.0) - 2.0);
            _vecGrid[i].y = (float)(((column / (height - 1)) * 4.0) - 2.0);
            _vecGrid[i].z = (float)((pgrid[i] / 31.0) - 0.5);
        }
        
        /*BYTE *blueGrid = malloc((_len * 4) * sizeof(BYTE) + 4);
        
        for (int i = 0; i < _len; i++)
        {
            int j = (i * 4);
            BYTE rgVal = (255 - (pgrid[i] * 8));
            blueGrid[j] = rgVal;
            blueGrid[j + 1] = rgVal;
            blueGrid[j + 2] = 255;
            blueGrid[j + 3] = 255;
        }*/
        
        free(pgrid);
        
        [self createGLView];
        
        /*CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
        CFDataRef imageData = CFDataCreate(NULL, blueGrid, (_len * 4));
        
        free(blueGrid);
        
        CGDataProviderRef provider = CGDataProviderCreateWithCFData(imageData);
        
        CGImageRef gridImageRef = CGImageCreate(width, height, 8, 32, (width * 4), colorspace,
                                                kCGBitmapByteOrderDefault, provider,
                                                NULL, YES, kCGRenderingIntentDefault);
        
        CFRelease(imageData);
        CGDataProviderRelease(provider);
        CGColorSpaceRelease(colorspace);
        UIImage *gridImage = [UIImage imageWithCGImage:gridImageRef];
        _hotspotView = [[UIImageView alloc] initWithImage:gridImage];
        _hotspotView.backgroundColor = UIColor.blackColor;
        _hotspotView.contentMode = UIViewContentModeScaleAspectFit;
        _hotspotView.translatesAutoresizingMaskIntoConstraints = NO;
        _hotspotView.userInteractionEnabled = YES;
        [self.view addSubview:_hotspotView];
        
        self.tabBarController.tabBar.hidden = YES;
        
        [_hotspotView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
        
        [_hotspotView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor
                                                  constant:self.tabBarController.tabBar.frame.size.height].active = YES;
        
        [_hotspotView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
        [_hotspotView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
        
        CGImageRelease(gridImageRef);*/
    }
}

- (void)createGLView
{
    _context = CreateBestEAGLContext();
    
    if (!_context)
        NSLog(@"Failed to create OpenGLES context");
    
    EAGLContext.currentContext = _context;
    
    _glView = [[GLKView alloc] init];
    _glView.translatesAutoresizingMaskIntoConstraints = NO;
    _glView.context = _context;
    _glView.delegate = self;
    _glView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    [self.view addSubview:_glView];
    
    self.tabBarController.tabBar.hidden = YES;
    
    [_glView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    
    [_glView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor
                                         constant:self.tabBarController.tabBar.frame.size.height].active = YES;
    
    [_glView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [_glView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    
    [self setUpGL];
    
    _displayLink = [CADisplayLink displayLinkWithTarget:self
                                               selector:@selector(drawFrame)];
    
    [_displayLink addToRunLoop:NSRunLoop.currentRunLoop
                       forMode:NSDefaultRunLoopMode];
}

- (void)setUpGL
{
    /*UIImage *image = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"brick_texture"
                                                                                    ofType:@"png"]];
    
    NSError *error;
    
    GLKTextureInfo *texture = [GLKTextureLoader textureWithCGImage:image.CGImage
                                                           options:nil
                                                             error:&error];
    
    if (!texture)
        NSLog(@"ERROR loading texture: %@", error.localizedDescription);*/
    
    _effect = [[GLKBaseEffect alloc] init];
    _effect.light0.enabled = GL_TRUE;
    _effect.light0.diffuseColor = GLKVector4Make(0.6, 0.6, 0.6, 1.0);
    _effect.light0.ambientColor = GLKVector4Make(0.4, 0.4, 0.4, 1.0);
    _effect.material.emissiveColor = GLKVector4Make(0.6, 0.6, 0.6, 1.0);
    _effect.material.ambientColor = GLKVector4Make(0.4, 0.4, 0.4, 1.0);
    /*_effect.texture2d0.enabled = GL_TRUE;
    _effect.texture2d0.envMode = GLKTextureEnvModeReplace;
    _effect.texture2d0.name = texture.name;
    _effect.texture2d0.target = texture.target;*/
    
    /*GLfloat gCubeVertexData[216] =
    {
        1.0, -1.0, -1.0,         1.0,  0.0,  0.0,
        1.0,  1.0, -1.0,         1.0,  0.0,  0.0,
        1.0, -1.0,  1.0,         1.0,  0.0,  0.0,
        1.0, -1.0,  1.0,         1.0,  0.0,  0.0,
        1.0,  1.0,  1.0,         1.0,  0.0,  0.0,
        1.0,  1.0, -1.0,         1.0,  0.0,  0.0,
        
        1.0,  1.0, -1.0,         0.0,  1.0,  0.0,
       -1.0,  1.0, -1.0,         0.0,  1.0,  0.0,
        1.0,  1.0,  1.0,         0.0,  1.0,  0.0,
        1.0,  1.0,  1.0,         0.0,  1.0,  0.0,
       -1.0,  1.0, -1.0,         0.0,  1.0,  0.0,
       -1.0,  1.0,  1.0,         0.0,  1.0,  0.0,
        
       -1.0,  1.0, -1.0,        -1.0,  0.0,  0.0,
       -1.0, -1.0, -1.0,        -1.0,  0.0,  0.0,
       -1.0,  1.0,  1.0,        -1.0,  0.0,  0.0,
       -1.0,  1.0,  1.0,        -1.0,  0.0,  0.0,
       -1.0, -1.0, -1.0,        -1.0,  0.0,  0.0,
       -1.0, -1.0,  1.0,        -1.0,  0.0,  0.0,
        
       -1.0, -1.0, -1.0,         0.0, -1.0,  0.0,
        1.0, -1.0, -1.0,         0.0, -1.0,  0.0,
       -1.0, -1.0,  1.0,         0.0, -1.0,  0.0,
       -1.0, -1.0,  1.0,         0.0, -1.0,  0.0,
        1.0, -1.0, -1.0,         0.0, -1.0,  0.0,
        1.0, -1.0,  1.0,         0.0, -1.0,  0.0,
        
        1.0,  1.0,  1.0,         0.0,  0.0,  1.0,
       -1.0,  1.0,  1.0,         0.0,  0.0,  1.0,
        1.0, -1.0,  1.0,         0.0,  0.0,  1.0,
        1.0, -1.0,  1.0,         0.0,  0.0,  1.0,
       -1.0,  1.0,  1.0,         0.0,  0.0,  1.0,
       -1.0, -1.0,  1.0,         0.0,  0.0,  1.0,
        
        1.0, -1.0, -1.0,         0.0,  0.0, -1.0,
       -1.0, -1.0, -1.0,         0.0,  0.0, -1.0,
        1.0,  1.0, -1.0,         0.0,  0.0, -1.0,
        1.0,  1.0, -1.0,         0.0,  0.0, -1.0,
       -1.0, -1.0, -1.0,         0.0,  0.0, -1.0,
       -1.0,  1.0, -1.0,         0.0,  0.0, -1.0
    };*/
    
    /*glEnable(GL_DEPTH_TEST);
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(gCubeVertexData), gCubeVertexData, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));*/
    
    glEnable(GL_DEPTH_TEST);
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, (sizeof(vec3) * _len), _vecGrid, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 0, BUFFER_OFFSET(0));
}

EAGLContext *CreateBestEAGLContext()
{
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    
    if (!context)
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    return context;
}

- (void)drawFrame
{
    [_glView setNeedsDisplay];
}

- (void)glkView:(GLKView *)view
     drawInRect:(CGRect)rect
{
    CGFloat aspect = fabs(UIScreen.mainScreen.bounds.size.width / UIScreen.mainScreen.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(50.0), aspect, 0.1, 100.0);
    _effect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 modelMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, -7.0);
    modelMatrix = GLKMatrix4Rotate(modelMatrix, _rotation, 1.0, 1.0, 0.7);
    _effect.transform.modelviewMatrix = modelMatrix;
    _rotation += 0.02;
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [_effect prepareToDraw];
    
    glDrawArrays(GL_POINTS, 0, (GLsizei)_len);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches
           withEvent:(UIEvent *)event
{
    if ([self.view.subviews containsObject:_glView])
    {
        [_displayLink invalidate];
        glDeleteBuffers(1, &_vertexBuffer);
        free(_vecGrid);
        
        if (EAGLContext.currentContext == _context)
            EAGLContext.currentContext = nil;
        
        _context = nil;
        
        [_glView removeFromSuperview];
        _glView = nil;
        _effect = nil;
    }
    
    else if ([self.view.subviews containsObject:_hotspotView])
        [_hotspotView removeFromSuperview];
    
    self.tabBarController.tabBar.hidden = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UserDefaults.defaults.appleGray;
    
    UIImage *autoUpload = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"autoUpload"
                                                                                         ofType:@"png"]];
    
    UIImage *loadData = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"loadData"
                                                                                       ofType:@"png"]];
    
    UIImage *upload = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"upload"
                                                                                     ofType:@"png"]];
    
    UIImage *update = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"update"
                                                                                     ofType:@"png"]];
    
    UIImage *calibrate = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"calibrate"
                                                                                        ofType:@"png"]];
    
    _images = [NSArray arrayWithObjects:autoUpload, upload, loadData, update, calibrate, nil];
    
    _tableView.layer.cornerRadius = 10.0;
    _tableView.rowHeight = 72.0;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.bounces = NO;
    _tableView.delaysContentTouches = NO;
    
    _versionLabel.text = [NSString stringWithFormat:@"NVMobile Version %@", UIApplication.appVersionBuild];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //removed: @"Access Contacts", @"Test Calendar Interface", @"Draw hotspottest.bin"
    
    _contents = @[@"Auto Update", @"Synchronize", @"Load Data", @"Update Data",
                  @"Calibrate Device", @"Track User Location"];
    
    [_tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return _contents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"
                                                            forIndexPath:indexPath];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:@"Cell"];
    }
    
    cell.textLabel.font = [UIFont boldSystemFontOfSize:32.0];
    cell.textLabel.textColor = UIColor.blackColor;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.text = _contents[indexPath.row];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    if (indexPath.row < _images.count)
        cell.imageView.image = _images[indexPath.row];
    
    else
        cell.imageView.image = nil;
    
    cell.textLabel.highlightedTextColor = UserDefaults.defaults.appleBlue;
    cell.indentationWidth = 10.0;
    
    for (UIView *views in cell.contentView.subviews)
    {
        if (views.tag == 777 || views.tag == 888)
            [views removeFromSuperview];
    }
    
    BOOL containsSwitch = NO;
    
    if ([cell.textLabel.text isEqualToString:@"Auto Update"] ||
        [cell.textLabel.text isEqualToString:@"Track User Location"])
    {
        for (UISwitch *switches in cell.contentView.subviews)
        {
            if ([switches isKindOfClass:UISwitch.class])
                containsSwitch = YES;
        }
        
        if (!containsSwitch)
        {
            UISwitch *cellSwitch = [[UISwitch alloc] init];
            cellSwitch.tintColor = UIColor.redColor;
            cellSwitch.onTintColor = UIColor.greenColor;
            
            if ([cell.textLabel.text isEqualToString:@"Auto Update"])
            {
                cellSwitch.tag = 777;
                cellSwitch.on = [UserDefaults.defaults boolForKey:@"AutoUpdate"];
            }
            
            else
            {
                cellSwitch.tag = 888;
                cellSwitch.on = [UserDefaults.defaults boolForKey:@"TrackLocation"];
            }
            
            cellSwitch.center = CGPointMake((cell.frame.size.width - 100.0),
                                            (cell.frame.size.height / 2.0));
            
            [cellSwitch addTarget:self
                           action:@selector(cellSwitchValueChanged:)
                 forControlEvents:UIControlEventValueChanged];
            
            [cell.contentView addSubview:cellSwitch];
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    else
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
    
    if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
         isEqualToString:@"Synchronize"])
    {
        NVSynchronizeVC *syncVC = NVSynchronizeVC.new;
        syncVC.delegate = self;
        
        [self presentViewController:syncVC
                           animated:YES
                         completion:nil];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Load Data"])
    {
        [self loadData];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Update Data"])
    {
        if (ConfigurationControl.sharedInstance.currentApp == HCConfigCrimes)
        {
            _cd = [CrimeData new];
            [_cd update:self.view];
        }
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Calibrate Device"])
    {
        [self calibrateDevice];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Access Contacts"])
    {
        _nvcp = [NVContactPicker presentContactPickerInDelegate:self];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Draw hotspottest.bin"])
    {
        [self setupHotspotTest];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Test Calendar Interface"])
    {
        [self testCalendar];
    }
}

- (void)testCalendar
{
    NVCalendarVC *calendarVC = [[NVCalendarVC alloc] init];
    
    [self presentViewController:calendarVC
                       animated:YES
                     completion:nil];
}

- (void)dismissReaderViewController:(ReaderViewController *)viewController
{
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    UIWindow *backgroundWindow = UIApplication.sharedApplication.keyWindow;
    
    if ([backgroundWindow.subviews containsObject:_mpController.view])
    {
        [UIView animateWithDuration:duration animations:^{
            _mpController.view.frame = CGRectMake(0.0, 0.0, backgroundWindow.frame.size.height,
                                                  backgroundWindow.frame.size.width);
        }];
    }
}

- (void)FTPPushDidComplete:(FTPDataType)dataType
                withStatus:(FTPStatus)status
           andStatusString:(NSString *)statusString
                  filePath:(NSString *)pathint
{
    [_push.popover hide];
    NSLog(@"Upload complete!");
}

- (void)contactPicker:(NVContactPicker *)contactPicker
       didReturnEmail:(NSString *)email
       forContactName:(NSString *)contactName
{
    NSLog(@"Name:%@", contactName);
    NSLog(@"Email:%@", email);
    _nvcp = nil;
}

- (void)loadData
{
    NVTextAlert *textAlert = [NVTextAlert showTextAlertinView:self.view
                                                     delegate:self
                                                        title:@"Password Required for Access to Load Data"];
    
    textAlert.keyboardType = UIKeyboardTypeNumberPad;
    textAlert.minimumCharacters = 0;
}

- (void)calibrateDevice
{
    NVCalibrationController *calibrationController = [[NVCalibrationController alloc] init];
    
    [self presentViewController:calibrationController
                       animated:YES
                     completion:nil];
}

- (void)textAlert:(NVTextAlert *)textAlert
    didReturnText:(NSString *)text
{
    [textAlert hideTextAlert:YES];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.timeStyle = NSDateFormatterNoStyle;
    dateFormatter.dateStyle = NSDateFormatterShortStyle;
    [dateFormatter setDateFormat:@"MMdd"];
    
    NSString *dateString = [dateFormatter stringFromDate:NSDate.date];
    dateString = reverseString(dateString);
    
    if ([dateString isEqualToString:text])
    {
        [self performSegueWithIdentifier:@"ShowSettings"
                                  sender:self];
    }
    
    else
    {
        NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                          delegate:self
                                                             title:@"Password Not Correct"
                                                   buttonTextArray:@[@"OK", @"Try Again"]
                                                  destructiveIndex:0];
#pragma unused(alert)
    }
}

- (void)alertView:(NVAlertView *)alertView
didTapButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        NVTextAlert *textAlert = [NVTextAlert showTextAlertinView:self.view
                                                         delegate:self
                                                            title:@"Password Required for Access to Load Data"];
        
        textAlert.keyboardType = UIKeyboardTypeNumberPad;
        textAlert.minimumCharacters = 0;
    }
    
    [alertView hideLargeAlertView:YES];
}

- (void)cellSwitchValueChanged:(UISwitch *)aSwitch
{
    switch (aSwitch.tag)
    {
        case 777://Auto upload
            [UserDefaults.defaults saveBool:aSwitch.on
                                     forKey:@"AutoUpdate"];
            break;
            
        case 888://Track location
        {
            if (aSwitch.on)
                [AppDelegate.sharedAppDelegate scheduleLocationTracking];
            
            else
                [AppDelegate.sharedAppDelegate stopLocationTracking];
            
            [UserDefaults.defaults saveBool:aSwitch.on
                                     forKey:@"TrackLocation"];
        }
            break;
            
        default:
            break;
    }
}

- (void)synchronizeControllerDidReturn:(NVSynchronizeVC *)controller
{
    [controller dismissViewControllerAnimated:YES
                                   completion:nil];
}

@end