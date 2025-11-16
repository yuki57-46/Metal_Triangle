//
//  MetalRenderer.h
//  Metal_Sample
//
//  Created by yuki on 2025/11/16.
//

#ifndef MetalRenderer_h
#define MetalRenderer_h

#import <QuartzCore/CAMetalLayer.h>

class MetalRenderer {
public:
    MetalRenderer(CAMetalLayer* layer);
    ~MetalRenderer();
    
    void Init();
    void DrawFrame();

private:
    void* impl;
    float angle;
};

#endif /* MetalRenderer_h */
