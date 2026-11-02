# Uncomment the next line to define a global platform for your project
platform :ios, '17.0'
workspace 'AllProjects'
target 'NVMobile' do
  # Comment the next line if you don't want to use dynamic frameworks
  #use_frameworks!

  # Pods for NVMobile
  pod 'GoogleMaps'
  pod 'Google-Maps-iOS-Utils'
  pod 'GooglePlaces'


end
post_install do |installer|
    installer.pods_project.targets.each do |target|
      if target.name == 'Google-Maps-iOS-Utils' || target.name == 'react-native-google-maps'
        target.build_configurations.each do |config|
          config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'NO'
        end
      end
    end
  end

