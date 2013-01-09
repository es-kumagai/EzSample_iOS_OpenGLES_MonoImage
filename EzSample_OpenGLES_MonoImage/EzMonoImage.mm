//
//  EzMonoImage.m
//  EzSample_OpenGLES_MonoImage
//
//  Created by 熊谷 友宏 on H.24/12/23.
//  Copyright (c) 平成24年 Tomohiro Kumagai. All rights reserved.
//

#import "EzMonoImage.h"
// #import "Matrix.h"

#define EzOpenGLESAssert NSAssert1(glGetError() == GL_NO_ERROR, @"glGetError() = 0x%X", glGetError())

void EzOpenGLESShaderCompileAssert(GLuint shader)
{
	GLint infoLogLength = 0;
	
	glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLogLength);
	
	if (infoLogLength > 0)
	{
		char* infoLog = (char*)malloc(sizeof(char)*infoLogLength);
		
		glGetShaderInfoLog(shader, infoLogLength, NULL, infoLog);
		
		NSLog(@"Compile error: %s", infoLog);
		free(infoLog);
	}
	else
	{
		NSLog(@"Unknown compile error.");
	}
	
	assert(false);
}

@implementation EzMonoImage
{
	EAGLContext* mpGLContext;
	
	GLuint mFrameBuffer;
	GLuint mColorBuffer;

	GLint bufferWidth;
	GLint bufferHeight;
	
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
}

+ (Class)layerClass
{
	return [CAEAGLLayer class];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];

	// 設定されたレイヤの取得
	CAEAGLLayer* pGLLayer = (CAEAGLLayer*)self.layer;
	
	// 不透明にすることで処理速度が上がる。透過したい場合は NO とする。
	pGLLayer.opaque = NO;
	
	
	// 描画の設定を行います。[値, キー] の順でプロパティを指定します。
	pGLLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
								   @NO, 					kEAGLDrawablePropertyRetainedBacking,	// 描画後にレンダバッファの内容を保持しない。
								   kEAGLColorFormatRGBA8, 	kEAGLDrawablePropertyColorFormat,		// レンダバッファーの 1 ピクセルあたり RGBA を 8bit ずつ保持する。
								   nil ];
	
	
	mpGLContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
	NSAssert(mpGLContext != nil, @"Invalid context.");

	// 現在のコンテキストにレンダリングコンテキストを設定
	[EAGLContext setCurrentContext:mpGLContext];

	// フレームバッファとレンダーバッファを作成
	glGenFramebuffers(1, &mFrameBuffer); EzOpenGLESAssert;
	glGenRenderbuffers(1, &mColorBuffer); EzOpenGLESAssert;
	
	// 作成したバッファーをバインドする。
	glBindFramebuffer(GL_FRAMEBUFFER, mFrameBuffer); EzOpenGLESAssert;
	glBindRenderbuffer(GL_RENDERBUFFER, mColorBuffer); EzOpenGLESAssert;
	
	// フレームバッファとレンダバッファを関連付け
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, mColorBuffer); EzOpenGLESAssert;

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

	// 画像の情報を取得します。
	image = self.sourceImageView.image;
	
	imageRef = image.CGImage;
	imageWidth = CGImageGetWidth(imageRef);
	imageHeight = CGImageGetHeight(imageRef);
	
	// Retina に対応するために、画像のイメージスケールを自分自身 UIView のスケールに設定します。
	self.contentScaleFactor = image.scale;
	
	// モノトーンで塗る色を準備しています。
	[self.sourceMonochromeView.backgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
	
	// 複数のコンテキストが存在するときは、別のところでコンテキストを変更されると正しく動作しなくなるので、冒頭でコンテキストを選択しておきます。
	[EAGLContext setCurrentContext:mpGLContext];
		
	// レンダバッファの描画メモリとしてレイヤーを割り当てます。
	[mpGLContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
	
	// ここまできたら、フレームバッファが正しく設定されたかチェックします。
	NSAssert1((glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE), @"Invalid framebuffer. (status=%x)", glCheckFramebufferStatus(GL_FRAMEBUFFER));
	
	// レンダーバッファーの幅と高さを取得します。
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &bufferWidth); EzOpenGLESAssert;
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &bufferHeight); EzOpenGLESAssert;

	// レンダリングした画像を表示する領域を、左下が原点の座標系で指定します。今回は画像サイズと同じにしています。ビューのサイズにすると、ビュー全体に引き延ばされて描画されます。
	// 座標系を変換する glOrthof は OpenGL ES 2.0 では使えないようでした。
	glViewport(0.0, 0.0, imageWidth, imageHeight); EzOpenGLESAssert;
	
	[self build];
}

