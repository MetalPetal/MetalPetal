# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

target 'MetalPetalDemo' do
  use_frameworks!

  pod 'MetalPetal', :path => 'Frameworks/MetalPetal'
  pod 'MetalPetal/Swift', :path => 'Frameworks/MetalPetal'
end

post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
        config.build_settings['RUN_CLANG_STATIC_ANALYZER'] = 'YES'
        config.build_settings['CLANG_STATIC_ANALYZER_MODE'] = 'deep'
        
        config.build_settings['CLANG_WARN_UNGUARDED_AVAILABILITY'] = 'YES_AGGRESSIVE'
        config.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = 'YES'
        config.build_settings['CLANG_ANALYZER_SECURITY_FLOATLOOPCOUNTER'] = 'YES'
        config.build_settings['GCC_WARN_ABOUT_RETURN_TYPE'] = 'YES_ERROR'
        config.build_settings['GCC_WARN_ABOUT_MISSING_FIELD_INITIALIZERS'] = 'YES'
        config.build_settings['GCC_WARN_ABOUT_MISSING_PROTOTYPES'] = 'YES'
        config.build_settings['CLANG_WARN_ASSIGN_ENUM'] = 'YES'
        config.build_settings['GCC_WARN_SIGN_COMPARE'] = 'YES'
        config.build_settings['GCC_TREAT_INCOMPATIBLE_POINTER_TYPE_WARNINGS_AS_ERRORS'] = 'YES'
        config.build_settings['GCC_TREAT_IMPLICIT_FUNCTION_DECLARATIONS_AS_ERRORS'] = 'YES'
        config.build_settings['GCC_WARN_UNINITIALIZED_AUTOS'] = 'YES_AGGRESSIVE'
        config.build_settings['ENABLE_STRICT_OBJC_MSGSEND'] = 'YES'
        config.build_settings['GCC_NO_COMMON_BLOCKS'] = 'YES_AGGRESSIVE'
        config.build_settings['CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING'] = 'YES'
        config.build_settings['CLANG_WARN_NON_LITERAL_NULL_CONVERSION'] = 'YES'
        config.build_settings['CLANG_WARN_OBJC_LITERAL_CONVERSION'] = 'YES'
        config.build_settings['CLANG_WARN_RANGE_LOOP_ANALYSIS'] = 'YES'
        config.build_settings['CLANG_WARN_STRICT_PROTOTYPES'] = 'YES'
        config.build_settings['CLANG_WARN_COMMA'] = 'YES'
        config.build_settings['CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF'] = 'YES'
        config.build_settings['CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS'] = 'YES'
        config.build_settings['GCC_WARN_ABOUT_MISSING_NEWLINE'] = 'YES'
        config.build_settings['CLANG_WARN_SEMICOLON_BEFORE_METHOD_BODY'] = 'YES'
        config.build_settings['CLANG_WARN_OBJC_IMPLICIT_ATOMIC_PROPERTIES'] = 'YES'
        config.build_settings['CLANG_WARN_OBJC_REPEATED_USE_OF_WEAK'] = 'YES'
        config.build_settings['GCC_WARN_STRICT_SELECTOR_MATCH'] = 'YES'
        config.build_settings['CLANG_WARN_OBJC_EXPLICIT_OWNERSHIP_TYPE'] = 'YES'
        config.build_settings['CLANG_ANALYZER_GCD_PERFORMANCE'] = 'YES'
        config.build_settings['CLANG_ANALYZER_LOCALIZABILITY_NONLOCALIZED'] = 'YES'
    end
end
