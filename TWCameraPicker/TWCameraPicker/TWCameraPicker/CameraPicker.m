//
//  CameraPicker.m
//  TourWay
//
//  Created by luomeng on 15/11/12.
//  Copyright © 2015年 OneThousandandOneNights. All rights reserved.
//

#import "CameraPicker.h"
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "CLLocation+GPSDictionary.h"
#import "NSDictionary+CLLocation.h"
#import <CoreLocation/CoreLocation.h>
#import <AssetsLibrary/AssetsLibrary.h>


#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height



@interface CameraPicker ()
<
UIAlertViewDelegate,
UINavigationControllerDelegate,
UIImagePickerControllerDelegate,
CLLocationManagerDelegate,
UIImagePickerControllerDelegate,
UICollectionViewDataSource,
UICollectionViewDelegate,
UICollectionViewDelegateFlowLayout,
AVCaptureFileOutputRecordingDelegate,
AVCaptureMetadataOutputObjectsDelegate
>
{
    IBOutlet UIView *_cameraOverLayerView;
    __weak IBOutlet UIButton *_flashBtn;
    __weak IBOutlet UIButton *_HDRBtn;
    __weak IBOutlet UIButton *_timeDelayBtn;
    __weak IBOutlet UIButton *_switchSceneBtn;
    __weak IBOutlet UIImageView *_layerImageView;
    
    __weak IBOutlet UIView *_settingView;
    __weak IBOutlet UIView *_actionView;
    UIImagePickerControllerCameraFlashMode _flashMode;
    UIImagePickerControllerQualityType _qualityType;
    __weak IBOutlet UILabel *_alertLabel;
    
    IBOutlet UIView *_albumView;
    __weak IBOutlet UICollectionView *_albumCollectionView;
}
- (IBAction)_photoLibrary:(id)sender;


@property (nonatomic, strong)AVCaptureSession *session;
@property (nonatomic, strong)AVCaptureDeviceInput *deviceInput;
@property (nonatomic, strong)AVCaptureVideoDataOutput *dataOutput;
@property (nonatomic, strong)AVCaptureStillImageOutput   * stillImageOutput;
@property (nonatomic, strong)AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong)AVCaptureDevice *device;
@property (nonatomic, strong)UIImagePickerController *camera;

@property (nonatomic, strong)UIView *cameraShowView;
@property (nonatomic, assign)UIImagePickerControllerCameraDevice currentDevice;
@property (nonatomic, strong)CLLocation *currentLocation;
@property (nonatomic, strong)CLLocationManager  *locationManager;
@property (nonatomic ,strong)NSMutableDictionary *mediaInfo;
@property (nonatomic ,strong)NSMutableArray *photos;


@end

@implementation CameraPicker (private)

- (IBAction)_sceneSwitch:(id)sender {
    
#ifdef CAMERA_TYPE_IMAGE_PICKER
    [self imagePickerSwitchCamera];
#else
    [self AVCaptureSwitchCamera];
#endif
    
}

- (void)imagePickerSwitchCamera{
    
    if (self.camera.cameraDevice == UIImagePickerControllerCameraDeviceRear) {
        self.camera.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    }
    else if (self.camera.cameraDevice == UIImagePickerControllerCameraDeviceFront) {
        self.camera.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    }
}

