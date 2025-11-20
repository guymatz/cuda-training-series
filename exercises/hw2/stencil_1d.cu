#include <stdio.h>
#include <algorithm>
#include <math.h>
#include "utils.cuh"

using namespace std;

//#define N 1024
#define N 16
#define RADIUS 1
#define BLOCK_SIZE 16

__global__ void stencil_1d(int *in, int *out) {
    __shared__ int temp[2 * RADIUS + 1];
    int gindex = threadIdx.x + blockIdx.x * blockDim.x;
    int lindex = threadIdx.x + RADIUS;
	printf("Here %i %i %i %i\n", gindex, lindex, threadIdx.x, RADIUS);

    // Read input elements into shared memory
	printf("Setting temp[%i] to in[%i] = %i\n", lindex, gindex, in[gindex]);
    temp[lindex] = in[gindex];
	printf("before IF\n");
    if (threadIdx.x < RADIUS) {
	  printf("Setting %i to %i\n", lindex-RADIUS, in[gindex-RADIUS]);;
      temp[lindex - RADIUS] = in[gindex - RADIUS];
	  printf("Setting %i to %i\n", lindex+BLOCK_SIZE, in[gindex+BLOCK_SIZE]);;
      temp[lindex + BLOCK_SIZE] = in[gindex + BLOCK_SIZE];
    }

    // Synchronize (ensure all the data is available)
    __syncthreads();
	printf("AFTER syncthreads\n");

    // Apply the stencil
    int result = 0;
    for (int offset = -RADIUS; offset <= RADIUS; offset++) {
		printf("here: %i\n", temp[offset]);
      result += temp[offset];
	}

    // Store the result
    out[gindex] = result;
}

void fill_ints(int *x, int n) {
  //fill_n(x, n, 1);
  for (int i = 0; i < n; i++) {
	  x[i] = 1;
  }
}

int main(void) {
  int *in, *out; // host copies of a, b, c
  int *d_in, *d_out; // device copies of a, b, c

  // Alloc space for host copies and setup values
  int size = (N + 2*RADIUS) * sizeof(int);
  in = (int *)malloc(size); fill_ints(in, N + 2*RADIUS);
  out = (int *)malloc(size); fill_ints(out, N + 2*RADIUS);
  //printf("in:\n");
  //print_matrix(in, (N+2*RADIUS));
  //printf("out before:\n");
  //print_matrix(out, (N+2*RADIUS));

  // Alloc space for device copies
  cudaMalloc((void **)&d_in, size);
  cudaMalloc((void **)&d_out, size);

  // Copy to device
  cudaMemcpy(d_in, in, size, cudaMemcpyHostToDevice);
  cudaMemcpy(d_out, out, size, cudaMemcpyHostToDevice);

  // Launch stencil_1d() kernel on GPU
  stencil_1d<<<ceil((float)N/BLOCK_SIZE),BLOCK_SIZE>>>(in, out);

  // Copy result back to host
  cudaMemcpy(out, d_out, size, cudaMemcpyDeviceToHost);
  //printf("out after:\n");
  //print_matrix(out, N);
  /*
  return 1;

  // Error Checking
  for (int i = 0; i < N + 2*RADIUS; i++) {
    if (i<RADIUS || i>=N+RADIUS){
      if (out[i] != 1)
    	printf("Mismatch at index %d, was: %d, should be: %d\n", i, out[i], 1);
    } else {
      if (out[i] != 1 + 2*RADIUS)
    	printf("Mismatch at index %d, was: %d, should be: %d\n", i, out[i], 1 + 2*RADIUS);
    }
  }
 */
  // Cleanup
  free(in); free(out);
  cudaFree(d_in); cudaFree(d_out);
  printf("Success!\n");
  return 0;
}
