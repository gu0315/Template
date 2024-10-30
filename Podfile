source 'https://cdn.cocoapods.org'
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '11.0'
use_frameworks!
target 'Template' do
   pod 'SModular'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      target.build_settings(config.name)['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
    end
  end
end
