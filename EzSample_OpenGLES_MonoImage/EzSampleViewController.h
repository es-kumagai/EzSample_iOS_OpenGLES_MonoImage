//
//  EzSampleViewController.h
//  EzSample_OpenGLES_MonoImage
//
//  Created by 熊谷 友宏 on H.24/12/23.
//  Copyright (c) 平成24年 Tomohiro Kumagai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EzSampleViewController : UIViewController

@property (nonatomic,readonly,weak) IBOutlet UIImageView* imageView;
@property (nonatomic,readonly,strong) IBOutletCollection(UIView) NSArray* monochromeViews;

@end
