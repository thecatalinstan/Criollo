[![Version Status](https://img.shields.io/cocoapods/v/Criollo.svg?style=flat)](http://cocoadocs.org/docsets/Criollo)  [![Platform](http://img.shields.io/cocoapods/p/Criollo.svg?style=flat)](http://cocoapods.org/?q=Criollo) [![license Public Domain](https://img.shields.io/badge/license-Public%20Domain-orange.svg?style=flat)](https://en.wikipedia.org/wiki/Public_domain)

# Criollo

#### A powerful Cocoa based web application framework for OS X and iOS.

Criollo helps create standalone web apps that deliver content directly over HTTP or FastCGI. You can write code in Objective-C or Swift. And you can use technologies you know and love: Grand Central Dispatch, NSURLSession, CoreImage and many more. 

It's as easy as this:

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

## How to Use

Criollo can easily be embedded as a web-server inside your OS X or iOS app, should you be in need of such a feature, however it was designed to create standalone, long-lived daemon style apps. It is fully [`launchd`](http://launchd.info/) compatible and replicates the lifecycle and behaviour of `NSApplication`, so that the learning curve should be as smooth as possible. 

See the [Hello World Multi Target example](https://github.com/thecatalinstan/Criollo/tree/master/Examples/HelloWorld-MultiTarget) for a demo of the two usage patterns.

# Installing

The preferred way of installing Criollo is through [CocoaPods](http://cocoapods.org). However, you can also embed the framework in your projects manually.

## Installing with CocoaPods

1. Create the Podfile if you don’t already have one. You can do so by running `pod init` in the folder of the project.
2. Add Criollo to your Podfile. `pod 'Criollo', '~> 0.1.7’`
3. Run `pod install`

Please note that Criollo will download [CocoaAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket) as a dependency.

# Getting Started

This section covers creating a standalone background app (a launchd [daemon](https://developer.apple.com/library/mac/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)) using Criollo.

## Step 1: The Project

**TL;DR**; You can just proceed to get the [skeleton project](https://criollo.io/res/doc/HelloWorld-skeleton.zip) from [here](https://criollo.io/res/doc/HelloWorld-skeleton.zip).

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

``` ruby
platform :osx, '10.9'
use_frameworks!
target ‘HelloWorld’ do
    pod 'Criollo', '~> 0.1.7’
end
```

After that is done, in Terminal, run:

```
pod install
```

This will install Criollo and its dependencies and create a `.xcworkspace` bundle. You should use this file and not the `.xcodeproj` file. 

Open the workspace in Xcode, and build.

### Principal Class - Info.plist

We have to make a small change to the `info.plist` file. Normally, the `Principal Class` of a Cocoa application is `NSApplication`. NSApplication takes care of a bunch of stuff like setting up a `RunLoop`, connecting to the graphics server, handling application events etc.

In the case of a Criollo application, these tasks are performed by the `CRApplication` class. We must *tell* the bundle that its `Principal Class` is `CRApplication`. 

Here’s how to do that:

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

First, let’s declare the server object as a property of the AppDelegate, for the purposes of retaining a strong reference to it, just to prevent ARC from prematurely `dealloc`-ing as soon as we exit `applicationDidFinishLaunching:`.

```objective-c
@property (nonatomic, strong, nonnull) CRServer* server;
```

After that, inside `applicationDidFinishLaunching:` we initialize the server and start listening.

```objective-c
self.server = [[CRHTTPServer alloc] init];
[self.server startListening];
```

Criollo will start an HTTP server that is bound to all interfaces on port `10781`. The server is accessible at [http://localhost:10781/](http://localhost:10781/). 

At this point, the server will return a 404 Not Found response, because there are no routes defined as yet. 

The info displayed to the client is provided by the built-in error handling block. The [code](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/CRServer.m#L42) for this is found [here](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/CRServer.m#L42).

### CRRouteBlock

The basic building block of Criollo’s routing system is a [`CRRouteBlock`](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/CRTypes.h#L15).

```objective-c
typedef void(^CRRouteBlock)(CRRequest* _Nonnull request, CRResponse* _Nonnull response, CRRouteCompletionBlock _Nonnull completionHandler);
```

These blocks are added to paths according to HTTP request methods and they get executed in the order in which they are added to the route.

### Adding a route

[`CRServer`](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/CRServer.h) offers several ways of adding a `CRRouteBlock` to a route:

```objective-c
- (void)addBlock:(CRRouteBlock _Nonnull)block;
- (void)addBlock:(CRRouteBlock _Nonnull)block forPath:(NSString * _Nullable)path;
- (void)addBlock:(CRRouteBlock _Nonnull)block forPath:(NSString * _Nullable)path HTTPMethod:(NSString * _Nullable)HTTPMethod;
- (void)addBlock:(CRRouteBlock _Nonnull)block forPath:(NSString * _Nullable)path HTTPMethod:(NSString * _Nullable)HTTPMethod recursive:(BOOL)recursive;
```

For the purpose of this guide we will add a block that says “Hello World”, to the path “/", for the HTTP method “GET”.

```objective-c
[self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
    [response sendString:@"Hello world!"];
    completionHandler();
} forPath:@"/" HTTPMethod:CRHTTPMethodGET];
```

Using `sendString:` and the `send` family of functions causes the response to end. Subsequent calls to the `write` or `send` [family of functions](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/CRResponse.h#L33-L40) will throw an `NSInternalInconsistencyException`. Check out the rest of the [CRResponse API](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/CRResponse.h).

At the end of the work that this block will perform, call `completionHandler()` in order to proceed with the execution of the rest of the blocks added to the current route.

### Adding a “middleware” block

Typically a middleware is a block that gets executed on a series of paths and is not the end-point of the route.

```objective-c
- (void)addBlock:(CRRouteBlock _Nonnull)block;
```

Calling this method of [`CRServer`](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/CRServer.h) will cause the `block` to be added to all paths on all HTTP methods. Of course the same result could be achieved by calling any other [versions of this method](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/CRServer.h#L50-L53) with the `path` and `HTTPMethod` parameters set to `nil`.

Let’s add a middleware that will set the `Server` [HTTP header](https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.38) on all responses. Useful for bragging rights. 

We will add this before the “Hello world” block, as that one finishes the response.

```objective-c
[self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
    [response setValue:[NSBundle mainBundle].bundleIdentifier forHTTPHeaderField:@"Server"];		
    completionHandler();
}];
```

### Adding Some Logging

Even though the “Hello world” block finishes the response, additional blocks can be added to the route. The only restriction is that they cannot alter the response. It has already been sent.

Let’s add a block that simply does some `NSLog`-ing.

```objective-c
[self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
    NSUInteger statusCode = request.response.statusCode;
    NSString* contentLength = [request.response valueForHTTPHeaderField:@"Content-Length"];
    NSString* userAgent = request.env[@"HTTP_USER_AGENT"];
    NSString* remoteAddress = request.connection.remoteAddress;
    NSLog(@"%@ %@ - %lu %@ - %@", remoteAddress, request, statusCode, contentLength ? : @"-", userAgent);
    completionHandler();
}];
```

All this block does is log some nice info about the request and response to the console.

### To Sum it Up

By this point we have a server running at [http://localhost:10781/]([http://localhost:10781/]), that sets a `Server` header on all responses, says “Hello world” and then `NSLog`s what it has just done.

The **AppDelegate.m** file should look like this:

```objective-c
#import "AppDelegate.h"

@interface AppDelegate () <CRServerDelegate>

@property (nonatomic, strong, nonnull) CRServer* server;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.server = [[CRHTTPServer alloc] init];

    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        [response setValue:[NSBundle mainBundle].bundleIdentifier forHTTPHeaderField:@"Server"];
        completionHandler();
    }];

    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        [response sendString:@"Hello world!"];
        completionHandler();
    } forPath:@"/" HTTPMethod:CRHTTPMethodGET];

    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSUInteger statusCode = request.response.statusCode;
        NSString* contentLength = [request.response valueForHTTPHeaderField:@"Content-Length"];
        NSString* userAgent = request.env[@"HTTP_USER_AGENT"];
        NSString* remoteAddress = request.connection.remoteAddress;
        NSLog(@"%@ %@ - %lu %@ - %@", remoteAddress, request, statusCode, contentLength ? : @"-", userAgent);
        completionHandler();
    }];

    [self.server startListening];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
```

# Doing More Stuff

Our app is now able to perform a basic set of functions but it is far from being ready for deployment in the wilderness of “Hello World!”-craving enthusiasts. Let’s look at some other real world scenarios.

## Serving Static Files

It is conceivable that you will need to serve a file from disk at some point.

```objective-c
- (void)mountStaticDirectoryAtPath:(NSString * _Nonnull)directoryPath forPath:(NSString * _Nonnull)path options:(CRStaticDirectoryServingOptions)options;
```

This method allows “mounting” directories as static file serving  points. The `options` parameter is an bitwise-or’ed list of [`CRStaticDirectoryServingOptions`](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/CRTypes.h#L17-L22) values.

- `CRStaticDirectoryServingOptionsCacheFiles` - use the OS’s disk cache when serving files. (this only applies to files smaller that 512K).
- `CRStaticDirectoryServingOptionsFollowSymlinks` - follow symbolic-links.
- `CRStaticDirectoryServingOptionsAutoIndex` - generates a clickable HTML index of the directory’s contents.
- `CRStaticDirectoryServingOptionsAutoIndexShowHidden` - show hidden files in the auto-generated index.

### Mounting the Directory

We will add a route that serves everything in the current user’s home directory as an auto-generated index, with caching. We’ll add this block before the logging block, in order to give it a chance to set the response headers before we try to log them.

```objective-c
[self.server mountStaticDirectoryAtPath:@"~" forPath:@"/pub" options:CRStaticDirectoryServingOptionsCacheFiles|CRStaticDirectoryServingOptionsAutoIndex];
```

You should be able to see the file list at [http://localhost:10781/pub](http://localhost:10781/pub).

#### CRStaticDirectoryManager

The class responsible for serving the files is [`CRStaticDirectoryManager`](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/CRStaticDirectoryManager.h). 

Static files **under [512K](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/CRStaticDirectoryManager.m#L22)** are read entirely in memory - using or not the OS disk cache, depending on the `CRStaticDirectoryServingOptionsCacheFiles` flag - synchronously within the same context of the route blocks.

Static files **over that threshold** are read in chunks using the [Dispatch I/O Channel API](https://developer.apple.com/library/ios/documentation/Performance/Reference/GCD_libdispatch_Ref/#//apple_ref/doc/uid/TP40008079-CH2-SW73) on a completely separate queue. `CRStaticDirectoryManager`’s route block will call its `completionHandler()` as soon as the I/O channel has been opened and the reading has been queued. In our case, if you are serving a large file, the logging block will be executed before the reading of the file is completed. 

### MIME-Type Hinting

`CRStaticDirectoryManager` uses [`CRMimeTypeHelper`](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/CRMimeTypeHelper.h) in order to determine the value of the `Content-type` [HTTP header](https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.17). It uses the files [UTI](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/CRMimeTypeHelper.m#L56-L86) in order to determine the appropriate value. 

While this algorithm is evolving, you may also specify an explicit value you want to set for a specific extension. 

Let’s specify that `.nfo` files will have the `Content-Type` HTTP header set to `text/plain; charset-utf-8`.

```objective-c
[[CRMimeTypeHelper sharedHelper] setMimeType:@"text/plain; charset=utf-8" forExtension:@"nfo"];
```

## Cookies

Criollo uses [`NSHTTPCookie`](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSHTTPCookie_Class/) class to encapsulate HTTP cookies.   Criollo adds a [category](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/Extensions/NSHTTPCookie%2BCriollo.h) to the `NSHTTPCookie` class, that defines the method `responseHeaderFieldsWithCookies:` in order to create the appropriate response headers.

Criollo manages the cookie store for you, so you don’t have to worry about persisting, deleting expired cookies, etc.

We will create two cookies.
- a session cookie called `session`, which will contain a UUID
- a long lived cookie called `token`, which will expire a long way into the future

For simplicity, we will add this code to the block that sets the `Server` HTTP header.

```objective-c
if ( !request.cookies[@"session"] ) {
	[response setCookie:@"session" value:[NSUUID UUID].UUIDString path:@"/" expires:nil domain:nil secure:NO];
}
[response setCookie:@"token" value:[NSUUID UUID].UUIDString path:@"/" expires:[NSDate distantFuture] domain:nil secure:NO];
```

The [`CRRequest`](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/CRRequest.h#L34) and [`CRResponse`](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/CRResponse.h#L30-L31) cookie APIs are straight-forward.

```objective-c
@property (nonatomic, readonly, nonnull) NSDictionary<NSString *, NSString *> * cookies;
```

```objective-c
- (void)setCookie:(nonnull NSHTTPCookie *)cookie;
- (nonnull NSHTTPCookie*)setCookie:(nonnull NSString *)name value:(nonnull NSString *)value path:(nonnull NSString *)path expires:(nullable NSDate *)expires domain:(nullable NSString *)domain secure:(BOOL)secure;
```

## Setting up a View Controller

*(to be continued)*

## Logging and CRServerDelegate

*(to be continued)*

## Clean Start and Shutdown

*(to be continued)*

# Deployment

Criollo is meant to run on OS X. I have no plans for the near future to make it run on Linux. That being said, there seems to be a sustained effort from the community to port OS X APIs to Linux. As this becomes mature I will look into it.

## Deploying to the Server

The final product will always be an [application bundle](https://developer.apple.com/library/mac/documentation/CoreFoundation/Conceptual/CFBundles/BundleTypes/BundleTypes.html#//apple_ref/doc/uid/10000123i-CH101-SW13), which can be simply deployed to the target server as any other application would be.

A more elegant solution would be deploying from source, using a git hook on the target machine. A deployment script is coming. 

*(to be continued)*

## Integrating with launchd

Launchd is OS X’s builtin process manager. [Wikipedia](http://en.wikipedia.org/wiki/Launchd) defines it as

> a unified, open-source service management framework for starting, stopping and managing daemons, applications, processes, and scripts. Written and designed by Dave Zarzycki at Apple, it was introduced with Mac OS X Tiger and is licensed under the Apache License.

The only thing that you need to make your Criollo application start and stop on launchd commands is to create a [`launchd.plist`](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man5/launchd.plist.5.html) file and place it in `/Library/LaunchDaemons/`. 

Here is an example file for the HelloWorld project described above is this:

**io.criollo.HelloWorld.plist**
```XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Disabled</key>
	<false/>
	<key>KeepAlive</key>
	<true/>
	<key>Label</key>
	<string>io.criollo.HelloWorld</string>
	<key>ProgramArguments</key>
	<array>
		<string>/WebApplications/HelloWorld.app/Contents/MacOS/HelloWorld</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>ServiceDescription</key>
	<string>A simple "Hello World" serving app</string>
	<key>StandardErrorPath</key>
	<string>/var/log/io.criollo.HelloWorld.log</string>
	<key>StandardOutPath</key>
	<string>/var/log/io.criollo.HelloWorld.log</string>
</dict>
</plist>
```

The example above assumes the app will be deployed at `/WebApplications/HelloWorld.app`.

Read more about launchd plists in the `launchd.plist(5)` man page.

## Starting and Stopping

You can then start and stop the app using [`launchctl`](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/launchctl.1.html) as follows.

```bash
sudo launchctl load /Library/LaunchDaemons/io.criollo.HelloWorld.plist

sudo launchctl unload /Library/LaunchDaemons/io.criollo.HelloWorld.plist
```

Read more about launchctl in the `launchctl(1)` man page.

# Examples

There following examples are available:

[**HelloWorld**](https://github.com/thecatalinstan/Criollo/tree/master/Examples/HelloWorld). The full code of the example developed in this primer.

[**HelloWorld-ObjC**](https://github.com/thecatalinstan/Criollo/tree/master/Examples/HelloWorld-ObjC) and [**HelloWorld-Swift**](https://github.com/thecatalinstan/Criollo/tree/master/Examples/HelloWorld-Swift). Two standalone launchd daemons. The same exact functionality is replicated in Objective-C and Swift.

[**HelloWorld-MultiTarget**](https://github.com/thecatalinstan/Criollo/tree/master/Examples/HelloWorld-MultiTarget). This example creates a launchd daemon app, an iOS app and an OS X app, using a shared code-base. 

# Work in Progress

Criollo is work in progress and - as such - it’s not ready for the wild yet. The reason for this is mainly missing functionality and sheer lack of documentation[^It is also very high on my list of priorities, but sadly still a “to-do” item].

The existing APIs are relatively stable and are unlikely to change dramatically unless marked as such.

## Missing Biggies

1. **Multipart request body parsing**. Criollo can handle JSON and URL-encoded bodies for now. Upcoming and in progress is the `multipart/form-data` request parsing.
2. **Binary / MIME body**. Requests that send binary data completely ignore this for now. This implementation is on the way, right after multipart.
3. **HTTPS** - The workaround for this is putting your app behind a  web server, like Nginx, and using the web-server as a reverse HTTP proxy or FastCGI client. Here’s an example of how to setup nginx to [reverse proxy HTTP requests](https://www.nginx.com/resources/wiki/start/topics/examples/reverseproxycachingexample/) and here’s how to [set up FastCGI](https://www.nginx.com/resources/wiki/start/topics/examples/fastcgiexample/#connecting-nginx-to-the-running-fastcgi-process).

## Get in Touch

If you have any **questions** regarding the project or **how to** do anything with it, please feel free to get in touch either on Twitter [@criolloio](https://twitter.com/criolloio) or by plain old email [criollo@criollo.io](mailto:criollo@criollo.io).

I really encourage you to [submit an issue](https://github.com/thecatalinstan/Criollo/issues/new), as your input is really and truly appreciated.
