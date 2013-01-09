//
//  EzSampleMonoImageByCIFilter.m
//  EzSample_OpenGLES_MonoImage
//
//  Created by 熊谷 友宏 on H.25/01/09.
//  Copyright (c) 平成25年 Tomohiro Kumagai. All rights reserved.
//

#import "EzSampleMonoImageByCIFilter.h"

@implementation EzSampleMonoImageByCIFilter

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)awakeFromNib
{
	UIImage* image = self.sourceImageView.image;
	UIColor* monochromeColor = self.sourceMonochromeView.backgroundColor;
	
	float intensity = 1.0;	// 線形ブレンドの強さを指定します。1.0 のときに完全に指定した色で単調化され、それより大きい場合は強く、小さい場合は弱く適用されますが、指定した色とは別の印象の色も入ってきます。
	
	// 灰色を下地にして、単調色を設定します。
	// MARK: OpenGL ES 2.0 のフラグメントシェーダーが判れば、もっと的確で速い処理が書けるかもしれません。
	CIImage* ciImage = [[CIImage alloc] initWithImage:image];
	CIColor* ciColor = [[CIColor alloc] initWithColor:monochromeColor];
	NSNumber* nsIntensity = [[NSNumber alloc] initWithFloat:intensity];
	
	CIContext* ciContext = [CIContext contextWithOptions:nil];
	CIFilter* ciMonochromeFilter = [CIFilter filterWithName:@"CIColorMonochrome" keysAndValues:kCIInputImageKey, ciImage, @"inputColor", ciColor, @"inputIntensity", nsIntensity, nil];
		
    CGImageRef cgImage = [ciContext createCGImage:ciMonochromeFilter.outputImage fromRect:[ciMonochromeFilter.outputImage extent]];
	
    UIImage* monochromeImage = [UIImage imageWithCGImage:cgImage scale:image.scale orientation:UIImageOrientationUp];
	
    CGImageRelease(cgImage);
	
	self.image = monochromeImage;
}

@end