- (void)build
{
	// 複数のコンテキストを使う場合、違うコンテキストが選択されている場合があるので、目的のコンテキストを設定し直します。
	[EAGLContext setCurrentContext:mpGLContext];
	
	// フラグメントシェーダーのコードを準備します。
	const char* fCode = ""
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
	
	// 頂点シェーダーも用意します。フラグメントシェーダーにテクスチャの値を渡すために必要です。
	const char* vCode = ""
	"attribute vec2 a_position;\n"
	"attribute vec2 a_texCoord;\n"
	"uniform mat4 u_matrix;\n"
	"varying vec2 v_texCoord;\n"
	"void main(void){\n"
	"	gl_Position = u_matrix * vec4(a_position, 0.0, 1.0);\n"
	"	v_texCoord = a_texCoord;\n"
	"}\n";
	
	GLint compiled;
	
	// 頂点シェーダーを生成します。
	GLuint vShader = glCreateShader(GL_VERTEX_SHADER); EzOpenGLESAssert;
	NSAssert(vShader != GL_FALSE, @"Failed to create a vertex shader.");
	
	glShaderSource(vShader, 1, &vCode, NULL); EzOpenGLESAssert;
	glCompileShader(vShader); EzOpenGLESAssert;

	glGetShaderiv(vShader, GL_COMPILE_STATUS, &compiled);
	
	if (!compiled)
	{
		EzOpenGLESShaderCompileAssert(vShader);
	}
	
	// フラグメントシェーダーを生成します。
	GLuint fShader = glCreateShader(GL_FRAGMENT_SHADER); EzOpenGLESAssert;
	NSAssert(fShader != GL_FALSE, @"Failed to create a fragment shader.");
	
	glShaderSource(fShader, 1, &fCode, NULL); EzOpenGLESAssert;
	glCompileShader(fShader); EzOpenGLESAssert;
	
	glGetShaderiv(fShader, GL_COMPILE_STATUS, &compiled);
	
	if (!compiled)
	{
		EzOpenGLESShaderCompileAssert(vShader);
	}
	
	// プログラムを構築します。
	program = glCreateProgram();
	
	// プログラムにシェーダーを関連づけます。
	glAttachShader(program, fShader); EzOpenGLESAssert;
	glAttachShader(program, vShader); EzOpenGLESAssert;
		
	// 頂点シェーダーの attribute 番号に変数名を割り当てます。
	glBindAttribLocation(program, 0, "a_position"); EzOpenGLESAssert;
	glBindAttribLocation(program, 1, "a_texCoord"); EzOpenGLESAssert;
	
	// 関連づけたシェーダーをリンクします。
	glLinkProgram(program); EzOpenGLESAssert;
	
	// リンクに成功したかを調べます。
	GLint linked;
	
	glGetProgramiv(program, GL_LINK_STATUS, &linked);
	
	if (!linked)
	{
		GLint infoLogLength=0;

		glGetProgramiv(program, GL_INFO_LOG_LENGTH, &infoLogLength);
		
		if (infoLogLength > 0)
		{
			char* infoLog = (char*)malloc(sizeof(char)*infoLogLength);
			glGetProgramInfoLog(program, infoLogLength, NULL, infoLog);
			
			NSAssert1(false, @"Link error: %s", infoLog);
			free(infoLog);
		}
		else
		{
			NSAssert(false, @"Unknown link error.");
		}
	}
	
	// リンクに成功したら、シェーダーは不要になるようなので、デタッチして削除します。
	glDetachShader(program, fShader); EzOpenGLESAssert;
	glDeleteShader(fShader); EzOpenGLESAssert;
	
	glDetachShader(program, vShader); EzOpenGLESAssert;
	glDeleteShader(vShader); EzOpenGLESAssert;
	
	// シェーダーで宣言したユニフォーム変数の値を格納するための ID を取得します。
	u_texture = glGetUniformLocation(program, "u_texture");
	NSAssert(u_texture != -1, @"Uniform variable 'u_texture' was not found.");
	
	u_color = glGetUniformLocation(program, "u_color");
	NSAssert(u_color != -1, @"Uniform variable 'u_color' was not found.");
		
	u_matrix = glGetUniformLocation(program, "u_matrix");
	NSAssert(u_matrix != -1, @"Uniform variable 'u_matrix' was not found.");
	
	
	[self draw];
}

