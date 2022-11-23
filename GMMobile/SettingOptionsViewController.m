//  SettingOptionsViewController.m
//  GMMobile

#import "SettingOptionsViewController.h"
#import "ConfigurationControl.h"
#import "CCodeLibrary/NVCalibrationController.h"
#import "CCodeLibrary/GSSiPopoverView.h"
#import <CommonCrypto/CommonDigest.h>
#import "CCodeLibrary/UserDefaults.h"
#import "AppDelegate.h"
#import "CCodeLibrary/NVCalendarVC.h"
#import "CCodeLibrary/NVSynchronizeVC.h"
#import "CCodeLibrary/FTPDirectoryList.h"
@import MediaPlayer;
@import GLKit;
#import "CCodeLibrary/NVKeyboard.h"
#import "CCodeLibrary/NVTextViewAlert.h"
#import "CCodeLibrary/NVTabBarEdit.h"
#import "CreateBatchCrimeMaps.h"
#import "CCodeLibrary/ChartsBitmap.h"
#import "CCodeLibrary/HotSpotVideoVC.h"
#import "CCodeLibrary/CRAPI.h"
#import "CCodeLibrary/RiteHome.h"
#import "CCodeLibrary/HeightCalculator.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@interface SettingOptionsViewController () <GLKViewDelegate, NVSynchronizeDelegate, FTPDirectoryListDelegate, FTPDataPullDelegate, NVCalibrationControllerDelegate, UITableViewDataSource, UITableViewDelegate, NVTextAlertDelegate, NVAlertViewDelegate, FTPDataPushDelegate, NVTextViewAlertDelegate, GSSiPopoverViewDelegate, RHSearchDelegate, GeoMasterServerDelegate, HeightCalculatorDelegate>

@property (nonatomic, copy) NSArray *contents, *images, *elements;
@property (nonatomic) NVContactPicker *nvcp;
@property (nonatomic) FTPDataPush *push;
@property (nonatomic, copy) NSArray *products;
@property (nonatomic, copy) NSString *iapFilePath;
@property (nonatomic) GLKView *glView;
@property (nonatomic) CADisplayLink *displayLink;
@property (nonatomic) GLKBaseEffect *effect;
@property (nonatomic) EAGLContext *context;
@property (nonatomic) GLuint vertexArray, vertexBuffer, indexBuffer;
@property (nonatomic) CGFloat rotation;
@property (nonatomic) UIImageView *hotspotView;
@property (nonatomic) vec3 *vecGrid;
@property (nonatomic) int len, totalPages, numElements, currentElement, numZips, numListings;
@property (nonatomic) CrimeData *cd;
@property (nonatomic) NVTextAlert *textAlert;
@property (nonatomic) NVKeyboard *keyboard;
@property (nonatomic) GSSiPopoverView *popoverView;
@property (nonatomic, copy) NSArray<NSString *> *zips;
@property (nonatomic) GeoMasterServer *GMServer;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

@end