- (void)AVCaptureSwitchCamera{
    
    NSUInteger cameraCount = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
    if (cameraCount > 1) {
        NSError *error;
        AVCaptureDeviceInput *newVideoInput;
        AVCaptureDevicePosition position = [[self.deviceInput device] position];
        
        if (position == AVCaptureDevicePositionBack)
            newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontCamera] error:&error];
        else if (position == AVCaptureDevicePositionFront)
            newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backCamera] error:&error];
        else
            return;
        
        if (newVideoInput != nil) {
            [self.session beginConfiguration];
            [self.session removeInput:self.deviceInput];
            if ([self.session canAddInput:newVideoInput]) {
                [self.session addInput:newVideoInput];
                self.deviceInput = newVideoInput;
            } else {
                [self.session addInput:self.deviceInput];
            }
            [self.session commitConfiguration];
        } else if (error) {
            NSLog(@"toggle carema failed, error = %@", error);
        }
    }
}
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}
- (AVCaptureDevice *)frontCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}
- (AVCaptureDevice *)backCamera {
    
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

- (IBAction)_flash:(id)sender {
    
#ifdef CAMERA_TYPE_IMAGE_PICKER
    [self _imagePickerSwitchFlash];
#else
    [self _AVCaptureSwitchFlash];
#endif
    
}
- (void)_imagePickerSwitchFlash{
    if (_flashMode == UIImagePickerControllerCameraFlashModeOff) {
        
        _flashMode = UIImagePickerControllerCameraFlashModeOn;
        [_flashBtn setImage:[UIImage imageNamed:@"c02_open.png"] forState:UIControlStateNormal];
        [_flashBtn setImage:[UIImage imageNamed:@"c02_open.png"] forState:UIControlStateHighlighted];
    }
    else if (_flashMode == UIImagePickerControllerCameraFlashModeOn){
        
        _flashMode = UIImagePickerControllerCameraFlashModeAuto;
        [_flashBtn setImage:[UIImage imageNamed:@"c02_auto.png"] forState:UIControlStateNormal];
        [_flashBtn setImage:[UIImage imageNamed:@"c02_auto.png"] forState:UIControlStateHighlighted];
    }
    else if (_flashMode == UIImagePickerControllerCameraFlashModeAuto){
        
        _flashMode = UIImagePickerControllerCameraFlashModeOff;
        [_flashBtn setImage:[UIImage imageNamed:@"c02"] forState:UIControlStateNormal];
        [_flashBtn setImage:[UIImage imageNamed:@"c02"] forState:UIControlStateHighlighted];
        
    }
    self.camera.cameraFlashMode = _flashMode;
    
}
- (void)_AVCaptureSwitchFlash{
    
    if([self.device hasTorch] && [self.device hasFlash]){
        
        [self.session beginConfiguration];
        [self.device lockForConfiguration:nil];
        
        if(self.device.torchMode == AVCaptureTorchModeOff){
            
            [self.device setTorchMode:AVCaptureTorchModeOn];
            [self.device setFlashMode:AVCaptureFlashModeOn];
            [_flashBtn setImage:[UIImage imageNamed:@"c02_open.png"] forState:UIControlStateNormal];
            [_flashBtn setImage:[UIImage imageNamed:@"c02_open.png"] forState:UIControlStateHighlighted];
            
        }
        else if (self.device.torchMode == AVCaptureFlashModeOn)
        {
            [self.device setTorchMode:AVCaptureTorchModeAuto];
            [self.device setFlashMode:AVCaptureFlashModeAuto];
            [_flashBtn setImage:[UIImage imageNamed:@"c02_auto.png"] forState:UIControlStateNormal];
            [_flashBtn setImage:[UIImage imageNamed:@"c02_auto.png"] forState:UIControlStateHighlighted];
            
        }
        else if (self.device.torchMode == AVCaptureFlashModeAuto)
        {
            [self.device setTorchMode:AVCaptureTorchModeOff];
            [self.device setFlashMode:AVCaptureFlashModeOff];
            [_flashBtn setImage:[UIImage imageNamed:@"c02"] forState:UIControlStateNormal];
            [_flashBtn setImage:[UIImage imageNamed:@"c02"] forState:UIControlStateHighlighted];
            
        }
        [self.device unlockForConfiguration];
        [self.session commitConfiguration];
        
        [self.session startRunning];
        [self.view bringSubviewToFront:_cameraOverLayerView];
    }
    
}


- (IBAction)_HDRSwitch:(id)sender {
    
}
- (IBAction)_timeDelaySwitch:(id)sender {
}

- (IBAction)_cancel:(id)sender {
    if ([self.delegate respondsToSelector:@selector(cameraPickerDidCancel:)]) {
        [self.delegate cameraPickerDidCancel:self];
    }
}
- (IBAction)_shutter:(id)sender {
    
#ifdef CAMERA_TYPE_IMAGE_PICKER
    [self _imagePickerShutter];
    
#else
    [self _AVCaptureShutter];
#endif
}
- (void)_imagePickerShutter{
    
    if (self.camera) {
        [self.camera takePicture];
    }
}
- (void)_AVCaptureShutter{
    
    AVCaptureConnection * videoConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (!videoConnection) {
        NSLog(@"take photo failed!");
        return;
    }
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (imageDataSampleBuffer == NULL) {
            return;
        }
        NSData * imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage * image = [UIImage imageWithData:imageData];
        
        ///*
        
        UIDeviceOrientation orien = [[UIDevice currentDevice] orientation];
        CGImageSourceRef source;
        source = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
        
        NSDictionary *metadata = (NSDictionary *) CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, 0, NULL));
        CFRelease(source);
        NSMutableDictionary *metadataAsMutable = [metadata mutableCopy];
        CGImagePropertyOrientation imagePropertyOrientation = kCGImagePropertyOrientationUp;
        
        switch (orien) {
            case UIDeviceOrientationPortrait:
                
                imagePropertyOrientation = kCGImagePropertyOrientationUp;
                break;
                
            case UIDeviceOrientationPortraitUpsideDown:
                
                imagePropertyOrientation = kCGImagePropertyOrientationDown;
                break;
                
            case UIDeviceOrientationLandscapeLeft:
                
                imagePropertyOrientation = kCGImagePropertyOrientationLeft;
                break;
                
            case UIDeviceOrientationLandscapeRight:
                
                imagePropertyOrientation = kCGImagePropertyOrientationRight;
                break;
                
            default:
                break;
        }
        NSDictionary * gpsDict=[self.currentLocation GPSDictionary];
        [metadataAsMutable setValue:gpsDict forKey:(NSString*)kCGImagePropertyGPSDictionary];
        
        [metadataAsMutable setValue:[NSNumber numberWithInteger:imagePropertyOrientation] forKey:(NSString *)kCGImagePropertyOrientation];
        
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        
        [library writeImageToSavedPhotosAlbum:image.CGImage metadata:metadataAsMutable completionBlock:^(NSURL *assetURL, NSError *error) {
            
            
        }];
        
        //*/
        if ([self.delegate respondsToSelector:@selector(cameraPicker:didPickImage:location:createTime:sourceType:)]) {
            [self.delegate cameraPicker:self didPickImage:[self fixOrientation:image] location:self.currentLocation createTime:[self nowString] sourceType:UIImagePickerControllerSourceTypeCamera];
        }
    }];
}

