Pod::Spec.new do |s|
  
  s.name         =  "Criollo"
  s.version      =  "0.1.4"
  s.license      =  { :type => "public domain", :text => <<-LICENSE

Public Domain License

The Criollo project is in the public domain.
Updated and maintained by Cătălin Stan.
                    LICENSE
                    }

  s.summary      =  "A Cocoa framework for creating HTTP or FCGI web applications."
  s.description  =  <<-DESC

Criollo helps create self-contained web applications that serve content
over the HTTP or FCGI protocols.                   
                    DESC

  s.homepage     			 =  "https://github.com/thecatalinstan/Criollo"
  s.author             =   { "Cătălin Stan" => "catalin.stan@me.com" }
  s.social_media_url   =   "http://twitter.com/criolloio"

  s.source       =  { :git => "https://github.com/thecatalinstan/Criollo.git", :tag => s.version }
  # s.source       =  { :git => "https://github.com/thecatalinstan/Criollo.git", :branch => "develop" }

  s.module_name         = "Criollo"

  s.source_files        = "Criollo/Criollo.h", "Criollo/Source/*.{h,m}", "Criollo/Source/{HTTP,FCGI,Routing,Extensions}/*.{h,m}"
  s.public_header_files = "Criollo/Criollo.h", "Criollo/Source/CRTypes.h", "Criollo/Source/CRApplication.h", "Criollo/Source/CRServer.h", "Criollo/Source/CRConnection.h", "Criollo/Source/CRMessage.h", "Criollo/Source/CRRequest.h", "Criollo/Source/CRResponse.h", "Criollo/Source/HTTP/CRHTTPServer.h", "Criollo/Source/FCGI/CRFCGIServer.h", "Criollo/Source/Routing/CRNib.h", "Criollo/Source/Routing/CRView.h", "Criollo/Source/Routing/CRViewController.h", "Criollo/Source/CRMimeTypeHelper.h"
  
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = "10.9"
  s.osx.frameworks = "Foundation"
  
  s.requires_arc = true

  s.dependency 		'CocoaAsyncSocket', '~> 7.4.2'

end
