Pod::Spec.new do |s|
  s.name         = "spa"
  s.version      = "1.1.0"
  s.summary      = "lua hotfix solution"

  s.description  = "hope to online"
  s.platform = :ios
  s.homepage     = "https://github.com/hzfanfei/spa"
  s.license      = "hzfanfei"
  s.requires_arc = true
  s.author       = { "hzfanfei" => "hzfanfei@corp.netease.com" }
  s.source       = { :git => "https://github.com/hzfanfei/spa.git", :tag => "#{s.version}" }
  s.source_files = "spa", "spa/Spa/**/*.{h,m,c}"
  s.ios.vendored_libraries = "spa/Spa/libffi/libffi_sim.a", "spa/Spa/libffi/libffi.a"
end

