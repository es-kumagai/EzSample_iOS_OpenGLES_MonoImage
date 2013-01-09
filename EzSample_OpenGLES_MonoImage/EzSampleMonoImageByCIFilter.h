//
//  EzSampleMonoImageByCIFilter.h
//  EzSample_OpenGLES_MonoImage
//
//  Created by 熊谷 友宏 on H.25/01/09.
//  Copyright (c) 平成25年 Tomohiro Kumagai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EzSampleMonoImageByCIFilter : UIImageView

@property (nonatomic,readonly,weak) IBOutlet UIImageView* sourceImageView;
@property (nonatomic,readonly,weak) IBOutlet UIView* sourceMonochromeView;

@end
