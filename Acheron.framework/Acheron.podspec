#
#  Be sure to run `pod spec lint Acheron.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name					= "acheron"
  spec.version				= "0.0.15"
  spec.summary				= "Acheron is a collection of utilties for developing iOS apps."
  spec.homepage				= "https://github.com/aepryus/Acheron"
  spec.license				= "MIT"
  spec.author				= { "Aepryus Software" => "contact@aepryus.com" }
  spec.platform				= :ios, "11.0"
  spec.source				= { :git => "https://github.com/aepryus/Acheron/Acheron.git", :branch => "cocoaPod" }
  spec.vendored_frameworks	= "Acheron.framework"
end
