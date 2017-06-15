//
//  ViewController.m
//  TWCameraPicker
//
//  Created by luomeng on 2017/6/15.
//  Copyright © 2017年 XRY. All rights reserved.
//

#import "ViewController.h"
#import "CameraPicker.h"


@interface ViewController ()
<
CameraPickerDelegate
>
{

    __weak IBOutlet UIImageView *_imageView;
    
}

@end

@implementation ViewController (private)

- (IBAction)_camera:(id)sender {
    
    CameraPicker *camera = [[CameraPicker alloc] init];
    camera.sourceType = UIImagePickerControllerSourceTypeCamera;
    camera.delegate = self;
    [self presentViewController:camera animated:YES completion:nil];
    
}


@end

@implementation ViewController


#pragma mark -
#pragma mark - lifeCycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark -
#pragma mark - CameraPickerDelegate
- (void)cameraPickerDidCancel:(CameraPicker *)camera{

    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)cameraPicker:(CameraPicker *)camera didPickImage:(UIImage *)pickedImage location:(CLLocation *)location createTime:(NSString *)time sourceType:(UIImagePickerControllerSourceType)sourceType{

    _imageView.image = pickedImage;
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end