@implementation SettingOptionsViewController

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
    
    UIImage *version = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"versionHistory"
                                                                                      ofType:@"png"]];
    
    UIImage *glossary = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"glossary"
                                                                                       ofType:@"png"]];
    
    /*UIImage *trackLocation = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"trackLocation"
     ofType:@"png"]];*/
    
    _images = [NSArray arrayWithObjects:autoUpload, upload, loadData, update, calibrate, version, glossary, nil];
    CGFloat margin = 0.0;
    
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.bounces = NO;
    _tableView.delaysContentTouches = NO;
    _tableView.layer.cornerRadius = 10.0;
    _totalPages = _numElements = _currentElement = 0;
    
    _versionLabel.text = [NSString stringWithFormat:@"NVMobile Version %@", UIApplication.appVersionBuild];
    _versionLabel.adjustsFontSizeToFitWidth = YES;
    CGFloat statusBarHeight = [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation];
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        _tableView.rowHeight = 38.0;
        margin = 8.0;
    }
    
    else
    {
        _tableView.rowHeight = 64.0;
        margin = 20.0;
    }
    
    [_tableView constrainToView:self.view
                        leading:margin
                       trailing:-margin top:statusBarHeight
                         bottom:-_versionLabel.frame.size.height];
    
    _popoverView = [[GSSiPopoverView alloc] initWithView:self.view];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    /*removed: @"Access Contacts", @"Draw hotspottest.bin", @"Compute PDF Pages, @"Test Keyboard",
     @"Test Calendar Interface", @"Watch TestDrive Training Video, @"Track Location",
     @"Set Default Email Recipients, @"Compress Crime Data"];//,@"Upload Crime Data"*/
    
    _contents = @[@"Auto Update", @"Synchronize", @"Load Data", @"Update Data", @"Calibrate Device",
                  @"See Version History", @"See Glossary of Terms", @"Create Background Crime Maps",
                  @"Create Charts Bitmap File", @"Display Current HotSpot Video", @"Search Realtor Listings",
                  @"Test Height Calculator",@"Toggle Evaluator"];
    
    [_tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

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
        
        [_hotspotView constrainTopToAnchor:self.view.topAnchor];
        [_hotspotView constrainBottomToAnchor:self.view.bottomAnchor constant:self.tabBarController.tabBar.frame.size.height];
        [_hotspotView constrainLeadingToAnchor:self.view.leadingAnchor];
        [_hotspotView constrainTrailingToAnchor:self.view.trailingAnchor];
        
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
    
    [_glView constrainTopToAnchor:self.view.topAnchor];
    [_glView constrainBottomToAnchor:self.view.bottomAnchor constant:self.tabBarController.tabBar.frame.size.height];
    [_glView constrainLeadingToAnchor:self.view.leadingAnchor];
    [_glView constrainTrailingToAnchor:self.view.trailingAnchor];
    
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
    
    CGFloat margin = 0.0;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        cell.textLabel.font = [UIFont boldSystemFontOfSize:18.0];
        margin = -6.0;
    }
    
    else
    {
        cell.textLabel.font = [UIFont boldSystemFontOfSize:32.0];
        margin = -20.0;
    }
    
    cell.textLabel.textColor = UIColor.blackColor;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.text = _contents[indexPath.row];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    if (indexPath.row < _images.count)
        cell.imageView.image = _images[indexPath.row];
    
    else
        cell.imageView.image = nil;
    
    cell.textLabel.highlightedTextColor = UserDefaults.defaults.appleBlue;
    
    for (UIView *views in cell.contentView.subviews)
    {
        if (views.tag == 777 || views.tag == 888)
            [views removeFromSuperview];
    }
    
    BOOL containsSwitch = NO;
    
    if ([cell.textLabel.text isEqualToString:@"Auto Update"] ||
        [cell.textLabel.text isEqualToString:@"Track Location"])
    {
        for (UISwitch *switches in cell.contentView.subviews)
        {
            if ([switches isKindOfClass:UISwitch.class])
                containsSwitch = YES;
        }
        
        if (!containsSwitch)
        {
            UISwitch *cellSwitch = UISwitch.new;
            cellSwitch.translatesAutoresizingMaskIntoConstraints = NO;
            cellSwitch.tintColor = UIColor.redColor;
            cellSwitch.onTintColor = UIColor.greenColor;
            
            if ([cell.textLabel.text isEqualToString:@"Auto Update"])
            {
                cellSwitch.tag = 777;
                cellSwitch.on = ![UserDefaults.defaults boolForKey:@"NoAutoUpdate"];
            }
            
            else
            {
                cellSwitch.tag = 888;
                cellSwitch.on = [UserDefaults.defaults boolForKey:@"TrackLocation"];
            }
            
            [cellSwitch addTarget:self
                           action:@selector(cellSwitchValueChanged:)
                 forControlEvents:UIControlEventValueChanged];
            
            [cell.contentView addSubview:cellSwitch];
            [cellSwitch constrainTrailingToAnchor:cell.contentView.trailingAnchor constant:margin];
            [cellSwitch constrainCenterYToAnchor:cell.contentView.centerYAnchor];
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
            [_cd update:self.view
                   auto:NO
             delegate:nil];
        }
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Calibrate Device"])
    {
        [self calibrateDevice];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"See Version History"])
    {
        [self seeVersionHistory];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"See Glossary of Terms"])
    {
        [self seeGlossary];
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
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Upload Crime Data"])
    {
        [self uploadCrimeData];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Create Background Crime Maps"])
    {
        [self batchCrimeMaps];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Create Charts Bitmap File"])
    {
        ChartsBitmap *chart = ChartsBitmap.new;
        ChartsBitmapDataSet *dataSet = ChartsBitmapDataSet.new;
        dataSet.color = UIColor.blueColor;
        
        for (int i = 1; i < 20; i++)
        {
            DPoint *point = DPoint.new;
            point.x = ((150 * i) - 75);
            point.y = ((arc4random() % 500) + 1450);
            [dataSet.data addObject:point];
        }
        
        [chart.dataSets addObject:dataSet];
        
        dataSet = ChartsBitmapDataSet.new;
        dataSet.color = UIColor.redColor;
        
        for (int i = 1; i < 20; i++)
        {
            DPoint *point = DPoint.new;
            point.x = ((150 * i) - 75);
            point.y = ((arc4random() % 250) + 500);
            [dataSet.data addObject:point];
        }
        
        [chart.dataSets addObject:dataSet];
        
        dataSet = ChartsBitmapDataSet.new;
        dataSet.color = UserDefaults.defaults.darkGreen;
        
        for (int i = 1; i < 20; i++)
        {
            DPoint *point = DPoint.new;
            point.x = ((150 * i) - 75);
            point.y = ((arc4random() % 1000) + 850);
            [dataSet.data addObject:point];
        }
        
        [chart.dataSets addObject:dataSet];
        
        dataSet = ChartsBitmapDataSet.new;
        dataSet.color = UIColor.orangeColor;
        
        for (int i = 1; i < 20; i++)
        {
            DPoint *point = DPoint.new;
            point.x = ((150 * i) - 75);
            point.y = (arc4random() % 500);
            [dataSet.data addObject:point];
        }
        
        [chart.dataSets addObject:dataSet];
        
        dataSet = ChartsBitmapDataSet.new;
        dataSet.color = UIColor.purpleColor;
        
        for (int i = 1; i < 20; i++)
        {
            DPoint *point = DPoint.new;
            point.x = ((150 * i) - 75);
            point.y = ((arc4random() % 675) + 675);
            [dataSet.data addObject:point];
        }
        
        [chart.dataSets addObject:dataSet];
        
        chart.title = @"An Interesting Line Chart from GSSi";
        [chart createChartBitmap];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Display Current HotSpot Video"])
    {
        HotSpotVideo *hsv = HotSpotVideo.new;
        hsv.imageFiles = [UserDefaults.defaults arrayForKey:@"HotSpotVideoImageFiles"].mutableCopy;
        hsv.timeRanges = [UserDefaults.defaults arrayForKey:@"HotSpotVideoTimeRanges"];
        hsv.type = [UserDefaults.defaults integerForKey:@"HotSpotVideoType"];
        
        if ([UserDefaults.defaults integerForKey:@"HotSpotVideoLength"])
            hsv.length = (int)[UserDefaults.defaults integerForKey:@"HotSpotVideoLength"];
        
        hsv.backgroundImageFile =  [UserDefaults.defaults stringForKey:@"HotSpotBackgroundImageFile"];
        hsv.numImages = (int)hsv.imageFiles.count;
        CRAPI.sharedInstance.hsv = hsv;
        HotSpotVideoVC *hsvVC = HotSpotVideoVC.new;
        
        hsvVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
        [self presentViewController:hsvVC
                           animated:YES
                         completion:nil];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Compress Crime Data"])
    {
        [self compressCrimeData];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Compute PDF Pages"])
    {
        [self computePDFPages];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Test Keyboard"])
    {
        if (![self.view.subviews containsObject:_keyboard])
            _keyboard = [NVKeyboard showKeyboardInView:self.view delegate:self];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Watch TestDrive Training Video"])
    {
        NVWebView *webView = [NVWebView showWebViewInView:self.view urlString:@"gssiserver3.com/testdrivevideo"];
#pragma unused(webView)
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Set Default Email Recipients"])
    {
        NSArray *recipientsArray = [UserDefaults.defaults arrayForKey:@"DefaultRecipients"];
        NSString *recipientsString = @"";
        
        if (recipientsArray.count)
            recipientsString = [recipientsArray componentsJoinedByString:@","];
        
        NVTextViewAlert *nvtva = [NVTextViewAlert showTextViewAlertinView:self.view
                                                                 delegate:self
                                                                    title:@"Enter Email Addresses Separated by Commas"
                                                                     text:recipientsString];
#pragma unused(nvtva)
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Search Realtor Listings"])
    {
        int updateTime = (int)[UserDefaults.defaults integerForKey:@"RHUpdateTime"];
        CRAPI.sharedInstance.rhUpdateTime = MAX(updateTime, 1);
        [self performListingsSearch];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Test Height Calculator"])
    {
        [self testHeightCalculator];
    }
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Toggle Evaluator"])
    {
        CRAPI.sharedInstance.evaluateEdges = !CRAPI.sharedInstance.evaluateEdges;
    }
}

- (void)testHeightCalculator
{
    [HeightCalculator presentHeightCalculatorInController:self delegate:self];
}

- (void)heightCalculator:(HeightCalculator *)heightCalculator
          returnedHeight:(float)height
{
    [heightCalculator dismissViewControllerAnimated:YES completion:nil];
}

- (void)performListingsSearch
{
    if (hasNetwork())
    {
        NSString *filePath = [NSBundle.mainBundle pathForResource:@"zipcodes" ofType:@"txt"];
        
        NSString *text = [NSString stringWithContentsOfFile:filePath
                                                   encoding:NSUTF8StringEncoding
                                                      error:nil];
        
        _zips = [text componentsSeparatedByString:@"\n"];
        _numZips = 0;

        [_popoverView showAfter:0.0 withTitle:@""];
        CRAPI.sharedInstance.rhCurrentZip = _zips[_numZips++].intValue;
        
        CRAPI.sharedInstance.rhSearchFilePath =
        [NSString stringWithFormat:@"%@/RHSearchSqlCommands_%d.txt",
         UserDefaults.defaults.localFilePath, CRAPI.sharedInstance.rhUpdateTime];
        
        [self searchPropsForZip];
    }
    
    else
        showAlert(@"RHSearch ERROR: Network required.");
}

- (void)searchPropsForZip
{
    CRAPI.sharedInstance.rhSearchSqlCommands = NSMutableString.string;
    RHSearch *search = [RHSearch searchWithDelegate:self];
    
    if (_numZips > 1)
        [NSThread sleepForTimeInterval:RH_QUERY_INTERVAL];
    
    [search getItemsForZip];
    
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
        _popoverView.title = [NSString stringWithFormat:@"RHSearch for Zip: %i",
                              CRAPI.sharedInstance.rhCurrentZip];
        
        [_popoverView updateProgress:(_numZips / (float)_zips.count)];
    }];
}

- (void)searchDidReturnItems:(NSArray<RHSearchItem *> *)items
                   morePages:(BOOL)morePages
{
    _numListings += items.count;
    RHSearchDatabase *rhsd = RHSearchDatabase.new;
    [rhsd updateDatabaseForSearchItems:items];
    
    if (!morePages)
    {
        if (_numZips < _zips.count)
        {
            [self updateSqlCmdFile];
            CRAPI.sharedInstance.rhCurrentZip = _zips[_numZips++].intValue;
            [self searchPropsForZip];
        }
        
        else
        {
            [rhsd deleteOldItems];
            
            [NSOperationQueue.mainQueue addOperationWithBlock:^ {
                NSString *filePath = CRAPI.sharedInstance.rhSearchFilePath;
                
                _push = FTPDataPush.push;
                _push.delegate = self;
                [_popoverView updateProgress:0.0];
                _push.popover = _popoverView;
                _popoverView.title = @"Upload RHSearchSqlCommands File";
                
                [_push sendFile:filePath.lastPathComponent
                  fromDirectory:filePath.stringByDeletingLastPathComponent
                         toFile:filePath.lastPathComponent
                    toDirectory:@"RiteHome"
                 deleteWhenDone:YES
                 appendFileName:NO];
            }];
            
            [NSThread sleepForTimeInterval:RH_QUERY_INTERVAL];
            CRAPI.sharedInstance.rhUpdateTime++;
            
            [UserDefaults.defaults saveInteger:CRAPI.sharedInstance.rhUpdateTime
                                        forKey:@"RHUpdateTime"];
            
            [self performListingsSearch];
        }
    }
}

- (void)updateSqlCmdFile
{
    NSMutableString *cmds = CRAPI.sharedInstance.rhSearchSqlCommands;
    
    if (cmds.length)
    {
        NSString *filePath = CRAPI.sharedInstance.rhSearchFilePath;
        NSError *error = nil;
        
        if (![NSFileManager.defaultManager fileExistsAtPath:filePath])
        {
            [cmds writeToFile:filePath
                   atomically:YES
                     encoding:NSUTF8StringEncoding
                        error:&error];
            
            if (error) {showAlert(@"ERROR: RHSearchSqlCommands File could not be written.");}
        }
        
        else
        {
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
            [fileHandle seekToEndOfFile];
            [fileHandle writeData:[cmds dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandle closeFile];
        }
    }
}

- (void)searchDidReceiveError:(NSString *)error
{
    [NSOperationQueue.mainQueue addOperationWithBlock:^ {
        _popoverView.title = @"RHSearch ERROR...waiting";
    }];
    
    [NSThread sleepForTimeInterval:RH_ERROR_INTERVAL];
    [self searchPropsForZip];
}

- (void)uploadCrimeData
{
    _push = FTPDataPush.push;
    _push.delegate = self;
    _push.popover = _popoverView;
    
    _cd = [CrimeData new];
    
    NSString *toDir = @"NVCRIS/UploadedDatabases";
    NSString * dbpath = _cd.path;
    NSString *file = dbpath.lastPathComponent;
    NSString *fromDir = dbpath.stringByDeletingLastPathComponent;
    [_popoverView showAfter:0.1 withTitle:@"Upload Crime Database"];
    
    [_push sendFile:file
      fromDirectory:fromDir
             toFile:file
        toDirectory:toDir
     deleteWhenDone:NO
     appendFileName:NO];
}

- (void)compressCrimeData
{
    _cd = [CrimeData new];
    [_cd open];
    long long oldSize = _cd.fileSize;
    NSString *title = [NSString stringWithFormat:@"Compressing Crime Database\nInitial Size:%lli",oldSize];
    [_cd close:YES];
    [_popoverView showAfter:0.1 withTitle:title];
    long long newSize = [_cd compress];
    int pct = 100.0 * (double)newSize / (double)oldSize;
    _popoverView.title = [NSString stringWithFormat:@"Compress Crime Database Complete\nNew Size:%lli\n%i Percent",newSize, pct];
 }

- (void) batchCrimeMaps
{
    CreateBatchCrimeMaps * bcm = CreateBatchCrimeMaps.new;
    
    [bcm createImages:@"test"
              popover:_popoverView];
}
- (void)GSSiPopoverViewdidCancel:(GSSiPopoverView *)popoverView
{
    [popoverView hide];
}


- (void)textViewAlert:(NVTextViewAlert *)textViewAlert
        didReturnText:(NSString *)text
{
    if (text && text.length)
    {
        text = [text stringByReplacingOccurrencesOfString:@" " withString:@""];
        text = [text stringByTrimmingCharactersInSet:NSCharacterSet.newlineCharacterSet];
        text = [text stringByTrimmingCharactersInSet:NSCharacterSet.symbolCharacterSet];
        NSArray *textArray = nil;
        
        if ([text containsString:@","])
            textArray = [text componentsSeparatedByString:@","];
        
        else
            textArray = [NSArray arrayWithObject:text];
        
        [UserDefaults.defaults saveArray:textArray forKey:@"DefaultRecipients"];
    }
    
     [textViewAlert hideTextViewAlert:YES];
}

- (void)textViewAlertDidCancel:(NVTextViewAlert *)textViewAlert
{
    [textViewAlert hideTextViewAlert:YES];
}

- (void)testCalendar
{
    NVCalendarVC *calendarVC = NVCalendarVC.new;
    [self presentViewController:calendarVC animated:YES completion:nil];
}

- (void)computePDFPages
{
    FTPDirectoryList *list = [FTPDirectoryList getListingFromFTPDomain:CRAPI.sharedInstance.getNVCRISServer
                                                             directory:@"mgv/linked"
                                                              username:@"GSSiProfessionalServer"
                                                              password:@"GSSi"
                                                                  port:@"21"
                                                              delegate:self];
#pragma unused(list)
}

- (void)FTPDirectoryListDidCompleteWithStatus:(FTPStatus)status
                                 statusString:(NSString *)statusString
                                directoryList:(NSData *)directoryList
{
    NSString *results = [[NSString alloc] initWithData:directoryList
                                              encoding:NSUTF8StringEncoding];
    
    if (results && ![results isEqualToString:@""])
    {
        _elements = [results componentsSeparatedByString:@"\n"];
        _numElements = ((int)_elements.count - 1);
        [self pullNextFile];
    }
}

- (void)pullNextFile
{
    NSString *element = _elements[_currentElement];
    NSString *fileName = removeEndingReturn(textAfterLastSpace(element));
    
    FTPDataPull *pull = FTPDataPull.new;
    pull.delegate = self;
    
    [pull getFile:fileName
     fromDirectory:@"mgv/linked"
            toFile:fileName
       toDirectory:UserDefaults.defaults.localFilePath
     refreshOption:FTPDataPullRefreshOptionCheckFileSize];
}

- (void)FTPdidComplete:(FTPDataType)dataType
            withStatus:(FTPStatus)status
       andStatusString:(NSString *)statusString
              filePath:(NSString *)path
{
    if (status == FTPStatusConnectionFailed)
        _currentElement--;
    
    NSURL *url = [NSURL fileURLWithPath:path];
    
    if ([path.pathExtension isEqualToString:@"pdf"] || [path.pathExtension isEqualToString:@"PDF"])
    {
        CFURLRef urlRef = (__bridge CFURLRef)url;
        CGPDFDocumentRef pdfRef = CGPDFDocumentCreateWithURL(urlRef);
        _totalPages += (int)CGPDFDocumentGetNumberOfPages(pdfRef);
        _currentElement++;
        CGPDFDocumentRelease(pdfRef);
    }
    
    NSLog(@"File %i of %i, total pages = %i", _currentElement, _numElements, _totalPages);
    
    NSError *error = nil;
    
    [NSFileManager.defaultManager removeItemAtPath:path
                                             error:&error];
    
    if (!error)
    {
        if (_currentElement < _numElements)
            [self pullNextFile];
    }
    
    else
        NSLog(@"File Delete ERROR:%@", path);
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    [_textAlert willRotateWithDuration:duration];
}

- (void)FTPPushDidComplete:(FTPDataType)dataType
                withStatus:(FTPStatus)status
           andStatusString:(NSString *)statusString
                  filePath:(NSString *)pathint
{
    [_push.popover hide];
    
    if (status == FTPStatusOK)
    {
        _GMServer = GeoMasterServer.open;
        _GMServer.delegate = self;
        [_GMServer initCommunication:5.0];
    }
}

- (void)GMServerDidOpen:(GeoMasterServer *)server
{
    NSString *msg = [NSString stringWithFormat:@"$M(LoadRHSearchFile,%d)",
                     CRAPI.sharedInstance.rhUpdateTime];
    
    [_GMServer sendMessage:msg];
    NSLog(@"GMServer Query: %@", msg);
}

- (void)GMServer:(GeoMasterServer *)server
 didReceiveError:(NSString *)error
      withStatus:(long)status
{
    [self closeGMServer];
}

- (void)GMServer:(GeoMasterServer *)server
didReceiveMessage:(NSString *)message
      withStatus:(long)status
{
    [self closeGMServer];
}

- (void)closeGMServer
{
    if (_GMServer)
    {
        [_popoverView hide];
        [_GMServer closeServer];
        _GMServer.delegate = nil;
    }
    
    _GMServer = nil;
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
    _textAlert = [NVTextAlert showTextAlertinView:self.view
                                         delegate:self
                                            title:@"Password Required for Access to Load Data"];
    
    _textAlert.keyboardType = UIKeyboardTypeNumberPad;
    _textAlert.minimumCharacters = 0;
}

- (void)calibrateDevice
{
    NVCalibrationController *calibrationController = [[NVCalibrationController alloc] init];
    calibrationController.delegate = self;
    
    [self presentViewController:calibrationController
                       animated:YES
                     completion:nil];
}

- (void)seeVersionHistory
{
    NSString *filePath = [NSBundle.mainBundle pathForResource:@"NVMobile_VersionHistory"
                                                       ofType:@"pdf"];
    
    NVWebView *nvwv = [NVWebView showWebViewInView:self.view
                                    showFileAtPath:filePath
                                          delegate:nil];
#pragma unused(nvwv)
}

- (void)seeGlossary
{
    NVWebView *webView = [NVWebView showWebViewInView:self.view urlString:@"gssiserver3.com/glossary"];
#pragma unused(webView)
}

- (void)textAlert:(NVTextAlert *)textAlert
    didReturnText:(NSString *)text
{
    [textAlert hideTextAlert:YES];
    
    NSDateFormatter *dateFormatter = NSDateFormatter.new;
    dateFormatter.timeStyle = NSDateFormatterNoStyle;
    dateFormatter.dateStyle = NSDateFormatterShortStyle;
    [dateFormatter setDateFormat:@"MMedd"];
    NSString *dateString = [dateFormatter stringFromDate:NSDate.date];
    dateString = reverseString(dateString);
    NSLog(@"Password: %@", dateString);
    
    if ([dateString isEqualToString:text])
        [self performSegueWithIdentifier:@"ShowSettings" sender:self];
    
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
        _textAlert = [NVTextAlert showTextAlertinView:self.view
                                             delegate:self
                                                title:@"Password Required for Access to Load Data"];
        
        _textAlert.keyboardType = UIKeyboardTypeNumberPad;
        _textAlert.minimumCharacters = 0;
    }
    
    [alertView hideLargeAlertView:YES];
}

- (void)cellSwitchValueChanged:(UISwitch *)aSwitch
{
    switch (aSwitch.tag)
    {
        case 777://Auto upload
            [UserDefaults.defaults saveBool:!aSwitch.on forKey:@"NoAutoUpdate"];
            break;
            
        case 888://Track location
        {
            if (aSwitch.on)
                [AppDelegate.sharedAppDelegate scheduleLocationTracking];
            
            else
                [AppDelegate.sharedAppDelegate stopLocationTracking];
            
            [UserDefaults.defaults saveBool:aSwitch.on forKey:@"TrackLocation"];
        }
            break;
            
        default:
            break;
    }
}

- (void)synchronizeControllerDidReturn:(NVSynchronizeVC *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)calibrationControllerNeedsRefresh:(NVCalibrationController *)controller
{
    NVCalibrationController *calibrationController = NVCalibrationController.new;
    calibrationController.delegate = self;
    calibrationController.useHeadingCalibration = controller.useHeadingCalibration;
    calibrationController.headingErrorShown = YES;
    [controller dismissViewControllerAnimated:NO completion:nil];
    [self presentViewController:calibrationController animated:YES completion:nil];
}

- (CGFloat)statusBarHeight:(UIInterfaceOrientation)orientation
{
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight)
            return 0.0;
    }
    
    return 20.0;
}

@end