- (void)_removeAlertLabel{
    
    _alertLabel.hidden = YES;
    [self.view bringSubviewToFront:_cameraOverLayerView];
    
}

-(UIImage *)_adjustImage:(UIImage *)sourceImg{
    
    return [self _aspectScaleImage:sourceImg toWidth:640];
}
-(UIImage *)_aspectScaleImage:(UIImage *)img toWidth:(float)width{
    
    float ratio = width / img.size.width;
    float h = img.size.height * ratio;
    CGSize size = CGSizeMake(width, h);
    UIGraphicsBeginImageContext(size);
    [img drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}
-(void)loadLocalPhotos{
    
    
    ALAssetsLibrary *libarary = [[ALAssetsLibrary alloc] init];
    self.photos = [NSMutableArray array];
    
    [libarary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            if ([[group valueForProperty:ALAssetsGroupPropertyType] intValue]) {
                
                [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                    
                    ALAssetRepresentation *representation = [result defaultRepresentation];
                    
                    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [UIImage imageWithCGImage:[result thumbnail]],@"thumbnail",
                                         //                                         [result fullResolutionImage],@"fullResolutionImage",
                                         representation,@"representation", nil];
                    [self.photos addObject:dic];
                }];
            }
            
        }
        //        [self dismissViewControllerAnimated:YES completion:nil];.
        _albumView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        [self.view addSubview:_albumView];
        [_albumCollectionView reloadData];
        
    } failureBlock:^(NSError *error) {
        
    }];
}
- (void)_showNoAcceessToPhotoLibrary{
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"在设置—途遇图记—权限中开启相机权限，以正常使用拍照、图像文字编译、创建图记等功能。" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"去设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        //很多应用需要访问相机或者相册，但有时用户会拒绝访问，所以下次再需要相关权限时，就要提示用户去设置开启权限。 NSURL *url = [NSURL URLWithString:@"prefs:root=com.1001nights.Gallery"];iOS10及之后不能正常使用
        
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];//ios8以上可用
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            
            [[UIApplication sharedApplication] openURL:url];
        }
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alert addAction:cancel];
    [alert addAction:ok];
    
    [self presentViewController:alert animated:YES completion:nil];
    
}
- (NSString *)nowString{
    
    NSDateFormatter * formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *str = [formatter stringFromDate:[NSDate date]];
    return str;
}
- (UIImage *)fixOrientation:(UIImage *)aImage {
    
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}


