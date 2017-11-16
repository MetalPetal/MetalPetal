Pod::Spec.new do |s|
s.name         = 'MetalPetal'
s.version      = '1.0'
s.author       = { 'YuAo' => 'me@imyuao.com' }
s.homepage     = 'https://github.com/YuAo/MetalPetal'
s.summary      = 'A image processing framework based on Metal.'
s.license      = { :type => 'MIT'}
s.source       = { :git => 'https://github.com/YuAo/MetalPetal.git', :tag => s.version}
s.requires_arc = true
s.ios.deployment_target = '9.0'

s.subspec 'Core' do |ss|
    ss.source_files = '**/*.{h,m,c,mm,metal}'
    ss.private_header_files = [
    'MTIImage+Promise.h',
    'MTIPrint.h',
    'MTIDefer.h'
    ]
    ss.user_target_xcconfig = { 'MTL_HEADER_SEARCH_PATHS' => '$(inherited) "${PODS_CONFIGURATION_BUILD_DIR}/MetalPetal/MetalPetal.framework/Headers"' }
end

s.subspec 'Swift' do |ss|
    ss.dependency 'MetalPetal/Core'
    ss.source_files = '**/*.{swift}'
end

s.default_subspec = 'Core'

end
