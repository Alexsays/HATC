//
//  ViewController.m
//  ColorGet
//
//  Created by iMAC-002 on 5/1/15.
//  Copyright (c) 2015 Redegal. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize cameraImageView, switchCamera, xLabel, yLabel;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    dotView = [[UIView alloc] initWithFrame:CGRectMake(-5, -5, 5, 5)];
    [dotView setBackgroundColor:[UIColor blackColor]];
    [self.view addSubview:dotView];
    
    [self captureLive];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)captureLive {
    NSError *error;
    
    AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
    captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    
    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    previewLayer.frame = cameraImageView.bounds;
    
    [cameraImageView.layer addSublayer:previewLayer];
    
    AVCaptureDevice *backCamera;
    
    for (AVCaptureDevice *device in [AVCaptureDevice devices]) {
        if ([device position] == AVCaptureDevicePositionBack) {
            backCamera = device;
        }
    }
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
    [captureSession addInput:input];
    
    output = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [output setOutputSettings:outputSettings];
    
    [captureSession addOutput:output];
    
    [captureSession startRunning];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[touches allObjects] objectAtIndex:0];
    CGPoint point1 = [touch locationInView:self.view];
    touch = [[event allTouches] anyObject];
    
    if ([[touch view] isKindOfClass:[UIImageView class]]) {
        
        /*CGPoint location = [touch locationInView:cameraImageView];
        UIColor *colorPoint = [self getPixelColorAtLocation:location];
        CGColorRef color = [colorPoint CGColor];
        
        NSLog(@"Touched x:%f y:%f", point1.x, point1.y);*/
        [xLabel setText:[NSString stringWithFormat:@"x: %.0f", point1.x]];
        [yLabel setText:[NSString stringWithFormat:@"y: %.0f", point1.y]];
        [dotView setFrame:CGRectMake(point1.x, point1.y, 5, 5)];
        
        [self captureImageAtX:point1.x atY:point1.y];
    }
}

- (UIImage *)captureImageAtX:(int)pointX atY:(int)pointY {
    __block UIImage *returnImage;
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in output.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) { break; }
    }
    
    NSLog(@"about to request a capture from: %@", output);
    [output captureStillImageAsynchronouslyFromConnection:videoConnection
                                                  completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
                                                      //CFDictionaryRef exifAttachments = CMGetAttachment( imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
                                                      
                                                      NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
                                                      UIImage *image = [[UIImage alloc] initWithData:imageData];
                                                      NSArray *arrayRGB = [ViewController getRGBAsFromImage:image atX:pointX andY:pointY count:1];
                                                      
                                                      [self animateColorView:[arrayRGB objectAtIndex:0]];
                                                      
                                                      returnImage = image;
        
     }];
    
    return returnImage;
}

- (void)animateColorView:(UIColor *)color {
    CGColorRef coloref = [color CGColor];
    const CGFloat* components = CGColorGetComponents(coloref);
    
    CGFloat red = components[0];
    CGFloat green = components[1];
    CGFloat blue = components[2];
    
    [_colorLabel setText:[NSString stringWithFormat:@"%.1f %.1f %.1f", red*255.0, green*255.0, blue*255.0]];
    
    [_colorView setBackgroundColor:color];
    [UIView animateWithDuration:0.2 animations:^{
        [_colorView setHidden:NO];
    }];
    
    [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(hideColorView) userInfo:nil repeats:NO];
}

- (void)hideColorView {
    [UIView animateWithDuration:0.2 animations:^{
        [_colorView setHidden:YES];
    }];
}

+ (NSArray *)getRGBAsFromImage:(UIImage *)image atX:(int)x andY:(int)y count:(int)count {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
    
    // First get the image into your data buffer
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    // Now your rawData contains the image data in the RGBA8888 pixel format.
    NSUInteger byteIndex = (bytesPerRow * y) + x * bytesPerPixel;
    for (int i = 0 ; i < count ; ++i)
    {
        CGFloat red   = (rawData[byteIndex]     * 1.0) / 255.0;
        CGFloat green = (rawData[byteIndex + 1] * 1.0) / 255.0;
        CGFloat blue  = (rawData[byteIndex + 2] * 1.0) / 255.0;
        CGFloat alpha = (rawData[byteIndex + 3] * 1.0) / 255.0;
        byteIndex += bytesPerPixel;
        
        UIColor *acolor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
        [result addObject:acolor];
    }
    
    free(rawData);
    
    return result;
}

@end
