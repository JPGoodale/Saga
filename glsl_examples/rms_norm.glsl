#version 450
#extension GL_KHR_shader_subgroup_arithmetic : enable

layout(local_size_x = 256) in;

layout(set = 0, binding = 0) buffer OutputBuffer {
    float output_data[];
};

layout(set = 0, binding = 1) buffer InputBuffer {
    float input_data[];
};

layout(set = 0, binding = 2) buffer WeightBuffer {
    float weight[];
};

layout(push_constant) uniform PushConstants {
    int N;
};

shared float shared_sum[32];

void main() {
    uint global_id = gl_GlobalInvocationID.x;
    uint local_id = gl_LocalInvocationID.x;
    uint warp_id = local_id / 32;
    uint lane_id = local_id % 32;

    float thread_sum = 0.0;
    for (int i = int(global_id); i < N; i += int(gl_WorkGroupSize.x * gl_NumWorkGroups.x)) {
        thread_sum += input_data[i] * input_data[i];
    }

    float warp_sum = subgroupAdd(thread_sum);
    if (subgroupElect()) {
        shared_sum[warp_id] = warp_sum;
    }
    barrier();

    if (lane_id < 32) {
        float block_sum = (warp_id < gl_WorkGroupSize.x / 32) ? shared_sum[lane_id] : 0.0;
        block_sum = subgroupAdd(block_sum);
        if (subgroupElect()) {
            block_sum /= float(N);
            block_sum += 1e-5;
            block_sum = inversesqrt(block_sum);
            shared_sum[0] = block_sum;
        }
    }
    barrier();

    float squared_sum = shared_sum[0];
    for (int i = int(global_id); i < N; i += int(gl_WorkGroupSize.x * gl_NumWorkGroups.x)) {
        output_data[i] = weight[i] * (squared_sum * input_data[i]);
    }
}
