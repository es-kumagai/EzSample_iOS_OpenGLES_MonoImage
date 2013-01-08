//
//  EzMonoImage.m
//  EzSample_OpenGLES_MonoImage
//
//  Created by 熊谷 友宏 on H.24/12/23.
//  Copyright (c) 平成24年 Tomohiro Kumagai. All rights reserved.
//

#import "EzMonoImage.h"
#import "Matrix.h"

#define EzOpenGLESAssert \
{ \
	int _OpenGLESError = glGetError(); \
	NSString* _OpenGLESErrorMessage = [[NSString alloc] initWithFormat:@"glGetError() = 0x%X", _OpenGLESError]; \
	NSAssert(_OpenGLESError == GL_NO_ERROR, _OpenGLESErrorMessage); \
}

@implementation EzMonoImage
{
	EAGLContext* mpGLContext;
	
	GLuint mFrameBuffer;
	GLuint mColorBuffer;

	GLint width;
	GLint height;
	
	GLuint program;
	
	GLint u_texture;
	GLint u_color;
	GLint u_matrix;
	
	GLuint texture;
	
	UIImage* image;
	CGImageRef imageRef;
	size_t imageWidth;
	size_t imageHeight;
	
	CGFloat red;
	CGFloat green;
	CGFloat blue;
	CGFloat alpha;
	
	CGFloat scale;
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

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];

	NSLog(@"INIT");
	// drawRect 内で以下を実行すると "calling -display has no effect" になる。
	/** 設定されたレイヤの取得 **/
	CAEAGLLayer* pGLLayer = (CAEAGLLayer*)self.layer;
	
	// 不透明にすることで処理速度が上がる
	pGLLayer.opaque = NO;
	
	
	/** 描画の設定を行う **/
	// 辞書登録をする。
	// 順番として 値 → キー
	pGLLayer.drawableProperties = [ NSDictionary dictionaryWithObjectsAndKeys:
								   /** 描画後レンダバッファの内容を保持しない。 **/
								   [ NSNumber numberWithBool:NO ],
								   kEAGLDrawablePropertyRetainedBacking,
								   /** カラーレンダバッファの1ピクセルあたりRGBAを8bitずつ保持する **/
								   kEAGLColorFormatRGBA8,
								   kEAGLDrawablePropertyColorFormat,
								   /** 終了 **/
								   nil ];
	
	
	mpGLContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
	
	NSAssert(mpGLContext != nil, @"Invalid context.");

	/** 現在のコンテキストにレンダリングコンテキストを設定する **/
	if ([EAGLContext setCurrentContext:mpGLContext])
	{
		/** フレームバッファを作成する **/
		// Gen で作成 → Bind で現在のコンテキストに格納。　の流れ
		glGenFramebuffers( 1, &mFrameBuffer );               // かぶらない識別子を渡す
		EzOpenGLESAssert;
		
		glBindFramebuffer( GL_FRAMEBUFFER, mFrameBuffer );   // コンテキストに与えられた識別子をもつフレームバッファを作成
		EzOpenGLESAssert;
		
		/** カラーレンダバッファを作成する **/
		glGenRenderbuffers( 1, &mColorBuffer );
		EzOpenGLESAssert;
		
		glBindRenderbuffer( GL_RENDERBUFFER, mColorBuffer );
		EzOpenGLESAssert;
		
		// フレームバッファとレンダバッファを結びつける
		glFramebufferRenderbuffer( GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, mColorBuffer );
		EzOpenGLESAssert;
	}
	else
	{
		NSAssert(NO, @"Failed to set context.");
	}
	
	return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	//image = [UIImage imageNamed:@"IMG_0098.JPG"];
	//	image = [UIImage imageNamed:@"IMG_0098s.JPG"];
	//	image = [UIImage imageNamed:@"Lenna.png"];
	//	image = [UIImage imageNamed:@"5-m.png"];
	//	image = [UIImage imageNamed:@"EzEraseButton.48x48.png"];
	image = self.sourceImageView.image;
	
	
	imageRef = image.CGImage;
	imageWidth = CGImageGetWidth(imageRef);
	imageHeight = CGImageGetHeight(imageRef);
	
	// Retina 対応。このとき、画像サイズはそのまま、表示座標系が２倍に成る？
	scale = [UIScreen mainScreen].scale;
	self.contentScaleFactor = image.scale;
	
	[self.sourceMonochromeView.backgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
	
	NSLog(@"Layout Begin: %p", self);
	
	
	[EAGLContext setCurrentContext:mpGLContext];	// 複数のコンテキストが存在するとき、これが無いとおかしくなる。
		
	// 先ほどのレンダバッファオブジェクトに描画するために必要なストレージを割り当てる。
	//      fromDrawable : レンダバッファにバインドするストレージ
	// ストレージをレイヤに割り当てることで、バッファに書き込んだらレイヤに書き込まれる!
	[ mpGLContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:( CAEAGLLayer* )self.layer ];
	
	/** フレームバッファが正しく設定されたかチェックする **/
	NSAssert((glCheckFramebufferStatus( GL_FRAMEBUFFER ) == GL_FRAMEBUFFER_COMPLETE), ([[NSString alloc] initWithFormat:@"フレームバッファが正しくありません！ %x", glCheckFramebufferStatus( GL_FRAMEBUFFER )]));

	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
	EzOpenGLESAssert;
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
	EzOpenGLESAssert;

	NSLog(@"w=%d, h=%d", width, height);

//	glViewport(0.0, 0.0, width, height);	// MARK: 必須
	glViewport(0.0, 0.0, imageWidth, imageHeight);
	EzOpenGLESAssert;
	NSLog(@"Image : w=%lu, h=%lu", imageWidth, imageHeight);
	
//	// 左X, 右X, 下Y, 上Y, 手前Z, 奥Z
//	glMatrixMode(GL_PROJECTION);
//	EzOpenGLESAssert;
//	glOrthof( 0.0f, 305.0f, 215.0f, 0.0f, 0.5f, -0.5f );
//	EzOpenGLESAssert;
	
	[self build];
}

