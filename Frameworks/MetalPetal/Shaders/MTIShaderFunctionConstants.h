//
//  MTIFunctionConstants.h
//  Pods
//
//  Created by YuAo on 2021/3/29.
//

#ifndef MTIShaderFunctionConstants_h
#define MTIShaderFunctionConstants_h

#ifdef __METAL_VERSION__

#include <metal_stdlib>

namespace metalpetal {
    constant bool blend_filter_backdrop_has_premultiplied_alpha [[function_constant(1024)]];
    constant bool blend_filter_source_has_premultiplied_alpha [[function_constant(1025)]];
    constant bool blend_filter_outputs_premultiplied_alpha [[function_constant(1026)]];
    constant bool blend_filter_outputs_opaque_image [[function_constant(1027)]];
    
    constant bool multilayer_composite_content_premultiplied [[function_constant(1028)]];
    constant bool multilayer_composite_has_mask [[function_constant(1029)]];
    constant bool multilayer_composite_has_compositing_mask [[function_constant(1030)]];
    constant bool multilayer_composite_has_tint_color [[function_constant(1031)]];
    constant short multilayer_composite_corner_curve_type [[function_constant(1037)]];

    constant bool rgb_color_space_conversion_input_has_premultiplied_alpha [[function_constant(1032)]];
    constant short rgb_color_space_conversion_input_color_space [[function_constant(1033)]];
    constant short rgb_color_space_conversion_output_color_space [[function_constant(1034)]];
    constant bool rgb_color_space_conversion_outputs_premultiplied_alpha [[function_constant(1035)]];
    constant bool rgb_color_space_conversion_outputs_opaque_image [[function_constant(1036)]];
}

#endif

#endif /* MTIShaderFunctionConstants_h */
