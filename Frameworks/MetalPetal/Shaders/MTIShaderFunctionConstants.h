//
//  MTIFunctionConstants.h
//  Pods
//
//  Created by YuAo on 2021/3/29.
//

#ifndef MTIShaderFunctionConstants_h
#define MTIShaderFunctionConstants_h

#if __METAL_MACOS__ || __METAL_IOS__

#include <metal_stdlib>

namespace metalpetal {
    constant bool blend_filter_backdrop_has_premultiplied_alpha [[function_constant(1024)]];
    constant bool blend_filter_source_has_premultiplied_alpha [[function_constant(1025)]];
    constant bool blend_filter_outputs_premultiplied_alpha [[function_constant(1026)]];
    constant bool blend_filter_outputs_opaque_image [[function_constant(1027)]];
    
    constant bool multilayer_composite_content_premultiplied [[function_constant(1028)]];
    constant bool multilayer_composite_has_mask [[function_constant(1029)]];
    constant bool multilayer_composite_mask_inverted [[function_constant(1030)]];
    constant bool multilayer_composite_has_compositing_mask [[function_constant(1031)]];
    constant bool multilayer_composite_compositing_mask_inverted [[function_constant(1032)]];
    constant bool multilayer_composite_has_tint_color [[function_constant(1033)]];
}

#endif

#endif /* MTIShaderFunctionConstants_h */
