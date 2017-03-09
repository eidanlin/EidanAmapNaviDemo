Pod::Spec.new do |s|

  s.name         = "AMapNaviKit"
  s.version      = "5.0.0"
  s.summary      = "AMapNaviKit for Myself."
  s.description  = <<-DESC
                    AMapNaviKit for Myself
                   DESC

  s.homepage     = "http://lbs.amap.com/api/ios-sdk/summary/"
  s.license      = {:type => 'Copyright', :text=> <<-LICENSE
Copyright © 2014 AutoNavi. All Rights Reserved.
			LICENSE
	}

  s.author = 'lbs.amap.com'
  s.social_media_url   = 'http://lbsbbs.amap.com/forum.php?mod=forumdisplay&fid=38'
  s.documentation_url = 'http://lbs.amap.com/api/ios-sdk/reference/'


  s.source = { :http => "file:///Users/eidan/Desktop/AMap_iOS_Navi_Lib_V2.3.0_20170309.zip" }

  s.source_files  = 'AMapNaviKit.framework/**/*.{h}'

  s.platform     = :ios, '7.0'

  s.requires_arc = true

  s.xcconfig = {'OTHER_LDFLAGS' => '-ObjC', 'ARCHS' => '$(ARCHS_STANDARD)'}

  s.public_header_files = 'AMapNaviKit.framework/Headers/*.h'

  s.resource = 'AMapNaviKit.framework/AMapNavi.bundle'

  s.vendored_frameworks = 'AMapNaviKit.framework'

  s.frameworks = 'QuartzCore', 'CoreLocation', 'SystemConfiguration', 'CoreTelephony', 'Security', 'OpenGLES', 'CoreText', 'CoreGraphics'

  s.libraries = 'stdc++.6.0.9', 'z', 'c++'

end