@end

@implementation CameraPicker


- (void)_imagePickerModel{
    
    if (self.sourceType == UIImagePickerControllerSourceTypeCamera) {
        _currentDevice = UIImagePickerControllerCameraDeviceRear;
        [self _getPictureFromCamera];
        [UIApplication sharedApplication].statusBarHidden = YES;
        
        if (SCREEN_HEIGHT > 480) {
            for (NSLayoutConstraint *contraint in _actionView.constraints) {
                if (contraint.firstAttribute == NSLayoutAttributeHeight) {
                    contraint.constant = SCREEN_HEIGHT - SCREEN_WIDTH / 3.0 * 4.0 - 44;
                }
            }
        }
        else{
            
            _actionView.backgroundColor = [UIColor clearColor];
        }
    }
    else if (self.sourceType == UIImagePickerControllerSourceTypePhotoLibrary){
        
        [_albumCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"UICollectionViewCell"];
        [self loadLocalPhotos];
        
    }
}
- (void)_AVCaptureSessionModel{
    
    
    //获取摄像设备
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //创建输入流
    self.deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    //创建输出流
    //    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    //       // output.rectOfInterest = CGRectMake(0,0,1, 1);
    //    //设置代理 在主线程里刷新
    //    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    
    //初始化链接对象
    self.session = [[AVCaptureSession alloc] init];
    //高质量采集率
    [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    
    if (self.deviceInput) {
        [self.session addInput:self.deviceInput];
        
    }
    //    if (output) {
    //        [self.session addInput:output];
    //
    //    }
    if (self.stillImageOutput) {
        [self.session addOutput:self.stillImageOutput];
        
    }
    
    
    
    //    output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
    
    
    AVCaptureVideoPreviewLayer *layer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    layer.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);//self.view.layer.bounds;
    [self.view.layer insertSublayer:layer atIndex:0];
    [self.view addSubview:_cameraOverLayerView];
    //开始捕获
    //    [self.session startRunning];
}

#pragma mark -
#pragma mark - lifeCycle
- (instancetype)init{
    
    if (self = [super init]) {
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(status == AVAuthorizationStatusAuthorized) {
        
    } else if(status == AVAuthorizationStatusDenied){
        
//        [self _showNoAcceessToPhotoLibrary];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"访问相机失败"
                                                        message:@"未成功获取相机使用权限"
                                                       delegate:self
                                              cancelButtonTitle:@"取消"
                                              otherButtonTitles:@"去设置", nil];
        [alert show];

    } else if(status == AVAuthorizationStatusRestricted){
    } else if(status == AVAuthorizationStatusNotDetermined){
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if(granted){
                
                
            } else {
                return;
            }
        }];
    }
    
    self.locationManager = [[CLLocationManager alloc]                                                                                 init];
    [self.locationManager setDelegate:self];
    [self.locationManager setDistanceFilter:kCLDistanceFilterNone];
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    [self.locationManager startUpdatingLocation];
    
    _cameraOverLayerView.frame = [UIScreen mainScreen].bounds;
    NSUserDefaults *st = [NSUserDefaults standardUserDefaults];
    
    if (![[st objectForKey:@"isShowAlertLabel"] boolValue]) {
        //        CATransform3D transform = CATransform3DMakeRotation(1.57, 1, 1, 0);
        //            [_alertLabel.layer setTransform:CATransform3DMakeRotation(270 * 3.14 / 180, 0, 1, 0)];
        [st setObject:[NSNumber numberWithBool:YES] forKey:@"isShowAlertLabel"];
        [st synchronize];
        [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(_removeAlertLabel) userInfo:nil repeats:NO];
    }
    
    float height = SCREEN_HEIGHT - _actionView.frame.size.height - _settingView.frame.size.height;
    float oringalY = 0;
    //    _settingView.frame.size.height + _settingView.frame.size.height;
    UIColor *color = [UIColor  colorWithRed:1 green:1 blue:1 alpha:0.35];
    
    _layerImageView.frame = CGRectMake(0, oringalY, SCREEN_WIDTH, height);
    
    UIView *Vline1 = [[UIView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH / 3.0 * 1.0, 0, 0.5, height)];
    Vline1.backgroundColor = color;
    [_layerImageView addSubview:Vline1];
    
    UIView *Vline2 = [[UIView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH / 3.0 * 2.0, 0, 0.5, height)];
    Vline2.backgroundColor = color;
    [_layerImageView addSubview:Vline2];
    
    UIView *Hline1 = [[UIView alloc] initWithFrame:CGRectMake(0, height / 3.0 * 1.0 + oringalY, SCREEN_WIDTH, 0.5)];
    Hline1.backgroundColor = color;
    [_layerImageView addSubview:Hline1];
    
    UIView *Hline2 = [[UIView alloc] initWithFrame:CGRectMake(0, height / 3.0 * 2.0 + oringalY, SCREEN_WIDTH, 0.5)];
    Hline2.backgroundColor = color;
    [_layerImageView addSubview:Hline2];
    
