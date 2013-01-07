//
//  EzMonoImage.m
//  EzSample_OpenGLES_MonoImage
//
//  Created by 熊谷 友宏 on H.24/12/23.
//  Copyright (c) 平成24年 Tomohiro Kumagai. All rights reserved.
//

#import "EzMonoImage.h"

@implementation EzMonoImage
{
	EAGLContext* mpGLContext;
	
	GLuint mFrameBuffer;
	GLuint mColorBuffer;
}

+ (Class)layerClass
{
	return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
	[self setNeedsDisplay];

	// drawRect 内で以下を実行すると "calling -display has no effect" になる。
	/** 設定されたレイヤの取得 **/
	CAEAGLLayer* pGLLayer = ( CAEAGLLayer* )self.layer;
	
	// 不透明にすることで処理速度が上がる
	pGLLayer.opaque = YES;
	
	
	/** 描画の設定を行う **/
	// 辞書登録をする。
	// 順番として 値 → キー
	pGLLayer.drawableProperties = [ NSDictionary dictionaryWithObjectsAndKeys:
								   /** 描画後レンダバッファの内容を保持しない。 **/
								   [ NSNumber numberWithBool:FALSE ],
								   kEAGLDrawablePropertyRetainedBacking,
								   /** カラーレンダバッファの1ピクセルあたりRGBAを8bitずつ保持する **/
								   kEAGLColorFormatRGBA8,
								   kEAGLDrawablePropertyColorFormat,
								   /** 終了 **/
								   nil ];
	
	
	mpGLContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
	
	/** 現在のコンテキストにレンダリングコンテキストを設定する **/
	[ EAGLContext setCurrentContext:mpGLContext ];
	
    /** フレームバッファを作成する **/
	// Gen で作成 → Bind で現在のコンテキストに格納。　の流れ
	glGenFramebuffers( 1, &mFrameBuffer );               // かぶらない識別子を渡す
	glBindFramebuffer( GL_FRAMEBUFFER, mFrameBuffer );   // コンテキストに与えられた識別子をもつフレームバッファを作成
	
	
	/** カラーレンダバッファを作成する **/
	glGenRenderbuffers( 1, &mColorBuffer );
	glBindRenderbuffer( GL_RENDERBUFFER, mColorBuffer );
	
	// 先ほどのレンダバッファオブジェクトに描画するために必要なストレージを割り当てる。
	//      fromDrawable : レンダバッファにバインドするストレージ
	// ストレージをレイヤに割り当てることで、バッファに書き込んだらレイヤに書き込まれる!
	[ mpGLContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:( CAEAGLLayer* )self.layer ];
	
	// フレームバッファとレンダバッファを結びつける
	glFramebufferRenderbuffer( GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, mColorBuffer );
	
	/** フレームバッファが正しく設定されたかチェックする **/
	if ( glCheckFramebufferStatus( GL_FRAMEBUFFER ) != GL_FRAMEBUFFER_COMPLETE )
		NSLog( @"フレームバッファが正しくありません！ %x", glCheckFramebufferStatus( GL_FRAMEBUFFER ) );
	/** X を 0.0f ~ 320.0 に、 Y を 0.0 ~ 480.0f にする **/
	// 左X, 右X, 下Y, 上Y, 手前Z, 奥Z
	glOrthof( 0.0f, 320.0f, 480.0f, 0.0f, 0.5f, -0.5f );
	
	[mpGLContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:pGLLayer];
	
	
	glClearColor(0.5, 0.8, 3.0, 1.0);
	glClear(GL_COLOR_BUFFER_BIT);

	
	
	
	
	UIImage* image = [UIImage imageNamed:@"IMG_0098.JPG"];

	const char* code = "void main (void) { gl_FragColor = vec4(1.0, 1.0, 0.66, 1.0); }";
	GLuint shader = glCreateShader(GL_FRAGMENT_SHADER);
	
	glShaderSource(shader, 1, &code, NULL);
	glCompileShader(shader);
	
	GLint compiled;
	
	glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
	if (!compiled)
	{
		NSLog(@"COMPILE ERROR");
	}
	else
	{
		GLuint program = glCreateProgram();
		glAttachShader(program, shader);
		glLinkProgram(program);
		
		GLint linked;
		glGetProgramiv(program, GL_LINK_STATUS, &linked);
		
		if (!linked)
		{
			NSLog(@"LINK ERROR");
		}
		else
		{
			glUseProgram(program);
		}
	}
	
	//image;
	//CAEAGLLayer;
	
	CAEAGLLayer
	
	[mpGLContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)dealloc
{
	glDeleteFramebuffers(1,&mFrameBuffer);
	glDeleteRenderbuffers(1, &mColorBuffer);
}

- (void)drawRect:(CGRect)rect
{
	[super drawRect:rect];
	
}

@end
