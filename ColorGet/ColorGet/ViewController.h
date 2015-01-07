//
//  ViewController.h
//  ColorGet
//
//  Created by iMAC-002 on 5/1/15.
//  Copyright (c) 2015 Redegal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController {
    int alpha;
    UIView *dotView;
    AVCaptureStillImageOutput *output;
}

@property (nonatomic) IBOutlet UIImageView *cameraImageView;
@property (nonatomic) IBOutlet UIButton *switchCamera;
@property (nonatomic) IBOutlet UIView *colorView;
@property (nonatomic) IBOutlet UILabel *xLabel;
@property (nonatomic) IBOutlet UILabel *yLabel;
@property (nonatomic) IBOutlet UILabel *colorLabel;

@end