#ifdef CAMERA_TYPE_IMAGE_PICKER
    [self _imagePickerModel];
#else
    [self _AVCaptureSessionModel];
#endif
    
}
- (void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
}
- (void)viewWillDisappear:(BOOL)animated{
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    [super viewWillDisappear:YES];
    
}

- (void)viewDidAppear:(BOOL)animated{
    
    [super viewDidAppear:YES];
#ifndef CAMERA_TYPE_IMAGE_PICKER
    if (self.session) {
        [self.session startRunning];
        [self.view bringSubviewToFront:_cameraOverLayerView];
        
    }
#endif
}
- (void)viewDidDisappear:(BOOL)animated{
    
    [super viewDidDisappear:YES];
#ifndef CAMERA_TYPE_IMAGE_PICKER
    if (self.session) {
        [self.session stopRunning];
    }
#endif
    [self.locationManager stopUpdatingLocation];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    if (self.isViewLoaded && !self.view.window)// 是否是正在使用的视图
    {
        
#ifdef INTERNAL_SERVER_DEBUG_MODE
        NSLog(@"%@ didReceiveMemoryWarning, it's view change nil.", [[self class] description]);
#endif

        self.view = nil;// 目的是再次进入时能够重新加载调用viewDidLoad函数。
    }
    // Dispose of any resources that can be recreated.
}

- (IBAction)_photoLibrary:(id)sender {
    
    [self.delegate cameraPickerDidClickPhotoLibrary:self];
    //    return;
    ////    self.camera.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    //    [self _getPictureFromAlbum];
}
- (void)_getPictureFromAlbum{
    
    if (!_camera) {
        _camera = [[UIImagePickerController alloc] init];
        _camera.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        
    }
    _camera.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    _camera.mediaTypes = [NSArray arrayWithObjects:(NSString*)kUTTypeImage, nil];
    //    _camera.allowsEditing = YES;
    _camera.delegate = self;
    [self presentViewController:_camera animated:NO completion:^(void){}];
}
- (void)_getPictureFromCamera{
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        NSArray *avalibity = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        
        BOOL available = NO;
        for (NSString *pres in avalibity) {
            if ([pres isEqualToString:((NSString *)kUTTypeImage)]) {
                available = YES;
                break;
            }
        }
        if (available) {
            
            [self performSelector:@selector(_presentPictureCamera) withObject:nil afterDelay:0];
            
        }
        else {
            [self _getPictureFromAlbum];
        }
    }
    else {
        [self _getPictureFromAlbum];
    }
}