- (void)draw
{
	// 複数のコンテキストを使う場合、違うコンテキストが選択されている場合があるので、目的のコンテキストを設定し直します。
	[EAGLContext setCurrentContext:mpGLContext];
	
	// レンダーバッファーを透明で初期化します。iOS シミュレーターだとノイズが入るようでした。
	glClearColor(0.0, 0.0, 0.0, 0.0); EzOpenGLESAssert;
	glClear(GL_COLOR_BUFFER_BIT); EzOpenGLESAssert;

	// 扱うサイズは画像サイズにすることにします。
	CGFloat width = imageWidth;
	CGFloat height = imageHeight;
	
	// 頂点シェーダーの 4 頂点を準備します。今回は画像と同じサイズの正方形を用意していることになっているはずです。
	GLKVector2 positions[4] =
	{
		{ 0.0, 		0.0	 	},
		{ width, 	0.0 	},
		{ 0.0,		height	},
		{ width,	height	}
	};
		
	// テクスチャを設定する座標は全体にぴったり貼るという指定になっているでしょうか。
	GLKVector2 texCoords[4] =
	{
		{ 0.0,		0.0 	},
		{ 1.0,		0.0 	},
		{ 0.0,		1.0 	},
		{ 1.0,		1.0 	}
	};
		
	// テクスチャの画像データを準備します。
	size_t imageBytesPerRow = CGImageGetBytesPerRow(imageRef);
	size_t imageBitsPerComponent = CGImageGetBitsPerComponent(imageRef);
	CGColorSpaceRef imageColorSpace = CGImageGetColorSpace(imageRef);

	size_t imageTotalBytes = imageBytesPerRow * imageHeight;
	Byte* imageData = (Byte*)malloc(imageTotalBytes);

	// バッファを初期化しないと、読み込んだ画像の透明部分にノイズが入る様子なので初期化しています。iOS シミュレーターだけかもしれません。
	memset(imageData, 0, imageTotalBytes);

	// テクスチャ画像と同じサイズのビットマップコンテキストを構築します。
	CGContextRef memContext = CGBitmapContextCreate(imageData, imageWidth, imageHeight, imageBitsPerComponent, imageBytesPerRow, imageColorSpace, kCGImageAlphaPremultipliedLast);

	// ビットマップコンテキストに画像を描画すると、コンテキスト構築時に指定したデータバッファーに描画されます。
	CGContextDrawImage(memContext, CGRectMake(0.0f, 0.0f, (CGFloat)imageWidth, (CGFloat)imageHeight), imageRef);

	// データバッファーに描画できたら、コンテキストは不要になります。
	CGContextRelease(memContext);
	
	
	// テクスチャ 0 を有効化します。
	glActiveTexture(GL_TEXTURE0); EzOpenGLESAssert;
	
	// テクスチャを 1 つ生成してバインドします。
	glGenTextures(1, &texture); EzOpenGLESAssert;
	glBindTexture(GL_TEXTURE_2D, texture); EzOpenGLESAssert;
	
	// メモリを参照するときのアドレス境界の数を 1, 2, 4, 8 で指定します。今回は 1 を指定していますが、RGBA の 4 バイト構成なら 4 を指定すると最適になるそうです。
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1); EzOpenGLESAssert;
	
	// テクスチャにテクスチャ画像を割り当てます。
	// param1: テクスチャの種類です。必ず GL_TEXTURE_2D になるようです。
	// param2: ミップマップを行う場合のテクスチャの解像度レベルだそうです。MIPMAP を使用しない場合は 0 を指定します。
	// param3: 内部で保持するテクスチャの形式を指定します。
	// param4: テクスチャの幅です。
	// param5: テクスチャの高さです。
	// param6: テクスチャの境界線の太さを指定するのだそうです。
	// param7: 画像データ (imageData) の画像形式を指定します。
	// param8: 画像データ (imageData) のデータ型を指定します。
	// param9: テクスチャに割り当てる画像データです。
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imageWidth, imageHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData); EzOpenGLESAssert;
	
	// テクスチャサイズが 2 の累乗であればミップマップを作成できます。ミップマップを使うときれいになるようです。GL_TEXTURE_MIN_FILTER で GL_LINEAR_MIPMAP_LINEAR するためには必要です。
