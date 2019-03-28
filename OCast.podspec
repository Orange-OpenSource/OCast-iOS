#
# Be sure to run `pod lib lint OCast.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
s.name             = 'OCast'
s.version          = '2.0.0'
s.summary          = 'OCast SDK provides an implementation of OCast protocol.'

s.description      = <<-DESC

SDK provides all required API to use a TV stick compatible with OCast.
OCast SDK is compatible with Swift and Objective-C.
A small sample code in Swift/Objective-C is included.

DESC

s.homepage         = 'https://github.com/Orange-OpenSource/OCast-iOS'
s.license          = { :type => 'Apache V2', :file => 'LICENSE' }
s.author           = { 'Orange' => ['christophe.azemar@orange.com', 'francois.suc@orange.com'] }
s.source           = { :git => 'https://github.com/Orange-OpenSource/OCast-iOS.git', :tag => s.version.to_s, :submodules => true }

s.ios.deployment_target = '8.0'
s.swift_version = '4.2'

s.subspec 'Core' do |core|
    core.source_files   = 'OCast/Core/**/*.{swift,m,h}', 'OCast/OCast.h'
    core.dependency 'CocoaAsyncSocket', '7.6.3'
    core.dependency 'DynamicCodable', '1.0'
end

s.subspec 'ReferenceDriver' do |reference|
    reference.source_files   = 'OCast/ReferenceDriver/**/*.{swift,m,h}', 'OCast/Starscream/Sources/*.swift'
    reference.dependency 'OCast/Core'
    reference.libraries      = 'z'
    reference.preserve_paths = 'OCast/Starscream/zlib/*'
    reference.pod_target_xcconfig = { 'SWIFT_INCLUDE_PATHS' => '$(PODS_TARGET_SRCROOT)/OCast/Starscream/zlib' }
end

end