- (void)_presentPictureCamera{
    
    if (!_camera) {
        _camera = [[UIImagePickerController alloc] init];
        _camera.sourceType = UIImagePickerControllerSourceTypeCamera;
        _camera.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        _camera.allowsEditing = NO;
        _camera.delegate = self;
        _camera.showsCameraControls = NO;
        _camera.cameraOverlayView = _cameraOverLayerView;
        
        if ([[UIScreen mainScreen] bounds].size.height > 480) {
            _camera.cameraViewTransform = CGAffineTransformMakeTranslation(0, 49);
        }
        
        _camera.cameraFlashMode = _flashMode;
        _camera.cameraDevice = _currentDevice;
        _camera.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
        _flashBtn.hidden = ![UIImagePickerController isFlashAvailableForCameraDevice:[_camera cameraDevice]];
        [self presentViewController:_camera animated:NO completion:^(void){
            
            self.view.frame = [[UIScreen mainScreen] bounds];
        }];
    }
}


#pragma mark -
#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    
    [self dismissViewControllerAnimated:NO completion:nil];
    
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        
        
        UIDeviceOrientation orien = [[UIDevice currentDevice] orientation];
        //        CGImageSourceRef source;
        ////        source = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
        //
        //        NSDictionary *metadata = (NSDictionary *) CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, 0, NULL));
        //        CFRelease(source);
        //        NSMutableDictionary *metadataAsMutable = [metadata mutableCopy];
        
        
        CGImagePropertyOrientation imagePropertyOrientation = kCGImagePropertyOrientationUp;
        //
        switch (orien) {
            case UIDeviceOrientationPortrait:
                
                imagePropertyOrientation = kCGImagePropertyOrientationUp;
                break;
                
            case UIDeviceOrientationPortraitUpsideDown:
                
                imagePropertyOrientation = kCGImagePropertyOrientationDown;
                break;
                
            case UIDeviceOrientationLandscapeLeft:
                
                imagePropertyOrientation = kCGImagePropertyOrientationLeft;
                break;
                
            case UIDeviceOrientationLandscapeRight:
                
                imagePropertyOrientation = kCGImagePropertyOrientationRight;
                break;
                
            default:
                break;
        }
        
        NSDictionary *dict = [info objectForKey:UIImagePickerControllerMediaMetadata];
        NSMutableDictionary *metadata = [NSMutableDictionary dictionaryWithDictionary:dict];
        
        NSDictionary * gpsDict=[self.currentLocation GPSDictionary];//CLLocation对象转换为NSDictionary
        if (metadata&& gpsDict) {
            [metadata setValue:gpsDict forKey:(NSString*)kCGImagePropertyGPSDictionary];
        }
        [metadata setValue:[NSNumber numberWithInteger:imagePropertyOrientation] forKey:(NSString *)kCGImagePropertyOrientation];
        
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        
        UIImage *image = [self fixOrientation:[info objectForKey:UIImagePickerControllerOriginalImage]];
        [library writeImageToSavedPhotosAlbum:image.CGImage metadata:metadata completionBlock:^(NSURL *assetURL, NSError *error) {
            
            
        }];
        
        
        if ([self.delegate respondsToSelector:@selector(cameraPicker:didPickImage:location:createTime:sourceType:)]) {
            
            [self.delegate cameraPicker:self didPickImage:[self _adjustImage:image] location:self.currentLocation createTime:[self nowString] sourceType:picker.sourceType];
        }
    }
    else if (picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary)
    {
        __block NSMutableDictionary *imageMetadata = nil;
        NSURL *assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library assetForURL:assetURL
                 resultBlock:^(ALAsset *asset)  {
                     imageMetadata = [[NSMutableDictionary alloc] initWithDictionary:asset.defaultRepresentation.metadata];
                     //控制台输出查看照片的metadata
                     CLLocation *loc = nil;
                     //GPS数据
                     NSDictionary *GPSDict=[imageMetadata objectForKey:(NSString*)kCGImagePropertyGPSDictionary];
                     if (GPSDict!=nil) {
                         loc=[GPSDict locationFromGPSDictionary];
                     }
                     else{
                         NSLog(@"此照片没有GPS信息");
                     }
                     
                     //EXIF数据
                     NSMutableDictionary *EXIFDictionary =[[imageMetadata objectForKey:(NSString *)kCGImagePropertyExifDictionary]mutableCopy];
                     NSString * dateTimeOriginal=[[EXIFDictionary objectForKey:(NSString*)kCGImagePropertyExifDateTimeOriginal] mutableCopy];
                     NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                     [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"];//yyyy-MM-dd HH:mm:ss
                     //                     NSDate *date = [dateFormatter dateFromString:dateTimeOriginal];
                     
                     if ([self.delegate respondsToSelector:@selector(cameraPicker:didPickImage:location:createTime:sourceType:)]) {
                         UIImage *image = [self fixOrientation:[info objectForKey:UIImagePickerControllerOriginalImage]];
                         [self.delegate cameraPicker:self didPickImage:image location:loc createTime:dateTimeOriginal sourceType:picker.sourceType];
                     }
                     
                 }
                failureBlock:^(NSError *error) {
                    
                    UIImage *image = [self fixOrientation:[info objectForKey:UIImagePickerControllerOriginalImage]];
                    if ([self.delegate respondsToSelector:@selector(cameraPicker:didPickImage:location:createTime:sourceType:)]) {
                        [self.delegate cameraPicker:self didPickImage:image location:nil createTime:nil sourceType:picker.sourceType];
                    }
                }];
        
    }
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else if (picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary){
        
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            self.camera.sourceType = UIImagePickerControllerSourceTypeCamera;
        }
        else{
            
            if ([self.delegate respondsToSelector:@selector(cameraPickerDidCancel:)]) {
                [self.delegate cameraPickerDidCancel:self];
            }
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}


