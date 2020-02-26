Pod::Spec.new do |s|

  s.name                    =  "Criollo"
  s.version                 =  "0.5.7"
  s.license                 =  "MIT"

  s.summary                 =  "A powerful Cocoa based web application framework for macS, iOS and tvOS."

  s.homepage                =  "https://criollo.io/"
  s.author                  =   { "Cătălin Stan" => "catalin.stan@me.com" }
  s.social_media_url        =   "http://twitter.com/criolloio"

  s.source                  =  { :git => "https://github.com/thecatalinstan/Criollo.git", :tag => s.version, :submodules => true }

  s.module_name             = "Criollo"

  s.requires_arc            = true
  s.dependency              "CocoaAsyncSocket", "~> 7.6"
  s.dependency              "OpenSSL-Universal", "~> 1.0"

  s.source_files            = "Criollo/Criollo.h", "Criollo/Source/*.{h,m}", "Criollo/Source/{HTTP,FCGI,Routing,Extensions}/*.{h,m}"
  s.public_header_files     = "Criollo/Criollo.h", "Criollo/Source/CRTypes.h", "Criollo/Source/CRApplication.h", "Criollo/Source/Routing/CRRouter.h", "Criollo/Source/CRServer.h", "Criollo/Source/CRConnection.h", "Criollo/Source/CRMessage.h", "Criollo/Source/CRRequest.h", "Criollo/Source/CRRequestRange.h", "Criollo/Source/CRUploadedFile.h", "Criollo/Source/CRResponse.h", "Criollo/Source/HTTP/CRHTTPServer.h", "Criollo/Source/FCGI/CRFCGIServer.h", "Criollo/Source/Routing/CRRouteController.h", "Criollo/Source/Routing/CRNib.h", "Criollo/Source/Routing/CRView.h", "Criollo/Source/Routing/CRViewController.h", "Criollo/Source/CRMimeTypeHelper.h"

  s.osx.deployment_target   = "10.10"
  s.osx.weak_frameworks     = "Foundation"

  s.ios.deployment_target   = "8.0"

  s.tvos.deployment_target  = "9.0"

end
