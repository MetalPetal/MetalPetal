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
    ss.source_files = '**/*.{h,m,c,mm,metal}'
    ss.private_header_files = [
    'MTIPrint.h',
    'MTIDefer.h',
    'MTIHasher.h',
    'MTIImageRenderingContext+Internal.h'
    ]
    ss.weak_frameworks = 'MetalPerformanceShaders', 'MetalKit'
end

s.subspec 'Swift' do |ss|
    ss.dependency 'MetalPetal/Core'
    ss.source_files = '**/*.{swift}'
    ss.weak_frameworks = 'MetalPerformanceShaders', 'MetalKit'
end

s.default_subspec = 'Core'

end
