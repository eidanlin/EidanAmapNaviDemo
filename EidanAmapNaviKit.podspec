Pod::Spec.new do |s|
  s.name         = "EidanAmapNaviKit"
  s.version      = "0.0.1"
  s.summary      = "基于高德导航SDK的自定义驾车导航界面"
  s.description  = <<-DESC
                    利用高德地图导航SDK，自定义驾车导航界面
                   DESC
  s.homepage     = "http://www.passby.net.cn"
  s.license      = {:type => 'Copyright', :text=> <<-LICENSE
                    Copyright © 2017 Passby. All Rights Reserved.
                    LICENSE
    }
  s.author       = { 'eidanlin' => 'wenan_39141@163.com' }
  s.source       = { :git => "https://github.com/eidanlin/EidanAmapNaviDemo.git", :tag => "v0.0.1" }
  s.source_files  = "EidanAmapNaviDemo/AMapNaviDriveViewX/*"
  s.resources = 'EidanAmapNaviDemo/**/*.{png,xib}'
  s.platform     = :ios, '8.0'
  s.requires_arc = true
  s.frameworks = 'CoreLocation', 'SystemConfiguration', 'CoreTelephony', 'Security'
  s.libraries = 'stdc++.6.0.9', 'z', 'c++'
  s.dependency 'AMapNavi'

end