- (void)build
{
	// シェーダーを作る。
	const char* code = ""
	"precision lowp float;\n"
	"varying vec2 v_texCoord;\n"
	"uniform lowp vec4 u_color;\n"
	"uniform sampler2D u_texture;\n"
	"void main(){\n"
	"	vec4 texcolor;\n"
	"	vec4 monocolor;\n"
	"	float texcolor_brightness;\n"
	"	vec3 coefficient;\n"
	"	monocolor = u_color;\n"
	"	texcolor = texture2D(u_texture, v_texCoord.xy);\n"
	"	texcolor_brightness = max(texcolor.r, max(texcolor.g, texcolor.b));\n"
	"	coefficient = vec3(1.0) - monocolor.rgb;\n"
	"	gl_FragColor = vec4(monocolor.rgb + vec3(pow(texcolor_brightness, 3.0)) * coefficient, monocolor.a * texcolor.a);\n"
	"}";
	
//	code = ""
//	"precision lowp float;\n"
//	"//precision highp float;\n"
//	"varying vec2 v_texCoord;\n"
//	"uniform lowp vec4 u_color;\n"
//	"//uniform highp vec4 u_color;\n"
//	"uniform sampler2D u_texture;\n"
//	"void main(){\n"
//	"	vec4 color;\n"
//	"	vec4 monocolor;\n"
//	"	float brightness;\n"
//	"	monocolor = u_color;\n"
//	"	color = texture2D(u_texture, v_texCoord.xy);\n"
//	"	brightness = max(color.r, max(color.g, color.b));"
//	"	gl_FragColor = vec4(monocolor.r * brightness, monocolor.g * brightness, monocolor.b * brightness, color.a);\n"
//	"//	gl_FragColor = color;\n"
//	"}";

	// 頂点シェーダーもいる？
	const char* vcode = ""
	"attribute vec2 a_position;\n"
	"attribute vec2 a_texCoord;\n"
	"uniform mat4 u_matrix;\n"
	"varying vec2 v_texCoord;\n"
	"void main(void){\n"
	"	mat4 dummy = u_matrix;"
	"	gl_Position = u_matrix * vec4(a_position, 0.0, 1.0);\n"
	"//	gl_Position = vec4(a_position, 0.0, 1.0);\n"
	"	v_texCoord = a_texCoord;\n"
	"}\n";
	
	GLint compiled;
	
	program = glCreateProgram();
	
	GLuint vShader = glCreateShader(GL_VERTEX_SHADER);
	EzOpenGLESAssert;
	glShaderSource(vShader, 1, &vcode, NULL);
	EzOpenGLESAssert;
	glCompileShader(vShader);
	EzOpenGLESAssert;
	glGetShaderiv(vShader, GL_COMPILE_STATUS, &compiled);
	
	if (!compiled)
	{
		GLint infoLen=0;
		glGetShaderiv(vShader, GL_INFO_LOG_LENGTH, &infoLen);
		EzOpenGLESAssert;
		
		if (infoLen > 0)
		{
			char* infoLog = (char*)malloc(sizeof(char)*infoLen);
			
			glGetShaderInfoLog(vShader, infoLen, NULL, infoLog);
			EzOpenGLESAssert;
			
			NSLog(@"Compile error: %s", infoLog);
			free(infoLog);
		}
		else
		{
			NSLog(@"Unknown compile error.");
		}
		
		glDeleteShader(vShader);
		EzOpenGLESAssert;
		
		NSAssert(false, @"Failed to compile a shader.");
	}
	

	GLuint shader = glCreateShader(GL_FRAGMENT_SHADER);
	EzOpenGLESAssert;
	NSAssert(shader != GL_FALSE, @"Failed to create shader.");
	
	glShaderSource(shader, 1, &code, NULL);
	EzOpenGLESAssert;
	
	glCompileShader(shader);
	EzOpenGLESAssert;
	
	glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
	
	if (!compiled)
	{
		GLint infoLen=0;
		glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLen);
		EzOpenGLESAssert;
		
		if (infoLen > 0)
		{
			char* infoLog = (char*)malloc(sizeof(char)*infoLen);
			
			glGetShaderInfoLog(shader, infoLen, NULL, infoLog);
			EzOpenGLESAssert;
			
			NSLog(@"Compile error: %s", infoLog);
			free(infoLog);
		}
		else
		{
			NSLog(@"Unknown compile error.");
		}
		
		glDeleteShader(shader);
		EzOpenGLESAssert;
		
		NSAssert(false, @"Failed to compile a shader.");
	}
	
	glAttachShader(program, shader);
	EzOpenGLESAssert;
	glAttachShader(program, vShader);
	EzOpenGLESAssert;
	
	
	// MARK: アトリビュート（リンクの後でも平気？）
	glBindAttribLocation(program, 0, "a_position");
	EzOpenGLESAssert;
	glBindAttribLocation(program, 1, "a_texCoord");
	EzOpenGLESAssert;
	

	glLinkProgram(program);
	EzOpenGLESAssert;
	
	GLint linked;
	glGetProgramiv(program, GL_LINK_STATUS, &linked);
	
	if (!linked)
	{
		GLint infoLen=0;
		glGetProgramiv(program, GL_INFO_LOG_LENGTH, &infoLen);
		EzOpenGLESAssert;
		
		if (infoLen > 0)
		{
			char* infoLog = (char*)malloc(sizeof(char)*infoLen);
			glGetProgramInfoLog(program, infoLen, NULL, infoLog);
			EzOpenGLESAssert;
			
			NSLog(@"Link Error: %s", infoLog);
			free(infoLog);
		}
		else
		{
			NSLog(@"Link Error: Unknown");
		}
		
		NSAssert(false, @"Failed to link shaders.");
	}
	
	// リンクに成功したら、シェーダー不要？
	glDetachShader(program, shader);
	EzOpenGLESAssert;
	
	glDeleteShader(shader);
	EzOpenGLESAssert;
	
	glDetachShader(program, vShader);
	glDeleteShader(vShader);
	
	// ユニフォーム変数
	u_texture = glGetUniformLocation(program, "u_texture");
	NSAssert(u_texture != -1, @"Uniform variable 'u_texture' was not found.");
	
	u_color = glGetUniformLocation(program, "u_color");
	NSAssert(u_color != -1, @"Uniform variable 'u_color' was not found.");
		
	u_matrix = glGetUniformLocation(program, "u_matrix");
	NSAssert(u_matrix != -1, @"Uniform variable 'u_matrix' was not found.");
	
