#version 450

layout(local_size_x = 256) in;

// Input buffers
layout(std430, binding = 0) readonly buffer XBuffer {
    float x[];
};

layout(std430, binding = 1) readonly buffer WBuffer {
    float w[];
};

// Output buffer
layout(std430, binding = 2) writeonly buffer ResultBuffer {
    float result[];
};

layout(push_constant) uniform PushConstants {
    uint size;
};

void main() {
    uint id = gl_GlobalInvocationID.x;
    
    if (id < size) {
        result[id] = x[id] * w[id];
    }
}
