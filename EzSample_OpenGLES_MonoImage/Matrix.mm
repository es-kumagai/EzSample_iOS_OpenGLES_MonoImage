//  Created by 神谷 栄治 on 12/05/16.
//  Copyright (c) 2012年 株式会社アイビス. All rights reserved.
#import <string>

#import "Matrix.h"

//コンストラクタ
Matrix::Matrix() {
	for(int col=0; col<3; col++){
		for(int row=0; row<3; row++){
			if(row==col){
				element[row][col] = float(1.0);
			}
			else{
				element[row][col] = float(0.0);
			}
		}
	}
}

//コピーコンストラクタ
Matrix::Matrix(const Matrix& mtrx)
{
	*this = mtrx;
}

//行列xベクトル
Vector Matrix::operator*(const Vector& vect) const
{
	Vector	vctr;
	for(int i=0; i<2; i++){
		float	val = 0.f;		
		for(int j=0; j<3; j++){
			if (j==2) {
				val += element[i][j];
			}else {
				val += element[i][j] * vect.element[j];
			}
		}
		if (i<2) {
			vctr.element[i] = val;
		}
	}
	return vctr;
}

//単位行列化
Matrix& Matrix::setUnit()
{
	for(int i=0; i<3; i++){
		for(int j=0; j<3; j++){
			if(j==i){
				element[j][i] = float(1.0);
			}
			else{
				element[j][i] = float(0.0);
			}
		}
	}

	return *this;
}

//単位行列か？
bool Matrix::IsUnit() const
{
	for(int i=0; i<3; i++){
		for(int j=0; j<3; j++){
			if(
				(j==i && element[j][i]!=float(1.0)) ||
				 (j!=i && element[j][i]!=float(0.0))){

				return false;
			}
		}
	}
	return true;
}

Matrix& Matrix::addZRotation(float rot)//角度はdegree
{
	rot = Deg2Rad(rot);
	float	nSin = sinf(rot),
			nCos = cosf(rot);

	float	rTemp00 = element[0][0]*nCos - element[1][0]*nSin,
			rTemp10 = element[0][0]*nSin + element[1][0]*nCos,

			rTemp01 = element[0][1]*nCos - element[1][1]*nSin,
			rTemp11 = element[0][1]*nSin + element[1][1]*nCos,

			rTemp02 = element[0][2]*nCos - element[1][2]*nSin,
			rTemp12 = element[0][2]*nSin + element[1][2]*nCos;

	element[0][0] = rTemp00;
	element[1][0] = rTemp10;

	element[0][1] = rTemp01;
	element[1][1] = rTemp11;

	element[0][2] = rTemp02;
	element[1][2] = rTemp12;
	
	return *this;
}

Matrix& Matrix::setZRotation(float rot)//角度はdegree
{
	rot = Deg2Rad(rot);
	float	nSin = sinf(rot),
			nCos = cosf(rot);

	element[0][0] = nCos;
	element[1][0] = nSin;
	element[2][0] = float(0.0);

	element[0][1] = -nSin;
	element[1][1] = nCos;
	element[2][1] = float(0.0);

	element[0][2] = float(0.0);
	element[1][2] = float(0.0);
	element[2][2] = float(1.0);

	return *this;
}

Matrix& Matrix::addTranslation(float x, float y)
{
	float	rTemp00 = element[0][0] + element[2][0] * x,
			rTemp10 = element[1][0] + element[2][0] * y,
			rTemp20 = element[2][0],

			rTemp01 = element[0][1] + element[2][1] * x,
			rTemp11 = element[1][1] + element[2][1] * y,
			rTemp21 = element[2][1],

			rTemp02 = element[0][2] + element[2][2] * x,
			rTemp12 = element[1][2] + element[2][2] * y,
			rTemp22 = element[2][2];

	element[0][0] = rTemp00;
	element[1][0] = rTemp10;
	element[2][0] = rTemp20;

	element[0][1] = rTemp01;
	element[1][1] = rTemp11;
	element[2][1] = rTemp21;

	element[0][2] = rTemp02;
	element[1][2] = rTemp12;
	element[2][2] = rTemp22;

	return *this;
}

Matrix& Matrix::setTranslation(float x, float y)
{
	element[0][0] = float(1.0);
	element[1][0] = float(0.0);
	element[2][0] = float(0.0);

	element[0][1] = float(0.0);
	element[1][1] = float(1.0);
	element[2][1] = float(0.0);

	element[0][2] = x;
	element[1][2] = y;
	element[2][2] = float(1.0);

	return *this;
}

Matrix& Matrix::addScale(float x, float y)
{
	float	rTemp00 = element[0][0] * x,
			rTemp10 = element[1][0] * y,
			
			rTemp01 = element[0][1] * x,
			rTemp11 = element[1][1] * y,

			rTemp02 = element[0][2] * x,
			rTemp12 = element[1][2] * y;

	element[0][0] = rTemp00;
	element[1][0] = rTemp10;

	element[0][1] = rTemp01;
	element[1][1] = rTemp11;

	element[0][2] = rTemp02;
	element[1][2] = rTemp12;

	return *this;
}

