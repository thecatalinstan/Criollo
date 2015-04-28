Pod::Spec.new do |s|
  
  s.name         = "Criollo"
  s.version      = "0.2.4"
  s.summary      = "A Cocoa framework for creating web applications."

  s.description  = <<-DESC

                   Criollo helps create self-contained web-applications that serve web content via webserver                    
                   
                   DESC

  s.homepage     = "https://github.com/thecatalinstan/Criollo"  

  s.license  = { :type => "public domain", :text => <<-LICENSE

                    Public Domain License

                    The Criollo project is in the public domain.

                    Updated and maintained by Cătălin Stan.

                 LICENSE
               }

  s.author             = { "Cătălin Stan" => "catalin.stan@me.com" }
  s.social_media_url   = "http://twitter.com/catalinstan"

  s.source       = { :git => "https://github.com/thecatalinstan/Criollo.git", :tag => s.version }

  s.source_files  = "Criollo", "Criollo/Classes/*.{h,m}, "Libraries/CocoaAsyncSocket/GCD/GCDAsyncSocket.{h,m}"
  s.public_header_files = "Criollo", "Criollo/Classes/*.h", "Libraries/CocoaAsyncSocket/GCD/GCDAsyncSocket.h"

 	s.osx.deployment_target = "10.10"
  s.osx.frameworks = "CFNetwork", "Foundation"
  
  s.requires_arc = true

end
