//
//  EzSampleViewController.m
//  EzSample_OpenGLES_MonoImage
//
//  Created by 熊谷 友宏 on H.24/12/23.
//  Copyright (c) 平成24年 Tomohiro Kumagai. All rights reserved.
//

#import "EzSampleViewController.h"
#import <OpenGLES/EAGL.h>
#import <QuartzCore/QuartzCore.h>

@interface EzSampleViewController ()

@end

@implementation EzSampleViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
//	UIImage* image = [UIImage imageNamed:@"IMG_0098.JPG"];
	
//	CIImage *ciImage = [[CIImage alloc] initWithImage:image];
//    CIFilter *ciFilter = [CIFilter filterWithName:@"CIColorMonochrome" //フィルター名
//                                    keysAndValues:kCIInputImageKey, ciImage,
//                          @"inputColor", [CIColor colorWithRed:0.1961 green:0.3098 blue:0.5216], //パラメータ
//                          @"inputIntensity", [NSNumber numberWithFloat:1.0], //パラメータ
//                          nil
//                          ];
//
//    CIContext *ciContext = [CIContext contextWithOptions:nil];
//    CGImageRef cgimg = [ciContext createCGImage:[ciFilter outputImage] fromRect:[[ciFilter outputImage] extent]];
//    UIImage* tmpImage = [UIImage imageWithCGImage:cgimg scale:1.0f orientation:UIImageOrientationUp];
//    CGImageRelease(cgimg);

//	EAGLContext* context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
	
	
	
//	self.imageView.image = tmpImage;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