//	[self setNeedsDisplay];
	NSLog(@"Layout End: %p", self);
	
	[self draw];
}

- (void)draw
{
	NSLog(@"Draw Begin: %p", self);

	// MARK: drawView@IBGLView
	
	[EAGLContext setCurrentContext:mpGLContext]; // MARK: 必要？
//	glBindFramebuffer(GL_FRAMEBUFFER, mFrameBuffer);	// MARK: 必要？
//	EzOpenGLESAssert;
//	glBindRenderbuffer( GL_RENDERBUFFER, mColorBuffer );
//	EzOpenGLESAssert;
//	// フレームバッファとレンダバッファを結びつける
//	glFramebufferRenderbuffer( GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, mColorBuffer );
//	EzOpenGLESAssert;
	
	glClearColor(0.8, 1.0, 1.0, 1.0);
	EzOpenGLESAssert;

//	glClear(GL_COLOR_BUFFER_BIT);
	EzOpenGLESAssert;

	// MARK: drawMain@MyGLView
	
	// 頂点シェーダー設定？
	// 位置
//	GLfloat w = fminf(width, height);
//	GLfloat h = w;
	GLfloat w = width;
	GLfloat h = height;
	
//	GLKVector2 positions[4];
//	GLKVector2 texCoords[4];
//	
//	positions[0].x = 0.0;
//	positions[0].y = 0.0;
//	positions[1].x = w;
//	positions[1].y = 0.0;
//	positions[2].x = 0.0;
//	positions[2].y = w;
//	positions[3].x = w;
//	positions[3].y = w;
//	// テクスチャ座標
//	texCoords[0].x = 0.0;
//	texCoords[0].y = 0.0;
//	texCoords[1].x = 1.0;
//	texCoords[1].y = 0.0;
//	texCoords[2].x = 0.0;
//	texCoords[2].y = 1.0;
//	texCoords[3].x = 1.0;
//	texCoords[3].y = 1.0;
	
	// 位置
	Vector positions[4];
	// テクスチャ座用
	Vector texCoords[4];

	positions[0] = Vector(0, 0);
	positions[1] = Vector(w, 0);
	positions[2] = Vector(0, h);
	positions[3] = Vector(w, h);
	// テクスチャ座標
	texCoords[0] = Vector(0,0);
	texCoords[1] = Vector(1,0);
	texCoords[2] = Vector(0,1);
	texCoords[3] = Vector(1,1);

	
	// MARK: initWithUIImage@IBGLImage
	
	// 画像データ準備
	size_t imageBytes = imageWidth * imageHeight * 4 * sizeof(Byte);
	Byte* imageData = (Byte*)malloc(imageBytes);
	memset(imageData, 0, imageBytes);	// バッファを初期化しないとノイズが入る様子。
	
	NSLog(@"Texture (%p) : w=%lu, h=%lu", imageData, imageWidth, imageHeight);
	
	CGContextRef memContext = CGBitmapContextCreate(imageData, imageWidth, imageHeight, 8/*8bit/要素*/,
													imageWidth * 4/*row bytes*/, CGImageGetColorSpace(imageRef),
													kCGImageAlphaPremultipliedLast);
	//コンテキストに画像を描画(これでdataに描画される）
	CGContextDrawImage(memContext, CGRectMake(0.0f, 0.0f, (CGFloat)imageWidth, (CGFloat)imageHeight), imageRef);
	CGContextRelease(memContext);
	
	// テクスチャ生成
	glGenTextures(1, &texture);
	EzOpenGLESAssert;
	
	glBindTexture(GL_TEXTURE_2D, texture);
	EzOpenGLESAssert;
	
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	EzOpenGLESAssert;
	
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imageWidth, imageHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
	EzOpenGLESAssert;
	
//	glGenerateMipmap(GL_TEXTURE_2D);	// MARK: ミップマップ生成は、画像サイズ 2^n である必要有りらしい。GL_TEXTURE_MIN_FILTER で GL_LINEAR_MIPMAP_LINEAR したときに必要。
//	EzOpenGLESAssert;
	
	free(imageData);
	
	
	// MARK: drawArraysMy@MyShader
	
	// プログラムを使います。
	glUseProgram(program);
	EzOpenGLESAssert;
	
	// アルファブレンド
	glEnable(GL_BLEND);
	EzOpenGLESAssert;
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
//	glBlendFunc(GL_DST_ALPHA, GL_SRC_COLOR);
	EzOpenGLESAssert;
	
	
		
	glActiveTexture(GL_TEXTURE0);
	EzOpenGLESAssert;
	
	
	glUniform1i(u_texture, 0); // Texture Unit 0
	
	
	glBindTexture(GL_TEXTURE_2D, texture); // MARK: 必要？
	
	// テクスチャの横リピート指定。
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);//GL_REPEATは、2のべき乗サイズのテクスチャのときのみ可
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	// 拡大 MAG 縮小 MIN 時の補完指定。GL_NEAREST=最近傍法, GL_LINEAR=双線形補完
	// 縮小においては次のものが選べる。
