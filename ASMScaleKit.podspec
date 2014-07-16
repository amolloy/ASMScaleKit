#
# Be sure to run `pod lib lint ASMScaleKit.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "ASMScaleKit"
  s.version          = "0.1.0"
  s.summary          = "A short description of ASMScaleKit."
  s.description      = <<-DESC
                       An optional longer description of ASMScaleKit

                       * Markdown format.
                       * Don't worry about the indent, we strip it!
                       DESC
  s.homepage         = "https://github.com/<GITHUB_USERNAME>/ASMScaleKit"
  s.license          = 'MIT'
  s.author           = { "Andrew Molloy" => "amolloy@gmail.com" }
  s.source           = { :git => "https://github.com/<GITHUB_USERNAME>/ASMScaleKit.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/amolloy'

  s.platform     = :ios, '7.0', :osx, '10.8'
  s.requires_arc = true

  s.source_files = 'Pod/Classes', 'Pod/Classes/OAuth'
  
  s.ios.source_files = 'Pod/Classes/OAuth/iOS'

  s.public_header_files = 'Pod/Classes/**/*.h'

  s.dependency 'libextobjc/EXTScope', '~> 0.4'

  s.subspec 'Withings' do |ws|
    ws.source_files = 'Pod/Classes/Withings'
    ws.public_header_files = 'Pod/Classes/Withings/*.h'
  end

# Based on Peter Hosey's Warnings.xcconfig. Put way down here to keep it out of the way.
  s.xcconfig = {
    "GCC_WARN_CHECK_SWITCH_STATEMENTS" => "YES",
    "GCC_WARN_SHADOW" => "YES",
    "GCC_WARN_64_TO_32_BIT_CONVERSION" => "YES",
    "CLANG_WARN_ENUM_CONVERSION" => "YES",
    "CLANG_WARN_INT_CONVERSION" => "YES",
    "CLANG_WARN_CONSTANT_CONVERSION" => "YES",
    "GCC_WARN_INITIALIZER_NOT_FULLY_BRACKETED" => "YES",
    "GCC_WARN_ABOUT_RETURN_TYPE" => "YES",
    "GCC_WARN_MISSING_PARENTHESES" => "YES",
    "GCC_WARN_ABOUT_MISSING_FIELD_INITIALIZERS" => "YES",
    "GCC_WARN_ABOUT_MISSING_NEWLINE" => "YES",
    "GCC_WARN_SIGN_COMPARE" => "YES",
    "GCC_WARN_UNDECLARED_SELECTOR" => "YES",
    "GCC_WARN_UNUSED_FUNCTION" => "YES",
    "GCC_WARN_UNUSED_LABEL" => "YES",
    "GCC_WARN_UNUSED_VALUE" => "YES",
    "GCC_WARN_UNUSED_VARIABLE" => "YES",
    "GCC_WARN_ABOUT_MISSING_PROTOTYPES" => "YES",
    "GCC_WARN_TYPECHECK_CALLS_TO_PRINTF" => "YES",
    "GCC_WARN_ABOUT_DEPRECATED_FUNCTIONS" => "YES",
    "GCC_WARN_HIDDEN_VIRTUAL_FUNCTIONS" => "YES",
    "GCC_WARN_ABOUT_INVALID_OFFSETOF_MACRO" => "YES",
    "GCC_WARN_NON_VIRTUAL_DESTRUCTOR" => "YES",
    "CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS" => "YES",
    "CLANG_WARN_IMPLICIT_SIGN_CONVERSION" => "YES",
    "CLANG_WARN_SUSPICIOUS_IMPLICIT_CONVERSION" => "YES",
    "CLANG_WARN_EMPTY_BODY" => "YES",
    "CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF" => "YES",
    "CLANG_ANALYZER_SECURITY_FLOATLOOPCOUNTER" => "YES",
    "CLANG_ANALYZER_SECURITY_INSECUREAPI_RAND" => "YES",
    "OTHER_CFLAGS" => "-Wextra -Wno-unused-parameter -Wformat=2",
    "GCC_TREAT_WARNINGS_AS_ERRORS" => "YES"
  }

end
