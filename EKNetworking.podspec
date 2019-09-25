Pod::Spec.new do |s|
    
    # 1
    s.platforms = { :ios => "10.0", :osx => "10.14", :watchos => "5.0", :tvos => "10.0" }
    s.name = "EKNetworking"
    s.summary = "EKNetworking swift 5.1 framework for simple development amazing apps."
    s.requires_arc = true
    
    # 2
    s.version = "1.0.0"
    
    # 3
    s.license = { :type => "MIT", :file => "LICENSE" }
    
    # 4 - Replace with your name and e-mail address
    s.author = { "Emil Karimov" => "emvakar@gmail.com" }
    
    # 5 - Replace this URL with your own Github page's URL (from the address bar)
    s.homepage = "https://github.com/emvakar/EKNetworking.git"
    
    # 6 - Replace this URL with your own Git URL from "Quick Setup"
    s.source = { :git => "https://github.com/emvakar/EKNetworking.git", :tag => "#{s.version}"}
    
    # 7
    s.framework = "UIKit"
    s.dependency 'Moya', '~> 13.0.1'
    
    # 8
    s.source_files = "Sources/EKNetworking/**/*.{swift}"
    
    # 9
    s.resources = "Sources/EKNetworking/**/*.{png,jpeg,jpg,storyboard,xib}"
    s.resource_bundles = {
        'EKNetworkingAssets' => ['Sources/EKNetworking/**/*.xcassets']
    }
end