//#define GL_NEAREST_MIPMAP_NEAREST         0x2700
//#define GL_LINEAR_MIPMAP_NEAREST          0x2701
//#define GL_NEAREST_MIPMAP_LINEAR          0x2702
//#define GL_LINEAR_MIPMAP_LINEAR           0x2703
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	EzOpenGLESAssert;
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);	// MARK: これがないと荒くなる様子。
//	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);	// MARK: これがないと荒くなる様子。
//	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);	// MARK: これがないと荒くなる様子。
	EzOpenGLESAssert;

	
	static GLuint VA_POSITION = 0;
	static GLuint VA_TEXCOORD = 1;
	
	glEnableVertexAttribArray(VA_POSITION);
	EzOpenGLESAssert;
	glVertexAttribPointer(VA_POSITION, 2, GL_FLOAT, GL_FALSE, 0, positions);
	EzOpenGLESAssert;
	
	glEnableVertexAttribArray(VA_TEXCOORD);
	EzOpenGLESAssert;
	glVertexAttribPointer(VA_TEXCOORD, 2, GL_FLOAT, GL_FALSE, 0, texCoords);
	EzOpenGLESAssert;
	
	
	// ユニフォーム設定
//	glUniform4f(u_color, 0.5, 1.0, 0.5, 1.0);
	glUniform4f(u_color, red, green, blue, alpha);
	EzOpenGLESAssert;

	// 平行投影変換の写像
	// 視野空間の中心が原点と成るように、-w/2 平行移動、大きさを 2/w 倍する。y, z についても同様。
	// -1.0 から 1.0 の座標系なので、right+left などは 2.0 になる。
	//
	//	2/w,	0,		0,		0
	//	0,		2/-h,	0,		0
	//	0,		0,		-2/d,	0
	//	0,		0,		0,		1
	//
	//			×
	//
	//	1,		0,		0,		-(right+left)/2
	//	0,		1,		0,		-(top+bottom)/2
	//	0,		0,		1,		(far+near)/2
	//	0,		0,		0,		1
	//
	// これを縦横を入れ変えた float 配列にします。
	
