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
  s.version          = "0.1.3"
  s.summary          = "Wrapper for smart scale APIs (currently supports Withings)"
  s.description      = <<-DESC
                       A wrapper for various smart scale APIs. Currently supports Withings' smart scales,
					   but the intent is to add support for scales from other vendors.
                       DESC
  s.homepage         = "https://github.com/amolloy/ASMScaleKit"
  s.license          = 'MIT'
  s.author           = { "Andrew Molloy" => "amolloy@gmail.com" }
  s.source           = { :git => "https://github.com/amolloy/ASMScaleKit.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/amolloy'

  s.platform     = :ios, '7.0' # iOS only for now, :osx, '10.9'
  s.requires_arc = true

  s.subspec 'Core' do |cs|
    cs.source_files = 'Pod/Classes', 'Pod/Classes/OAuth'
    cs.ios.source_files = 'Pod/Classes/OAuth/iOS'
    cs.public_header_files = 'Pod/Classes/*.h'
  end

  s.subspec 'Withings' do |ws|
    ws.dependency 'ASMScaleKit/Core'
    ws.source_files = 'Pod/Classes/Withings'
    ws.public_header_files = 'Pod/Classes/Withings/*.h'
  end
end
