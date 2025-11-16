//
//  TriangleShader.metal
//  FluidEngine_Metal
//
//  Created by yuki on 2025/11/16.
//

#include <metal_stdlib>
using namespace metal;


struct VertexIn {
    float2 position [[attribute(0)]];
    float3 color [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 color;
};


//vertex float4 vs_main(VertexIn in [[stage_in]])
//{
//    return float4(in.position, 0.0, 1.0);
//}

vertex VertexOut vs_main(VertexIn in [[stage_in]], constant float4x4 &mvp [[buffer(1)]])
{
    VertexOut vout;
    vout.position = mvp * float4(in.position, 0.0, 1.0);
    vout.color = in.color;
    return vout;
}

fragment float4 fs_main(VertexOut in [[stage_in]])
{
    return float4(in.color, 1.0);
}
