Pod::Spec.new do |s|
s.name         = 'MetalPetal'
s.version      = '1.0'
s.author       = { 'YuAo' => 'me@imyuao.com' }
s.homepage     = 'https://github.com/MetalPetal/MetalPetal'
s.summary      = 'GPU-accelerated image and video processing framework based on Metal.'
s.license      = { :type => 'MIT'}
s.source       = { :git => 'https://github.com/MetalPetal/MetalPetal.git', :tag => s.version}
s.requires_arc = true

s.ios.deployment_target = '10.0'
s.macos.deployment_target = '10.13'

s.module_map = 'MetalPetal.modulemap'
s.prefix_header_file = false

s.swift_version = '5.0'

s.subspec 'Core' do |ss|
    ss.prefix_header_file = false
    ss.source_files = '**/*.{h,m,c,mm,metal}'
    ss.private_header_files = [
    'MTIPrint.h',
    'MTIDefer.h',
    'MTIHasher.h',
    'MTIImageRenderingContext+Internal.h'
    ]
    ss.library = 'c++'
    ss.pod_target_xcconfig = {
      'CLANG_CXX_LANGUAGE_STANDARD' => 'c++14'
    }
    ss.weak_frameworks = 'MetalPerformanceShaders', 'MetalKit'
end

s.subspec 'Swift' do |ss|
    ss.prefix_header_file = false
    ss.dependency 'MetalPetal/Core'
    ss.source_files = '**/*.{swift}'
    ss.weak_frameworks = 'MetalPerformanceShaders', 'MetalKit'
end

s.subspec 'Static' do |ss|
    ss.prefix_header_file = false
    ss.dependency 'MetalPetal/Core'
    ss.weak_frameworks = 'MetalPerformanceShaders', 'MetalKit'
    ss.ios.pod_target_xcconfig = { 'METAL_LIBRARY_OUTPUT_DIR' => '${TARGET_BUILD_DIR}/MetalPetal.bundle/' }
    ss.osx.pod_target_xcconfig = { 'METAL_LIBRARY_OUTPUT_DIR' => '${TARGET_BUILD_DIR}/MetalPetal.bundle/Contents/Resources' }
    ss.resource_bundle = { 'MetalPetal' => ['CocoaPodsBundledResourcePlaceholder'] }
    ss.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'METALPETAL_DEFAULT_LIBRARY_IN_BUNDLE=1'}
end

s.default_subspec = 'Core'

end