//	Matrix m;
//	GLfloat matrix[16];
//	m.addScale(Vector(2.f/self.bounds.size.width, -2/self.bounds.size.height));
//	m.addTranslation(Vector(-1.f, 1.f));
//	m.getMat4(matrix);
//	GLfloat matrix[16] = {
//		0.00655738, 0, 0, -1,
//		0, -0.00930233, 0, 1,
//		0, 0, 1, 0,
//		0, 0, 0, 1 };
	GLfloat matrix[16] = {
		2.0f/w, 0, 0, 0,
		0, -2.0f/h, 0, 0,
		0, 0, 1, 0,
		-1, 1, 0, 1 };
	glUniformMatrix4fv(u_matrix, 1, GL_FALSE, matrix);
	EzOpenGLESAssert;
	
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);		// glVertexPointer で設定した要素が 4 つ
	EzOpenGLESAssert;

	// MARK: drawView@IBGLView
	
	glFlush();
	EzOpenGLESAssert;
		
	// バックバッファをフロントバッファへ
	glBindRenderbuffer(GL_RENDERBUFFER, mColorBuffer);
	EzOpenGLESAssert;
	
	[mpGLContext presentRenderbuffer:GL_RENDERBUFFER];
	
	glDisable(GL_BLEND);
	EzOpenGLESAssert;

	NSLog(@"Draw End: %p", self);

}

- (void)dealloc
{
	NSLog(@"Dealloc Begin: %p", self);
	
	NSLog(@"Finalize Begin: %p", self);
	
	[EAGLContext setCurrentContext:nil];
	
	glDeleteProgram(program);
	EzOpenGLESAssert;
	
	glDeleteTextures(1, &texture);
	EzOpenGLESAssert;
	
	glDeleteFramebuffers(1,&mFrameBuffer);
	EzOpenGLESAssert;
	
	glDeleteRenderbuffers(1, &mColorBuffer);
	EzOpenGLESAssert;
	
	mpGLContext = nil;
	NSLog(@"Finalize End: %p", self);
	
	NSLog(@"Dealloc End: %p", self);
}

@end
