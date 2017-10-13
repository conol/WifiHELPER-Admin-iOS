use_frameworks!
platform :ios, '11.0'

def install_pods

pod 'CORONAWriter', :git => 'https://gitlab.conol.jp/IoT/CORONAWriter-iOS.git', :branch => 'develop'
pod 'CORONAReader', :git => 'https://gitlab.conol.jp/IoT/CORONAReader-iOS.git', :branch => 'develop'
#pod 'IDZSwiftCommonCrypto', '~> 0.9.2'

end

target "wifiHelper-admin" do
  install_pods
end


post_install do |installer|
    installer.pods_project.targets.each do |target|
        if target.name == "wifiHelper-admin"
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = "4.0"
            end
        end
    end
end
