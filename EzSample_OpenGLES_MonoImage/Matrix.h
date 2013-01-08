//  Created by 神谷 栄治 on 12/05/16.
//  Copyright (c) 2012年 株式会社アイビス. All rights reserved.

#ifndef __MATRIX_H__
#define __MATRIX_H__

#import "EzMonoImage.h"

//float型3x3行列
class Matrix {
	friend class Vector;
public:
	float element[3][3];

public:
	//コンストラクタ
	Matrix();
	//コピーコンストラクタ
	Matrix(const Matrix& mtrx);
	//デストラクタ
	virtual ~Matrix(){}
	//要素の取得
	float getElement(int row, int col) const {
		assert(0<=row && row<3);
		assert(0<=col && col<3);
		return element[row][col];
	}
	//要素の設定
	void setElement(int row, int col, float val){
		assert(0<=row && row<3);
		assert(0<=col && col<3);
		element[row][col] = val;
	}
	//要素の取得
	float operator()(int row, int col){
		return getElement(row,col);
	}
	//比較
	bool operator==(const Matrix& mtrx) const;
	//比較（NOT）
	bool operator!=(const Matrix& mtrx) const;
	//代入
	Matrix& operator=(const Matrix& mtrx);
	//乗算
	Matrix operator*(const Matrix& mtrx) const;
	//乗算（代入）
	Matrix& operator*=(const Matrix& mtrx){
		return *this=(*this)*mtrx;
	}
	//加算
	Matrix operator+(const Matrix& mtrx) const;
	//加算（代入）
	Matrix& operator+=(const Matrix& mtrx){
		return *this=(*this)+mtrx;
	}
	//減算
	Matrix operator-(const Matrix& mtrx) const;
	//減算（代入）
	Matrix& operator-=(const Matrix& mtrx){
		return *this=(*this)-mtrx;
	}
	//ベクトルとの乗算
	Vector operator*(const Vector& mtrx) const;
	//単位ベクトル化
	Matrix& setUnit();
	//単位ベクトルか？
	bool IsUnit() const;

	//Z軸周りに回転（角度はdegree）
	Matrix& addZRotation(float rot);
	//Z軸周りの回転行列（角度はdegree）
	Matrix& setZRotation(float rot);
	//平行移動
	Matrix& addTranslation(float x, float y);
	//平行移動
	Matrix& addTranslation(const Vector& v){
		return addTranslation(v.x,v.y);
	}
	//平行移動行列
	Matrix& setTranslation(float x, float y);
	//平行移動行列
	Matrix& setTranslation(const Vector& v){
		return setTranslation(v.x,v.y);
	}
	//拡大縮小（各軸方向ごと倍率）
	Matrix& addScale(float x, float y);
	//拡大縮小（各軸方向ごと倍率）
	Matrix& addScale(const Vector& v){
		return addScale(v.x,v.y);
	}
	//拡大縮小（全軸共通倍率）
	Matrix& addScale(float val){
		return addScale(val,val);
	}
	//拡大縮小行列（各軸方向ごと倍率）
	Matrix& setScale(float x, float y);
	//拡大縮小行列（各軸方向ごと倍率）
	Matrix& setScale(const Vector& v){
		return setScale(v.x,v.y);
	}
	//拡大縮小行列（全軸共通倍率）
	Matrix& setScale(float val){
		return setScale(val,val);
	}
	//逆行列化
	Matrix& inverse();
	//行列式
	float det();
	//４次元行列化してカラムごとにもらう
	void getVec4(int column, float* dataOut);
	//4x4行列に展開する
	void getMat4(float dataOut[16]);
};

#endif
