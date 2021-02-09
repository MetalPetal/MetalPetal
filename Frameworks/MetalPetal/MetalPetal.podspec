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
s.tvos.deployment_target = '13.0'

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
    'MTIImageRenderingContext+Internal.h',
    'MTIBlendFormulaSupport.h'
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

s.subspec 'AppleSilicon' do |ss|
    ss.dependency 'MetalPetal/Core'
    ss.prefix_header_file = false
    ss.ios.script_phase = {
      :name => 'Build Metal Library - MSL 2.3',
      :script => <<~SCRIPTCONTENT,
        set -e
        set -u
        set -o pipefail
        cd "${PODS_TARGET_SRCROOT}/Shaders/"
        xcrun metal -target "air64-${LLVM_TARGET_TRIPLE_VENDOR}-${LLVM_TARGET_TRIPLE_OS_VERSION}${LLVM_TARGET_TRIPLE_SUFFIX:-""}" -ffast-math -std=ios-metal2.3 -o "${METAL_LIBRARY_OUTPUT_DIR}/default.msl23.metallib" *.metal
        SCRIPTCONTENT
      :execution_position => :after_compile
    }
    ss.tvos.script_phase = {
      :name => 'Build Metal Library - MSL 2.3',
      :script => <<~SCRIPTCONTENT,
        set -e
        set -u
        set -o pipefail
        cd "${PODS_TARGET_SRCROOT}/Shaders/"
        xcrun metal -target "air64-${LLVM_TARGET_TRIPLE_VENDOR}-${LLVM_TARGET_TRIPLE_OS_VERSION}${LLVM_TARGET_TRIPLE_SUFFIX:-""}" -ffast-math -std=ios-metal2.3 -o "${METAL_LIBRARY_OUTPUT_DIR}/default.msl23.metallib" *.metal
        SCRIPTCONTENT
      :execution_position => :after_compile
    }
    ss.macos.script_phase = {
      :name => 'Build Metal Library - MSL 2.3',
      :script => <<~SCRIPTCONTENT,
        set -e
        set -u
        set -o pipefail
        cd "${PODS_TARGET_SRCROOT}/Shaders/"
        xcrun metal -target "air64-${LLVM_TARGET_TRIPLE_VENDOR}-${LLVM_TARGET_TRIPLE_OS_VERSION}${LLVM_TARGET_TRIPLE_SUFFIX:-""}" -ffast-math -std=macos-metal2.3 -o "${METAL_LIBRARY_OUTPUT_DIR}/default.msl23.metallib" *.metal
        SCRIPTCONTENT
      :execution_position => :after_compile
    }
end

s.subspec 'Static' do |ss|
    ss.prefix_header_file = false
    ss.dependency 'MetalPetal/Core'
    ss.weak_frameworks = 'MetalPerformanceShaders', 'MetalKit'
    ss.ios.pod_target_xcconfig = { 'METAL_LIBRARY_OUTPUT_DIR' => '${TARGET_BUILD_DIR}/MetalPetal.bundle/' }
    ss.macos.pod_target_xcconfig = { 'METAL_LIBRARY_OUTPUT_DIR' => '${TARGET_BUILD_DIR}/MetalPetal.bundle/Contents/Resources' }
    ss.tvos.pod_target_xcconfig = { 'METAL_LIBRARY_OUTPUT_DIR' => '${TARGET_BUILD_DIR}/MetalPetal.bundle/' }
    ss.resource_bundle = { 'MetalPetal' => ['CocoaPodsBundledResourcePlaceholder'] }
    ss.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'METALPETAL_DEFAULT_LIBRARY_IN_BUNDLE=1'}
end

s.default_subspec = 'Core'

end
