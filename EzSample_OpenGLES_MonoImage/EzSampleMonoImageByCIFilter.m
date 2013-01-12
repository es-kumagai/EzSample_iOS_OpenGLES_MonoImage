//
//  EzSampleMonoImageByCIFilter.m
//  EzSample_OpenGLES_MonoImage
//
//  Created by 熊谷 友宏 on H.25/01/09.
//  Copyright (c) 平成25年 Tomohiro Kumagai. All rights reserved.
//

#import "EzSampleMonoImageByCIFilter.h"

@implementation EzSampleMonoImageByCIFilter

- (void)awakeFromNib
{
	UIImage* image = self.sourceImageView.image;
	UIColor* monochromeColor = self.sourceMonochromeView.backgroundColor;
	
	CIImage* ciImage = [[CIImage alloc] initWithImage:image];
	CIColor* ciColor = [[CIColor alloc] initWithColor:monochromeColor];
	NSNumber* nsIntensity = @1.0f;
	
	CIContext* ciContext = [CIContext contextWithOptions:nil];
	CIFilter* ciMonochromeFilter = [CIFilter filterWithName:@"CIColorMonochrome" keysAndValues:kCIInputImageKey, ciImage, @"inputColor", ciColor, @"inputIntensity", nsIntensity, nil];
		
    CGImageRef cgImage = [ciContext createCGImage:ciMonochromeFilter.outputImage fromRect:[ciMonochromeFilter.outputImage extent]];
	
    UIImage* monochromeImage = [UIImage imageWithCGImage:cgImage scale:image.scale orientation:UIImageOrientationUp];
	
    CGImageRelease(cgImage);
	
	self.image = monochromeImage;
}

@end