Matrix& Matrix::setScale(float x, float y)
{
	element[0][0] = x;
	element[1][0] = float(0.0);
	element[2][0] = float(0.0);

	element[0][1] = float(0.0);
	element[1][1] = y;
	element[2][1] = float(0.0);

	element[0][2] = float(0.0);
	element[1][2] = float(0.0);
	element[2][2] = float(1.0);

	return *this;
}

//行列式
float Matrix::det()
{
	return element[0][0]*(element[1][1]*element[2][2]-element[1][2]*element[2][1])
			-element[0][1]*(element[1][0]*element[2][2]-element[1][2]*element[2][0])
			+element[0][2]*(element[1][0]*element[2][1]-element[1][1]*element[2][0]);
}

Matrix& Matrix::inverse()
{
	Matrix	mtrx;
	float detf = det();
	if (detf == 0.f) {
		return *this;
	}
	mtrx.element[0][0] = (element[1][1]*element[2][2]-element[1][2]*element[2][1])/detf;
	mtrx.element[1][0] = (element[1][2]*element[2][0]-element[1][0]*element[2][2])/detf;
	mtrx.element[2][0] = (element[1][0]*element[2][1]-element[1][1]*element[2][0])/detf;
	
	mtrx.element[0][1] = (element[0][2]*element[2][1]-element[0][1]*element[2][2])/detf;
	mtrx.element[1][1] = (element[0][0]*element[2][2]-element[0][2]*element[2][0])/detf;
	mtrx.element[2][1] = (element[0][1]*element[2][0]-element[0][0]*element[2][1])/detf;
	
	mtrx.element[0][2] = (element[0][1]*element[1][2]-element[0][2]*element[1][1])/detf;
	mtrx.element[1][2] = (element[0][2]*element[1][0]-element[0][0]*element[1][2])/detf;
	mtrx.element[2][2] = (element[0][0]*element[1][1]-element[0][1]*element[1][0])/detf;

	return (*this = mtrx);
}

Matrix& Matrix::operator=(const Matrix& mtrx)
{
	memcpy((void*)element, (void*)mtrx.element, sizeof element);
	return *this;
}

bool Matrix::operator==(const Matrix& mtrx) const
{
	for(int col=0; col<3; col++){
		for(int row=0; row<3; row++){
			if(element[row][col]!=mtrx.element[row][col]){
				return false;
			}
		}
	}
	return true;
}

bool Matrix::operator!=(const Matrix& mtrx) const
{
	return !((*this)==mtrx);
}

Matrix Matrix::operator*(const Matrix& mtrx) const
{
	Matrix	mtrxResult;

	for(int i=0; i<3; i++){
		for(int j=0; j<3; j++){
			float	val = float(0.0);
			
			for(int k=0; k<3; k++){
				val +=
					element[i][k] *
					mtrx.element[k][j];
			}

			mtrxResult.element[i][j] = val;
		}
	}
	
	return mtrxResult;
}

Matrix Matrix::operator+(const Matrix& mtrx) const
{
	Matrix	mtrxResult;
	
	for(int i=0; i<3; i++){
		for(int j=0; j<3; j++){
			mtrxResult.element[i][j]
				= element[i][j] + mtrx.element[i][j];
		}
	}
	return mtrxResult;
}

Matrix Matrix::operator-(const Matrix& mtrx) const
{
	Matrix	mtrxResult;
	
	for(int i=0; i<3; i++){
		for(int j=0; j<3; j++){
			mtrxResult.element[i][j]
			= element[i][j] - mtrx.element[i][j];
		}
	}
	return mtrxResult;
}

//４次元行列化してカラムごとにもらう
void Matrix::getVec4(int column, float* dataOut) {
	if (column == 2) {
		dataOut[0] = dataOut[1] = dataOut[3] = 0.f;
		dataOut[2] = 1.f;
		return;
	}
	if (column > 2) {
		column = 2;
	}
	dataOut[0] = element[0][column];
	dataOut[1] = element[1][column];
	dataOut[2] = 0.f;
	dataOut[3] = element[2][column];
}

//4x4行列に展開する
void Matrix::getMat4(float dataOut[16]) {
	//col=0
	dataOut[0] = element[0][0];
	dataOut[1] = element[1][0];
	dataOut[2] = 0.f;
	dataOut[3] = element[2][0];	
	//col=1
	dataOut[4] = element[0][1];
	dataOut[5] = element[1][1];
	dataOut[6] = 0.f;
	dataOut[7] = element[2][1];	
	//col=2
	dataOut[8] = 0.f;
	dataOut[9] = 0.f;
	dataOut[10] = 1.f;
	dataOut[11] = 0.f;	
	//col=3
	dataOut[12] = element[0][2];
	dataOut[13] = element[1][2];
	dataOut[14] = 0.f;
	dataOut[15] = element[2][2];	
}
