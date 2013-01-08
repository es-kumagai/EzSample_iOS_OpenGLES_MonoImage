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

@end

// デグリーからラジアンへ変換
inline float Deg2Rad(float deg){return (float)M_PI * deg / 180.f;}
// ラジアンからデグリーへ変換
inline float Rad2Deg(float rad){return 180.0f * rad / (float)M_PI;}


class Vector {
public:
	union {
		float	element[2];
		struct {//element[2]の別名
			float	x;
			float	y;
		};
		struct {//element[2]の別名
			float width;
			float height;
		};
	};
	
public:
	//コンストラクタ（ゼロベクトルで初期化）
	Vector(){
		x=0.f;y=0.f;
	}
	//コンストラクタ（x,y,z指定）
	Vector(float X,float Y){
		x=X;y=Y;
	}
	//コピーコンストラクタ
	Vector(const Vector& v){
		x=v.x;y=v.y;
	}
	//コンストラクタ（target-origin)
	Vector(const Vector& target, const Vector& origin){
		x=target.x-origin.x; y=target.y-origin.y;
	}
	//デストラクタ
	//GL用：virtualメソッドが１つでもあるとsizeof(Vector)が8でなくなるためvirtualは付けてはならない
	~Vector(){}
};