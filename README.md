

[![Criollo](https://criollo.io/res/doc/images/criollo-github.png)](https://criollo.io/)

#### A powerful Cocoa based web application framework for macOS, iOS and tvOS.

[![Build Status](https://travis-ci.org/thecatalinstan/Criollo.svg?branch=master)](https://travis-ci.org/thecatalinstan/Criollo) [![Version Status](https://img.shields.io/cocoapods/v/Criollo.svg?style=flat)](http://cocoadocs.org/docsets/Criollo)  [![Platform](http://img.shields.io/cocoapods/p/Criollo.svg?style=flat)](http://cocoapods.org/?q=Criollo) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![MIT License](https://img.shields.io/badge/license-MIT-orange.svg?style=flat)](https://opensource.org/licenses/MIT) [![Twitter](https://img.shields.io/badge/twitter-@criolloio-orange.svg?style=flat)](http://twitter.com/Criolloio) [![Gitter](https://img.shields.io/gitter/room/criollo-io/Lobby.svg?style=flat)](https://gitter.im/criollo-io/Lobby)


Criollo helps create fast standalone or embedded web apps that deliver content directly over HTTP or FastCGI. You can write code in Swift or Objective-C and you can use the Cocoa technologies you already know. 

It's as easy as this:

```swift
let server = CRHTTPServer()
server.get("/") { (req, res, next) in
  res.send("Hello world!")
}
server.startListening()
```

... and in Objective-C:

```objective-c
CRServer* server = [[CRHTTPServer alloc] init];
[server get:@"/" block:^(CRRequest *req, CRResponse *res, CRRouteCompletionBlock next) {
  [res send:@"Hello world!"];
}];
[server startListening];
```

# Key Features

Criollo is designed with speed, security and flexibility in mind, that's why it comes with a few very useful features out of the box, thus allowing you to focus on the actual job your project needs to do, without having to jump through hoops in order to make it happen.

### HTTPS

Criollo fully supports HTTPS on all platforms. You can pass the credentials as a PKCS#12 identity and password, or an X509 certificate and private key pair, either PEM or DER encoded. 

```swift
server.isSecure = true

// Credentials: PKCS#12 Identity and password
server.identityPath = Bundle.main.path(forResource: "identity", ofType: "p12")
server.password = "123456"

// Credentials: PEM-encoded certificate and public key
server.certificatePath = Bundle.main.path(forResource: "certificate", ofType: "pem")
server.certificateKeyPath = Bundle.main.path(forResource: "key", ofType: "pem")

// Credentials: DER-encoded certificate and public key
server.certificatePath = Bundle.main.path(forResource: "certificate", ofType: "der")
server.certificateKeyPath = Bundle.main.path(forResource: "key", ofType: "der")
```

... and in Objective-C:

```objective-c
server.isSecure = YES;
        
// Credentials: PKCS#12 Identity and password
server.identityPath = [NSBundle.mainBundle pathForResource:@"identity" ofType:@"p12"];
server.password = @"password";
        
// Credentials: PEM-encoded certificate and public key
server.certificatePath = [NSBundle.mainBundle pathForResource:@"certificate" ofType:@"pem"];
server.certificateKeyPath = [NSBundle.mainBundle pathForResource:@"key" ofType:@"pem"];
        
// Credentials: DER-encoded certificate and public key
server.certificatePath = [NSBundle.mainBundle pathForResource:@"certificate" ofType:@"der"];
server.certificateKeyPath = [NSBundle.mainBundle pathForResource:@"key" ofType:@"der"];
```

### Routing

When defining routes, paths can be specified in three ways:

- **Fixed string** (ex. `/api`). This will match the string exactly.
- **Placeholders** (ex. `/posts/:pid`). The next path component after `/posts`, will be matched and added to `request.query` under the `pid` key.
- **Regex patterns** (ex. `/[0-9]{4}/[0-9]{1,2}/[a-zA-Z0-9-]+`). When the three patterns are matched, they are added to `request.query`, under the keys `0`, `1` and `2` respectively.

```swift
server.add("/api") { (req, res, next) in
  // /api/?pid=12345
  res.send(req.query)
}

server.add("/posts/:pid") { (req, res, next) in
  // /posts/12345
  res.send(req.query)
}

server.add("/[0-9]{4}/[0-9]{1,2}/[a-zA-Z0-9-]+") { (req, res, next) in
  // /2017/10/my-first-criollo-app
  res.send(req.query)
}
```

... and in Objective-C:

```objective-c
[server add:@"/api" block:^(CRRequest *req, CRResponse *res, CRRouteCompletionBlock next) {
  // /api/?pid=12345
  [res send:req];
}];

[server add:@"/posts/:pid" block:^(CRRequest *req, CRResponse *res, CRRouteCompletionBlock next) {
  // /posts/12345
  [res send:req];
}];

[server add:@"/[0-9]{4}/[0-9]{1,2}/[a-zA-Z0-9-]+" block:^(CRRequest *req, CRResponse *res, CRRouteCompletionBlock next) {
  // /2017/10/my-first-criollo-app
  [res send:req];
}];
```

### Controllers
Controllers provide a very simple way of grouping functionality into one semantical unit. They function as routers and allow you to define routes based on paths relative to the path they are themselves attached to.

```swift
// The controller class
class APIController : CRRouteController {
  override init(prefix: String) {
    super.init(prefix: prefix)
    
    self.add("/status") { (req, res, next) in
      res.send(["status": true])
    }
    
  }
}

// Add the controller to the server
server.add("/api", controller:APIController.self)
```

... and in Objective-C:

```objective-c
// The controller class
@interface APIController : CRRouteController
@end

@implementation APIController

- (instancetype)initWithPrefix:(NSString *)prefix {
  self = [super initWithPrefix:prefix];
  if ( self != nil ) {
    
    [self add:@"/status" block:^(CRRequest *req, CRResponse *res, CRRouteCompletionBlock next) {
      [res send:@{@"status": @YES}];
    }];
         
  }
}

@end

// Add the controller to the server
[server add:@"/api" controller:APIController.class];
```

### Views and View Controllers

View controllers render view objects, constructed from HTML resource files by calling the view's `render` method. This is achieved by the `CRViewConroller`, `CRView` and `CRNib` APIs respectively.

View controllers are powerful objects that allow you to easily standardise an app's appearance and group functionality together into a coherent unit.

HTML template file:
```html
<!-- Define some placeholders -->
<!DOCTYPE html>
  <html lang="en">
  <head>
    <title>{{title}}</title>
  </head>
  <body>
    <h1>{{title}}</h1>
    <p>{{content}}</p>
  </body>
</html>
```

Source code:
```swift
// The view controller class
class HelloWorldViewController: CRViewController {
  
  override func present(with request: CRRequest, response: CRResponse) -> String {
    self.vars["title"] = String(describing: type(of: self))
    self.vars["content"] = "Hello from the view controller."

    return super.present(with: request, response: response)
  }
  
}

// Add the view controller to server
server.add("/controller", viewController: HelloWorldViewController.self, withNibName: "HelloWorldViewController", bundle: nil)
```

... and in Objective-C:

```objective-c
// The view controller class
@interface HelloWorldViewController : CRViewController
@end

@implementation HelloWorldViewController

- (NSString *)presentViewControllerWithRequest:(CRRequest *)request response:(CRResponse *)response {
    self.vars[@"title"] = NSStringFromClass(self.class);
    self.vars[@"content"] = @"Hello from the view controller.";

    return [super presentViewControllerWithRequest:request response:response];
}

@end

// Add the view controller to server
[server add:@"/controller" viewController:HelloWorldViewController.class withNibName:@"HelloWorldViewController" bundle:nil];
```

### Static File/Directory Serving
Criollo comes with built-in support for exposing both directories and individual over HTTP. The `CRStaticFileManager` and `CRStaticDirectoryManager` APIs enable you to do this.

```swift
// Expose the home directory (with auto-indexing)
server.mount("/pub", directoryAtPath: "~", options: [.autoIndex])

// Serve a single static file at a path
server.mount("/info.plist", fileAtPath:  Bundle.main.bundlePath.appending("/Info.plist"))
```

... and in Objective-C

```objective-c
// Expose the home directory (with auto-indexing)
[server mount:@"/pub" directoryAtPath:@"~" options:CRStaticDirectoryServingOptionsAutoIndex];
   
// Serve a single static file at a path 
[server mount:@"/info.plist" fileAtPath:[NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"/Contents/Info.plist"]];
```

### Multipart File Uploads

Criollo comes with builtin support for handling `multipart/form-data` POST requests, so that you can handle HTML file uploads out of the box. Uploaded files are provided in `request.files`, as an array of `CRUploadedFile` objects.

```swift
// Serve the first uploaded file back to the client
self.server.post("/image") { (req, res, next) in
  do {
    let data = try Data.init(contentsOf: (req.files!["0"]?.temporaryFileURL)!)
    res.setValue(req.env["HTTP_CONTENT_TYPE"]!, forHTTPHeaderField: "Content-type")
    res.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")
    res.send(data)
  } catch {
    res.setValue("text/plain", forHTTPHeaderField: "Content-type")
    res.setValue("\(error.localizedDescription.count)", forHTTPHeaderField: "Content-length")
    res.send(error.localizedDescription)
  }
}
```

... and in Objective-C

```objective-c
// Serve the first uploaded file back to the client
[server post:@"/image" block:^(CRRequest *req, CRResponse *res, CRRouteCompletionBlock next) {
  NSError *error;
  NSData *data = [NSData dataWithContentsOfURL:req[0].temporaryFileURL options:0 error:&error];
  if ( error ) {
    [res setValue:@"text/plain" forHTTPHeaderField:@"Content-type"];
    [res setValue:@(error.description.length).stringValue forHTTPHeaderField:@"Content-length"];
    [res sendString:error.description];
  } else {
    [res setValue:request.env[@"HTTP_CONTENT_TYPE"] forHTTPHeaderField:@"Content-type"];
    [res setValue:@(data.length).stringValue forHTTPHeaderField:@"Content-length"];
    [res sendData:data];
  }
}];
```

## Why?

Criollo was created in order to take advantage of the truly awesome tools and APIs that the Apple stack provides and serve content produced with them over the web. 

It incorporates an HTTP web server and a [FastCGI](https://fast-cgi.github.io/) application server that are used to deliver content. The server is built on Grand Central Dispatch and designed for *speed*.

## How to Use

Criollo can easily be embedded as a web-server inside your macOS, iOS or tvOS app, should you be in need of such a feature, however it was designed to create standalone, long-lived daemon style apps. It is fully [`launchd`](http://launchd.info/) compatible and replicates the lifecycle and behavior of `NSApplication`, so that the learning curve should be as smooth as possible. 

For a more real-world example, check out the [criollo.io](https://criollo.io) website, made using Criollo and available for your cloning pleasure at [https://github.com/thecatalinstan/Criollo-Web](https://github.com/thecatalinstan/Criollo-Web).

See the [Hello World Multi Target example](https://github.com/thecatalinstan/Criollo/tree/master/Examples/HelloWorld-MultiTarget) for a demo of the two usage patterns.

## Getting Started

- Read the [“Getting Started” guide](https://github.com/thecatalinstan/Criollo/wiki/Getting-Started) and move further with the [“Doing More Stuff” guide](https://github.com/thecatalinstan/Criollo/wiki/Doing-More-Stuff)
- Check out the [Examples](https://github.com/thecatalinstan/Criollo/tree/master/Examples)
- Check out the [API Reference](http://cocoadocs.org/docsets/Criollo/) for a look at the APIs available
- Learn how to deploy your Criollo apps in the [“Deployment” guide](https://github.com/thecatalinstan/Criollo/wiki/Deployment)
- Check out the [Criollo Blog](https://criollo.io/blog) for news, ideas and updates on Criollo.

## Installing

The preferred way of installing Criollo is through [CocoaPods](http://cocoapods.org). However, you can also embed the framework in your projects manually.

### Installing with CocoaPods

1. Create the `Podfile` if you don’t already have one. You can do so by running `pod init` in the folder of the project.
2. Add Criollo to your `Podfile`. `pod 'Criollo', '~> 0.4’`
3. Run `pod install`

Please note that Criollo will download [CocoaAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket) as a dependency.

### Cloning the repo

Criollo uses [CocoaAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket) which is included as a git submodule

```bashh
git clone --recursive https://github.com/thecatalinstan/Criollo.git
```

## Get in Touch

If you have any **questions** regarding the project or **how to** do anything with it, please feel free to get in touch either on Twitter [@criolloio](https://twitter.com/criolloio) or by plain old email [criollo@criollo.io](mailto:criollo@criollo.io).

I really encourage you to [submit an issue](https://github.com/thecatalinstan/Criollo/issues/new), as your input is really and truly appreciated.

---

Check out the [Criollo Blog](https://criollo.io/blog) for news, ideas and updates on Criollo.
