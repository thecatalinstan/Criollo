Pod::Spec.new do |s|

  s.name                    =  "Criollo"
  s.version                 =  "1.1.0"
  s.license                 =  "MIT"

  s.summary                 =  "A powerful Cocoa web framework and HTTP server for macS, iOS and tvOS."

  s.homepage                =  "https://criollo.io/"
  s.author                  =  { "Cătălin Stan" => "catalin.stan@me.com" }
  s.social_media_url        =  "http://twitter.com/criolloio"

  s.source                  =  { :git => "https://github.com/thecatalinstan/Criollo.git", :tag => s.version, :submodules => true }

  s.module_name             =  "Criollo"

  s.requires_arc            =  true
  s.dependency              "CocoaAsyncSocket", "~> 7.6.5"

  s.source_files            =  "Sources/Criollo/Headers/Criollo/*", "Sources/Criollo/*.{h,m}", "Sources/Criollo/{HTTP,FCGI,Routing,Extensions}/*.{h,m}"
  s.public_header_files     =  "Sources/Criollo/Headers/Criollo/*"

  s.osx.deployment_target   = "10.10"
  s.ios.deployment_target   = "12.0"
  s.tvos.deployment_target  = "12.0"

end
