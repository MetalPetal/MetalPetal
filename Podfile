# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

target 'MetalPetalDemo' do
  use_frameworks!

  pod 'MetalPetal', :path => 'Frameworks/MetalPetal'
  pod 'MetalPetal/Swift', :path => 'Frameworks/MetalPetal'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = 'YES'
            config.build_settings['RUN_CLANG_STATIC_ANALYZER'] = 'YES'
            config.build_settings['CLANG_STATIC_ANALYZER_MODE'] = 'deep'
        end
    end
end
