#version 450

layout(local_size_x = 16, local_size_y = 1, local_size_z = 1) in;

layout(set = 0, binding = 0) buffer InputBuffer {
    float inputData[];
};

layout(set = 0, binding = 1) buffer OutputBuffer {
    float outputData[];
};

layout(push_constant) uniform PushConstants {
    uint vectorSize;
};

void main() {
    uint gID = gl_GlobalInvocationID.x;
    
    if (gID >= vectorSize) {
        return;
    }

    // Find the maximum value in the vector
    float maxVal = inputData[0];
    for (uint i = 1; i < vectorSize; ++i) {
        maxVal = max(maxVal, inputData[i]);
    }

    // Calculate exp(x - max) for numerical stability and sum
    float sum = 0.0;
    for (uint i = 0; i < vectorSize; ++i) {
        float expVal = exp(inputData[i] - maxVal);
        sum += expVal;
        outputData[i] = expVal;  // Store intermediate result
    }

    // Normalize to get softmax probabilities
    for (uint i = 0; i < vectorSize; ++i) {
        outputData[i] /= sum;
    }
}