//	glGenerateMipmap(GL_TEXTURE_2D); EzOpenGLESAssert;
	
	// テクスチャを準備できたら、画像データは不要になります。
	free(imageData);
	
	
	// シェーダーを使用するために、プログラムを使います。
	glUseProgram(program); EzOpenGLESAssert;
	
	// アルファブレンドを有効にして、透明色を透過させるようにします。
	glEnable(GL_BLEND); EzOpenGLESAssert;
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); EzOpenGLESAssert;
	
	
	// テクスチャの横 (GL_TEXTURE_WRAP_S) と縦 (GL_TEXTURE_WRAP_T) のリピート方法を指定します。
	// GL_REPEAT は繰り返し適用で、2 の累乗のテクスチャサイズのときに使えるらしいです。淵を延々と延ばす場合は GL_CLAMP_TO_EDGE を指定するそうです。
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE); EzOpenGLESAssert;
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE); EzOpenGLESAssert;

	// 拡大 (GL_TEXTURE_MAG_FILTER) 縮小 (GL_TEXTURE_MIN_FILTER) 時の補完指定を行います。指定しないと正しく表示されないか荒くなるようでrす。
	// GL_NEAREST=最近傍法, GL_LINEAR=双線形補完
	// 縮小の場合で、ミップマップが有効なときは次のものも選べます。
	// GL_NEAREST_MIPMAP_NEAREST, GL_LINEAR_MIPMAP_NEAREST, GL_NEAREST_MIPMAP_LINEAR, GL_LINEAR_MIPMAP_LINEAR
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); EzOpenGLESAssert;
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); EzOpenGLESAssert;
	
	

	// アトリビュート 0 番の値を設定します。 (glBindAttribLocation で "a_position" を 0 に割り当てています）
	glEnableVertexAttribArray(0); EzOpenGLESAssert;
	glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, positions); EzOpenGLESAssert;
	
	// アトリビュート 1 番の値を設定します。 (glBindAttribLocation で "a_texCoord" を 0 に割り当てています）
	glEnableVertexAttribArray(1); EzOpenGLESAssert;
	glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 0, texCoords); EzOpenGLESAssert;
	
	
	// ユニフォーム変数 u_texture に 0 番のテクスチャを設定します。
	glUniform1i(u_texture, 0); EzOpenGLESAssert;

	// ユニフォーム変数 u_color に、今回はモノトーン変換で使用する色情報を渡します。
	glUniform4f(u_color, red, green, blue, alpha); EzOpenGLESAssert;

	// ユニフォーム変数 u_matrix に、平行投影変換の写像を渡します。
	
	// 視野空間の中心が原点になるように、-width / 2.0 平行移動して、大きさを 2 / width 倍します。つまり -1.0 から 1.0 の座標系にします。y, z についても同様です。
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
	
	GLfloat matrix[16] =
	{
		 2.0f / width,	 0.0f,				0.0f,	0.0f,
		 0.0f,			-2.0f / height, 	0.0f,	0.0f,
		 0.0f,			 0.0f,				1.0f,	0.0f,
		-1.0f,			 1.0f,				0.0f,	1.0f
	};
	
	glUniformMatrix4fv(u_matrix, 1, GL_FALSE, matrix); EzOpenGLESAssert;
	
	// glVertexPointer で用意した頂点 4 つをレンダーバッファー描画します。
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4); EzOpenGLESAssert;

	// レンダーバッファーへの描画が終わったら、ブレンド設定などはリセットしてもよくなります。
	glDisable(GL_BLEND); EzOpenGLESAssert;
	
	// これまでの描画を全て実行することを命令します。なくても大丈夫そうです。
	glFlush(); EzOpenGLESAssert;
		
	// レンダーバッファーに描画した内容を画面に描画します。
	[mpGLContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)dealloc
{
	NSLog(@"Dealloc Begin: %p", self);
	
	NSLog(@"Finalize Begin: %p", self);
	
	// コンテキストを無効化します。
	[EAGLContext setCurrentContext:nil];
	
	mpGLContext = nil;
	
	// glCreate 系や glGen 系の関数で作成したオブジェクトは要らなくなったら削除します。
	glDeleteProgram(program); EzOpenGLESAssert;
	glDeleteTextures(1, &texture); EzOpenGLESAssert;
	glDeleteFramebuffers(1,&mFrameBuffer); EzOpenGLESAssert;
	glDeleteRenderbuffers(1, &mColorBuffer); EzOpenGLESAssert;
	
	NSLog(@"Finalize End: %p", self);
	
	NSLog(@"Dealloc End: %p", self);
}

@end