#pragma mark -
#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    
    self.currentLocation = locations.lastObject;
    [self.locationManager stopUpdatingLocation];
    //获取照片元数据
    
    
}
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    
}


- (void)writeCGImage:(UIImage*)image metadata:(NSDictionary *)metadata{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    ALAssetsLibraryWriteImageCompletionBlock imageWriteCompletionBlock =
    ^(NSURL *newURL, NSError *error) {
        if (error) {
            NSLog( @"Error writing image with metadata to Photo Library: %@", error );
        } else {
            NSLog( @"Wrote image with metadata to Photo Library");
        }
    };
    
    //保存相片到相册 注意:必须使用[image CGImage]不能使用强制转换: (__bridge CGImageRef)image,否则保存照片将会报错
    [library writeImageToSavedPhotosAlbum:[image CGImage]
                                 metadata:metadata
                          completionBlock:imageWriteCompletionBlock];
}

- (UIImage *)fixOrientation:(UIImage *)aImage {
    
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}




#pragma mark -
#pragma mark - UICollectionView
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    
    return self.photos.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    UICollectionViewCell *cell=[collectionView dequeueReusableCellWithReuseIdentifier:@"UICollectionViewCell" forIndexPath:indexPath];
    if(!cell){
        
        cell = [[UICollectionViewCell alloc] initWithFrame:CGRectMake(cell.frame.origin.x, cell.frame.origin.y, (SCREEN_WIDTH - 10) / 4, (SCREEN_WIDTH - 10) / 4)];
    }
    //    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(cell.frame.origin.x, cell.frame.origin.y, (SCREEN_WIDTH - 10) / 4, (SCREEN_WIDTH - 10) / 4)];
    //    imageView.image = [[self.photos objectAtIndex:indexPath.row] objectForKey:@"thumbnail"];
    ////    imageView.backgroundColor = [UIColor redColor];
    //    imageView.contentMode = UIViewContentModeScaleAspectFill;
    //    imageView.clipsToBounds = YES;
    //    [cell addSubview:imageView];
    return cell;
}
//- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
//
//    return UIEdgeInsetsMake(2, 2, 0, 0);
//}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    return CGSizeMake((SCREEN_WIDTH - 20) / 4, (SCREEN_WIDTH - 20) / 4);
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
}



- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    
    
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
    
    
}


#pragma mark -
#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    
    if (buttonIndex == 1) {
        
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];//ios8以上可用
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            
            [[UIApplication sharedApplication] openURL:url];
        }
 
    }
//    [self dismissViewControllerAnimated:YES completion:nil];
    
}

@end








