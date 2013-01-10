//
//  EzMonoImage.h
//  EzSample_OpenGLES_MonoImage
//
//  Created by 熊谷 友宏 on H.24/12/23.
//  Copyright (c) 平成24年 Tomohiro Kumagai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <QuartzCore/QuartzCore.h>

@interface EzMonoImage : UIView

@property (nonatomic,readonly,weak) IBOutlet UIImageView* sourceImageView;
@property (nonatomic,readonly,weak) IBOutlet UIView* sourceMonochromeView;

- (void)glInit;
- (void)glPrepare;
- (void)glBuild;
- (void)glDraw;

@end

