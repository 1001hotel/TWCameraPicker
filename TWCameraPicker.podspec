#
#  Be sure to run `pod spec lint TWCameraPicker.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
s.name         = "TWCameraPicker"

  s.version      = "1.0.1"

  s.summary      = "A camera picker used on iOS."

  s.description  = <<-DESC
                   It is a camera picker used on iOS, which implement by Objective-C.
                   DESC

  s.homepage     = "https://github.com/1001hotel/TWCameraPicker"

  s.license      = "MIT"

  s.author             = { "xurenyan" => "812610313@qq.com" }

  s.platform     = :ios, "8.0"

  s.requires_arc = true

  s.source       = { :git => "https://github.com/1001hotel/TWCameraPicker.git", :tag => s.version.to_s }

  s.source_files  = "TWCameraPicker/TWCameraPicker/TWCameraPicker/*.{h,m}"
  s.resources = "TWCameraPicker/**/*.png", "TWCameraPicker/TWCameraPicker/TWCameraPicker/*.xib"

  s.frameworks = "AVFoundation", "Foundation", "UIKit", "CoreLocation", "MobileCoreServices", "AssetsLibrary" 

 #s.libraries = "z", "c++"

end
