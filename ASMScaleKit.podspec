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

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes', 'Pod/Classes/OAuth'
  s.public_header_files = 'Pod/Classes/**/*.h'

  s.subspec 'Withings' do |ws|
    ws.source_files = 'Pod/Classes/Withings'
    ws.public_header_files = 'Pod/Classes/Withings/*.h'
  end

end
