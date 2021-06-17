Pod::Spec.new do |spec|
  spec.name					= "Acheron"
  spec.version				= "0.0.19"
  spec.summary				= "Acheron is a collection of utilties for developing iOS apps."
  spec.homepage				= "https://github.com/aepryus/Acheron"
  spec.license				= "MIT"
  spec.author				= { "Aepryus Software" => "contact@aepryus.com" }
  spec.platform				= :ios, "11.0"
  spec.source				= { :git => "https://github.com/aepryus/Acheron/Acheron.git", :branch => "cocoaPod" }
  spec.vendored_frameworks	= "Acheron.framework"
end
