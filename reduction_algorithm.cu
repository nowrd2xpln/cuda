#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <assert.h>
//#include "benchmark.h"

//Macros
#define min(a, b) ( (a)<(b)? (a): (b) )
#define max(a, b) ( (a)>(b)? (a): (b) )

//Constants
#define MAX_VECTOR_COUNT 5

//Vector structure
typedef struct {
	float e[3];
}Vec3f;

//Global array
Vec3f vecArray[MAX_VECTOR_COUNT];
Vec3f newvecArray[MAX_VECTOR_COUNT];

//forward declarations
__global__ void reduce(Vec3f *input, Vec3f *output);

int 
main(int argc, char** argv){

	vecArray[0].e[0] =   1.0; vecArray[0].e[1] =   2.0; vecArray[0].e[2] =   3.0;
	vecArray[1].e[0] =   4.0; vecArray[1].e[1] =   5.0; vecArray[1].e[2] =   6.0;
	vecArray[2].e[0] =   7.0; vecArray[2].e[1] =   8.0; vecArray[2].e[2] =   9.0;
	vecArray[3].e[0] =  10.0; vecArray[3].e[1] =  11.0; vecArray[3].e[2] =  12.0;
	vecArray[4].e[0] =  13.0; vecArray[4].e[1] =  14.0; vecArray[4].e[2] =  15.0;
	// NOTE:  the data being operated on are Vec3f's and frange from 0 (black) to 10ish for each rgb.  
	//I think they are the intesities.

	//--------------------------------------------------------------------------------
	//allocate device mem
	Vec3f *ddata, *dbuffer;

	cudaMalloc( &ddata,     MAX_VECTOR_COUNT * sizeof(Vec3f) );
	cudaMalloc( &dbuffer,   MAX_VECTOR_COUNT * sizeof(Vec3f) );   
	cudaMemset( dbuffer, 0, MAX_VECTOR_COUNT * sizeof(Vec3f) );    

	cudaMemcpy( ddata, vecArray, MAX_VECTOR_COUNT * sizeof(Vec3f), cudaMemcpyHostToDevice );

	dim3 gridDim(1,1);
	dim3 blockDim(5,1);

	//Check verArray values going into kernel function
	for (int i = 0 ; i < 5 ; i++){
		for (int j = 0 ; j < 3 ; j ++)
	        	printf("vecArray[%d][%d] = %.3f\n", j,i,vecArray[i].e[j]);
    	}
	printf("\n\n");

	//call the reduction function
	reduce<<< gridDim, blockDim >>> ( ddata, dbuffer );

	//ZERO out newvecArray
    	memset(newvecArray, 0, MAX_VECTOR_COUNT * sizeof(Vec3f));
	cudaMemcpy( newvecArray, dbuffer, MAX_VECTOR_COUNT * sizeof(Vec3f), cudaMemcpyDeviceToHost );
	//Check to see if copied over to newvecArry

	//Check to see if copied over to newvecArry
	printf("Check to see if copied over to newvecArry\n");
	for (int i = 0 ; i < 5 ; i++){
		for (int j = 0 ; j < 3 ; j ++)
	        	printf("newvecArray[%d][%d] = %.3f\n", j,i,newvecArray[i].e[j]);
    	}

	//free device mem
	cudaFree( &ddata );

	//--------------------------------------------------------------------------------
	return 0;
}

__global__ void 
reduce(Vec3f *input, Vec3f *output){
	extern __shared__ Vec3f sdata[];

	// each thread loadsome element from global to shared mem
	unsigned int tid = threadIdx.x;
	unsigned int i   = threadIdx.x + blockIdx.x * blockDim.x;
	sdata[tid] = input[i];
	__syncthreads();

	//perform reduction in shared mem
	for(unsigned int s=1; s < blockDim.x; s *= 2) {
		//int s = 2;
		if(tid % (2*s) == 0){

			sdata[tid].e[0] += sdata[tid + s].e[0];	//summing
			sdata[tid].e[1] += sdata[tid + s].e[1];
			sdata[tid].e[2] += sdata[tid + s].e[2];
/*
			sdata[tid].e[0] = min( sdata[tid].e[0], sdata[tid + s].e[0] );	//min
			sdata[tid].e[1] = min( sdata[tid].e[1], sdata[tid + s].e[1] );
			sdata[tid].e[2] = min( sdata[tid].e[2], sdata[tid + s].e[2] );

			sdata[tid].e[0] = max( sdata[tid].e[0], sdata[tid + s].e[0] );	//max
			sdata[tid].e[1] = max( sdata[tid].e[1], sdata[tid + s].e[1] );
			sdata[tid].e[2] = max( sdata[tid].e[2], sdata[tid + s].e[2] );
*/
		}
		__syncthreads();
	}

	// write result for this block to global mem
	if(tid == 0) output[blockIdx.x] = sdata[0];
}
