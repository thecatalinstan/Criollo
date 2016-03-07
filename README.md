# Criollo
A powerful Cocoa based web application framework for OS X and iOS.
Criollo helps create self-contained web applications that deliver content directly over HTTP or behind a web server (through FastCGI) - all the while leveraging the technologies you know and love: GCD, NSURLSession, CoreImage etc.
You can write code in either Objective-C or Swift, however know that the framework itself is written in Objective-C. 
## Here’s a simple HelloWorld:
```objective-c
CRServer* server = [[CRHTTPServer alloc] init];
[server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
    [response sendString:@"Hello world!"];
} forPath:@"/"];
[server startListening];
```
and in Swift:
```swift
let server:CRServer = CRHTTPServer()
server.addBlock({ (request:CRRequest, response:CRResponse, completionHandler:CRRouteCompletionBlock) -> Void in
	response.sendString("Hello world!")
}, forPath: "/")
server.startListening()
```
## Why?
Criollo was created in order to take advantage of the truly awesome tools and APIs that OS X and iOS provide and serve content produced with them over the web. 
It incorporates an HTTP web server and a [FastCGI](http://fastcgi.com) application server that are used to deliver content. The server is built on Grand Central Dispatch and designed for *speed*.
## How to Use.
Criollo can easily be embedded as a web-server inside your OS X or iOS app, should you be in need of such a feature, however it was designed to create standalone, long-running daemon style apps. Is fully [launchd](http://launchd.info/) compatible and replicates the lifecycle and behaviour of `NSApplication`, so that the learning curve should be as smooth as possible. 
See the Hello World examples for a demo of the two usage patterns.
# Installing
The preferred way of installing Criollo is through [CocoaPods](http://cocoapods.org). However, you can also embed the framework in your projects manually.
## Installing with CocoaPods
1. Create the Podfile if you don’t already have one. You can do so by running `pod init` in the folder of the project.
2. Add Criollo to your Podfile.   
```ruby
pod 'Criollo', '~> 0.1.7
```
3. Run `pod install`
Please note that Criollo will download [CocoaAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket) as a dependency.
# Getting Started
This section covers creating a standalone background app (a launchd [daemon](https://developer.apple.com/library/mac/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)) using Criollo. Should you just be looking to embed it in your existing app, just skip steps 1 through 3.
## Step 1: The Project
**TL;DR**; You can just proceed to get the skeleton project from here.
Since the final build product is an OS X application, we will start with a Cocoa Application template project.[^An Xcode project template is in the pipeline, but I really haven’t gotten around to it.] The demo below is in Objective-C but it applies to Swift as well. 
Check out the [HelloWorld-Swift](https://github.com/thecatalinstan/Criollo/tree/master/Examples/HelloWorld-Swift) and [HelloWorld-ObjC](https://github.com/thecatalinstan/Criollo/tree/master/Examples/HelloWorld-ObjC) examples for a basic project.
### Open Xcode and Create a new Cocoa Application  
This will give us a really good starting point. None of the options should be selected.
![New project - Cocoa Application Details](https://criollo.io/res/doc/images/doc-1-2.png)
### Cleanup the Project  
There is some ‘excess fat’ in the standard cocoa application template - which we really don’t need. So, let’s get rid of it. Delete `Assets.xcassets` and `MainMenu.xib`. We are not really using those. Of course you can leave `Assets.xcassets`.
## Step 2: Adding Criollo
Once the basic cleanup of the project is done, we must add Criollo and configure the project to use it.
### CocoaPods
Open Terminal and `cd` to your project folder, and type in
`pod init`
This will create a file called `Podfile`. Open it in your favourite text editor and modify it so that it looks like this:
```ruby
platform :osx, '10.9'
use_frameworks!
target ‘HelloWorld’ do
        pod 'Criollo', '~> 0.1.7’
end
```
After that is done, in Terminal, run:
`pod install`.
This will install Criollo and its dependencies and create a `.xcworkspace` bundle. You should use this file and not the `.xcodeproj` file. 
Open the workspace in Xcode, and build.
### Principal Class - Info.plist
We have to make a small change to the `info.plist` file. Normally, the `Principal Class` of a Cocoa application is `NSApplication`. NSApplication takes care of a bunch of stuff like setting up a `RunLoop`, connecting to the graphics server, handling application events etc.
In the case of a Criollo application, this task is performed by the `CRApplication` class. We must *tell* the bundle that its `Principal Class` is `CRApplication`. Here’s how to do that:
1. Open `HelloWorld.xcworkspace` in Xcode, then locate and select the `Info.plist` file, in the Project navigator.
2. In the editor window, locate the key labeled `Principal class` (or `NSPrincipalClass` if you’re showing raw key/values).
3. Replace `NSApplication` with `CRApplication`.
### CRApplicationMain - The Entry Point
A typical Cocoa application will call the `NSApplicationMain` function to set everything up. A Criollo application does this with the `CRApplicationMain` function. This is located in the `main.m` file. 
A typical `main.m` file looks like this:
```objective-c
#import <Cocoa/Cocoa.h>

int main(int argc, const char * argv[]) {
    return NSApplicationMain(argc, argv);
}
```
In a Criollo app, the main.m file should look like this, assuming that `AppDelegate` is the application delegate class.
```objective-c
#import <Criollo/Criollo.h>
#import "AppDelegate.h"

int main(int argc, const char * argv[]) {
    return CRApplicationMain(argc, argv, [AppDelegate new]);
}
```
Eagle-eyed readers will observe that `CRApplicationMain` has one extra parameter. As you have guessed, this is the application delegate. Feel free to check out the code of [`CRApplicationMain`](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/CRApplication.m#L46).
Edit the `main.m` file and make the changes as indicated above.
At this point Xcode will display a warning about assigning `AppDelegate *` to `id<CRApplicationDelegate>`. We’ll take care of that next.
### The AppDelegate
As in the case of Cocoa, Criollo defines the [`CRApplicationDelegate`](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/CRApplication.h#L22) protocol[^Again apologies for the lack of documentation].
#### AppDelegate.h
The file should look like this:
```objective-c
#import <Criollo/Criollo.h>

@interface AppDelegate : NSObject <CRApplicationDelegate>

@end
```
The only two changes should be importing the Criollo header and conforming to `CRApplicationDelegate` instead of `NSApplicationDelegate`.
#### AppDelegate.m
Cocoa apps do more than we need. The main thing is to remove the  `IBOutlet` declaration, since we are not using Interface Builder to design our UI (if any). 
Look for the line `@property (weak) IBOutlet NSWindow *window;` and remove it. Everything else stays the same. The file should look like this:
```objective-c
#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
```
You’ll notice a few familiar methods; they do the exact same thing as in Cocoa or CocoaTouch.
You can download this [skeleton project here](https://criollo.io/res/doc/HelloWorld-skeleton.zip), for future use.
## Step 3: Hello World
At this point the app should build, start and hang around, doing absolutely nothing.
The next step is to spin-up a server and start serving some content.
### CRHTTPServer/CRFCGIServer
Depending on which way you need to go with your project, you can use either of the two (HTTP/FastCGI). This is not a decision you have to make at the start of development since the two classes are perfectly compatible. In case you need to switch just change the class you are instantiating.
First, let’s declare the server object as a property of the AppDelegate, for the purposes of retaining a strong reference to it.
```objective-c
@property (nonatomic, strong, nonnull) CRServer* server;
```
After that, inside `applicationDidFinishLaunching:` we initialize the server and start listening.
```objective-c
self.server = [[CRHTTPServer alloc] init];
[self.server startListening];
```
Criollo will start an HTTP server that is bound to all interfaces on port `10781`.
The server is accessible at [http://localhost:10781/](http://localhost:10781/). At this point, the server will return a 404 Not Found response, because there are no routes defined as yet. The info displayed to the client is provided by the built-in error handling block. The [code](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/CRServer.m#L42) for this is found [here](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/CRServer.m#L42).
### Adding a route

# Doing More Stuff
## Serving Static Files
## Cookies
## Setting up a View Controller
## Logging
# Deploy
# Work in Progress
Criollo is still work in progress and not ready for the wild yet. The reason for this is mainly missing functionality and sheer lack of documentation[^It is also very high on my list of priorities, but sadly still a “to-do” item].
The existing features and APIs are stable and are unlikely to change dramatically. 
## Missing Biggies
1. **Multipart request body parsing**. Criollo can handle JSON and URL-encoded bodies for now. Upcoming and in progress is the `multipart/form-data` request parsing.
2. **Binary / MIME body**. Requests that send binary data completely ignore this for now. This implementation is on the way, right after multipart.
2. **HTTPS** - The workaround for this is putting your app behind a  web server, like Nginx, and using the web-server as a reverse HTTP proxy or FastCGI client. Here’s an example of how to setup nginx to [reverse proxy HTTP requests](https://www.nginx.com/resources/wiki/start/topics/examples/reverseproxycachingexample/) and here’s how to [set up FastCGI](https://www.nginx.com/resources/wiki/start/topics/examples/fastcgiexample/#connecting-nginx-to-the-running-fastcgi-process).
## Get in Touch
If you have any **questions** regarding the project or **how to** do anything with it, please feel free to get in touch either on Twitter [@criolloio](https://twitter.com/criolloio) or by plain old email [criollo@criollo.io](mailto:criollo@criollo.io).
I really encourage you to [submit an issue](https://github.com/thecatalinstan/Criollo/issues/new), as your input is really really appreciated.





