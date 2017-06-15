//
//  CameraPicker.h
//  TourWay
//
//  Created by luomeng on 15/11/12.
//  Copyright © 2015年 OneThousandandOneNights. All rights reserved.
//

#import <UIKit/UIKit.h>

#define CAMERA_TYPE_IMAGE_PICKER

@class CameraPicker;
@class UIImagePickerController;
@class CLLocation;
@protocol CameraPickerDelegate <NSObject>

@optional
- (void)cameraPicker:(CameraPicker *)camera didPickImage:(UIImage *)pickedImage location:(CLLocation *)location createTime:(NSString *)time sourceType:(UIImagePickerControllerSourceType)sourceType;    //still camera, image back

- (void)cameraPickerDidClickPhotoLibrary:(CameraPicker *)camera;
- (void)cameraPickerDidCancel:(CameraPicker *)camera;

@end

@interface CameraPicker : UIViewController

@property (nonatomic, assign)id<CameraPickerDelegate>delegate;
@property (nonatomic, assign)UIImagePickerControllerSourceType sourceType;

@end
