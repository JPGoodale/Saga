#version 450

layout (local_size_x = 16, local_size_y = 16) in;

layout (std430, binding = 0) writeonly buffer MatrixC {
    float C[];
};

layout (std430, binding = 1) readonly buffer MatrixA {
    float A[];
};

layout (std430, binding = 2) readonly buffer MatrixB {
    float B[];
};


uniform int M;  // Rows of A
uniform int N;  // Columns of B
uniform int K;  // Columns of A / Rows of B

shared float As[16][16];
shared float Bs[16][16];

void main() {
    ivec2 globalId = ivec2(gl_GlobalInvocationID.xy);
    ivec2 localId = ivec2(gl_LocalInvocationID.xy);
    
    if (globalId.x >= N || globalId.y >= M) return;
    
    float sum = 0.0;
    
    for (int tile = 0; tile < K; tile += 16) {
        // Load data into shared memory
        if (tile + localId.x < K && globalId.y < M)
            As[localId.y][localId.x] = A[globalId.y * K + tile + localId.x];
        else
            As[localId.y][localId.x] = 0.0;
        
        if (tile + localId.y < K && globalId.x < N)
            Bs[localId.y][localId.x] = B[(tile + localId.y) * N + globalId.x];
        else
            Bs[localId.y][localId.x] = 0.0;
        
        barrier();
        
        // Compute partial dot product
        for (int k = 0; k < 16; ++k) {
            sum += As[localId.y][k] * Bs[k][localId.x];
        }
        
        barrier();
    }
    
    if (globalId.x < N && globalId.y < M)
        C[globalId.y * N + globalId.x] = sum;
}
