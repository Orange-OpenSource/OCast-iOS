#
# Be sure to run `pod lib lint OCast.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
s.name             = 'OCast'
s.version          = '1.3.0'
s.summary          = 'OCast SDK provides an application with all necessary functions to cast any contents to an Orange stick.'

# This description is used to generate tags and improve search results.

s.description      = <<-DESC

The Orange OCast SDK provides all required API methods to implement cast applications for the Orange stick.
The Example project aims at demonstrating the basic instruction set of the Orange OCast SDK to help you get started.

Both Objective C and Swift applications may use the Orange OCast SDK.

Here are the main functionalities of the Example project:

- Wifi connection to the receiver
- Application stop and restart
- Audio cast Play/Pause/Stop
- Video cast Play/Pause/Stop
- Image cast
- Volume control
- Time seek management
- Media tracks management
- Custom messages handling

DESC

s.homepage         = 'https://github.com/Orange-OpenSource/OCast-iOS'
s.license          = { :type => 'Apache V2', :file => 'LICENSE' }
s.author           = { 'Orange Labs' => ['philippe.besombe@orange.com', 'christophe.azemar@orange.com', 'francois.suc@orange.com'] }
s.source           = { :git => 'https://github.com/Orange-OpenSource/OCast-iOS.git', :tag => s.version.to_s, :submodules => true }

s.ios.deployment_target = '8.0'
s.swift_version = '4.2'

s.subspec 'Core' do |core|
    core.source_files   = 'OCast/Core/**/*.{swift,m,h}', 'OCast/OCast.h'
    core.dependency 'CocoaAsyncSocket', '7.6.3'
end

s.subspec 'ReferenceDriver' do |reference|
    reference.source_files   = 'OCast/ReferenceDriver/**/*.{swift,m,h}', 'OCast/Starscream/Sources/*.swift'
    reference.dependency 'OCast/Core'
    reference.libraries      = 'z'
    reference.preserve_paths = 'OCast/Starscream/zlib/*'
    reference.pod_target_xcconfig = { 'SWIFT_INCLUDE_PATHS' => '$(PODS_TARGET_SRCROOT)/OCast/Starscream/zlib' }
end

end
