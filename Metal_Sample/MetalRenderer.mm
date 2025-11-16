//
//  MetalRenderer.m
//  Metal_Sample
//
//  Created by yuki on 2025/11/16.
//

#import "MetalRenderer.h"

#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#import <AppKit/AppKit.h>
#import <simd/simd.h>

@interface MetalRendererObjCImpl : NSObject
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> queue;
@property (nonatomic, strong) CAMetalLayer* layer;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipeline;
@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;
@property (nonatomic, strong) id<MTLBuffer> uniformBuffer;
@end

@implementation MetalRendererObjCImpl
@end

MetalRenderer::MetalRenderer(CAMetalLayer* layer)
{
    MetalRendererObjCImpl* obj = [[MetalRendererObjCImpl alloc] init];
    obj.layer = layer;
    impl = (__bridge_retained void*)obj;
}

MetalRenderer::~MetalRenderer()
{
    MetalRendererObjCImpl* p = (__bridge_transfer MetalRendererObjCImpl*)impl;
    // ARC により自動解放される
    // ARC ... Automatic Reference Counting(自動参照カウント)
    (void)p;
}

void MetalRenderer::Init()
{
    MetalRendererObjCImpl* p = (__bridge MetalRendererObjCImpl*)impl;
    
    p.device = MTLCreateSystemDefaultDevice();
    p.queue = [p.device newCommandQueue];
    
    // 受け取った layer の設定を更新
    p.layer.device = p.device;
    p.layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    p.layer.contentsScale = NSScreen.mainScreen.backingScaleFactor;
    
    // ウィンドウサイズに追従
    p.layer.frame = p.layer.superlayer.bounds;
    
    p.uniformBuffer = [p.device newBufferWithLength:sizeof(simd_float4x4) options:MTLResourceStorageModeShared];
    
    // パイプラインの構築
    NSError* error = nil;
    id<MTLLibrary> lib = [p.device newDefaultLibrary];
    
    if (!lib) {
        NSLog(@"[ERROR] newDefaultLibrary returned nil - .metal ファイルがターゲットに入っていない可能性があります");
    }
    
    id<MTLFunction> vfn = [lib newFunctionWithName:@"vs_main"];
    id<MTLFunction> ffn = [lib newFunctionWithName:@"fs_main"];
    
    if (!vfn) NSLog(@"[ERROR] vertex shader 'vs_main' が見つかりません");
    if (!ffn) NSLog(@"[ERROR] fragment shader 'fs_main' が見つかりません");
    
    MTLRenderPipelineDescriptor *desc = [[MTLRenderPipelineDescriptor alloc] init];
    desc.vertexFunction = vfn;
    desc.fragmentFunction = ffn;
    
    MTLVertexDescriptor* vdesc = [[MTLVertexDescriptor alloc] init];
    // attribute 0 : position (float2)
    vdesc.attributes[0].format = MTLVertexFormatFloat2;
    vdesc.attributes[0].offset = 0;
    vdesc.attributes[0].bufferIndex = 0;
    
    // attribute 1 : color (float3)
    vdesc.attributes[1].format = MTLVertexFormatFloat3;
    vdesc.attributes[1].offset = sizeof(float) * 2;
    vdesc.attributes[1].bufferIndex = 0;
    
    vdesc.layouts[0].stride = sizeof(float) * 5;
    vdesc.layouts[0].stepRate = 1;
    vdesc.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
    
    desc.vertexDescriptor = vdesc;
    
    desc.colorAttachments[0].pixelFormat = p.layer.pixelFormat;
    
    p.pipeline = [p.device newRenderPipelineStateWithDescriptor:desc error:&error];
    
    if (!p.pipeline) {
        NSLog(@"[ERROR] pipeline creation failed %@", error);
    } else {
        NSLog(@"[OK] pipeline created");
    }
    
    float vertices[] = {
    //    x     y        r    g   b
         0.0f,  0.8f,   1.0f, 0.0f, 0.0f,
        -0.8f, -0.8f,   0.0f, 1.0f, 0.0f,
         0.8f, -0.8f,   0.0f, 0.0f, 1.0f
    };
    
    p.vertexBuffer = [p.device newBufferWithBytes:vertices length:sizeof(vertices) options:MTLResourceStorageModeShared];
}

void MetalRenderer::DrawFrame()
{
    MetalRendererObjCImpl* p = (__bridge MetalRendererObjCImpl*)impl;

    id<CAMetalDrawable> drawable = [p.layer nextDrawable];
    if (!drawable)
    {
        NSLog(@"[WARN] drawable is nil");
        return;
    }
    id<MTLCommandBuffer> cmd = [p.queue commandBuffer];
    MTLRenderPassDescriptor* pass = [MTLRenderPassDescriptor renderPassDescriptor];

    // 描画コマンドをここに追加
    
    // 回転
    angle += 0.02f;
    float c = cosf(angle);
    float s = sinf(angle);
    simd_float4 col0 = { c, s, 0.0f, 0.0f };
    simd_float4 col1 = { -s, c, 0.0f, 0.0f };
    simd_float4 col2 = { 0.0f, 0.0f, 1.0f, 0.0f };
    simd_float4 col3 = { 0.0f, 0.0f, 0.0f, 1.0f };
    simd_float4x4 mvp = { col0, col1, col2, col3 };
    
    memcpy(p.uniformBuffer.contents, &mvp, sizeof(mvp));
    
    pass.colorAttachments[0].texture = drawable.texture;
    pass.colorAttachments[0].clearColor = MTLClearColorMake(0.1, 0.1, 0.3, 1.0);
    pass.colorAttachments[0].storeAction = MTLStoreActionStore;
    pass.colorAttachments[0].loadAction = MTLLoadActionClear;
    
    id<MTLRenderCommandEncoder> enc = [cmd renderCommandEncoderWithDescriptor:pass];
    
    [enc setRenderPipelineState:p.pipeline];
    [enc setVertexBuffer:p.vertexBuffer offset:0 atIndex:0];
    [enc setVertexBuffer:p.uniformBuffer offset:0 atIndex:1];
    [enc drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
    
    [enc endEncoding];
    [cmd presentDrawable:drawable];
    [cmd commit];
}
