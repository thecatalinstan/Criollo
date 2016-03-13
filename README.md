
<p align="center" >
  <img src="https://criollo.io/res/doc/images/criollo.png" alt="Criollo" title="Criollo"/>
</p>

A powerful Cocoa based web application framework for OS X and iOS.

[![Version Status](https://img.shields.io/cocoapods/v/Criollo.svg?style=flat)](http://cocoadocs.org/docsets/Criollo)  [![Platform](http://img.shields.io/cocoapods/p/Criollo.svg?style=flat)](http://cocoapods.org/?q=Criollo) [![license Public Domain](https://img.shields.io/badge/license-Public%20Domain-orange.svg?style=flat)](https://en.wikipedia.org/wiki/Public_domain) [![Twitter](https://img.shields.io/badge/twitter-@Criolloio-orange.svg?style=flat)](http://twitter.com/Criolloio)

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

## Getting Started

- [Download Criollo](https://github.com/thecatalinstan/Criollo/archive/master.zip) and try out the included OSX and iOS example apps
- Read the [“Getting Started” guide](https://github.com/thecatalinstan/Criollo/wiki/Getting-Started) and move further with the [“Doing More Stuff” guide](https://github.com/thecatalinstan/Criollo/wiki/Doing-More-Stuff)
- Learn how to deploy your Criollo apps in the [“Deployment” guide](https://guthub.com/thecatalinstan/Criollo/wiki/Deployment)
- Check out the [documentation](http://cocoadocs.org/docsets/Criollo/) for a look at the APIs available

## Installing

The preferred way of installing Criollo is through [CocoaPods](http://cocoapods.org). However, you can also embed the framework in your projects manually.

### Installing with CocoaPods

1. Create the Podfile if you don’t already have one. You can do so by running `pod init` in the folder of the project.
2. Add Criollo to your Podfile. `pod 'Criollo', '~> 0.1.7’`
3. Run `pod install`

Please note that Criollo will download [CocoaAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket) as a dependency.

## Work in Progress

Criollo is work in progress and - as such - it’s not ready for the wild yet. The reason for this is mainly missing functionality and sheer lack of documentation[^It is also very high on my list of priorities, but sadly still a “to-do” item].

The existing APIs are relatively stable and are unlikely to change dramatically unless marked as such.

### Missing Biggies

1. **Multipart request body parsing**. Criollo can handle JSON and URL-encoded bodies for now. Upcoming and in progress is the `multipart/form-data` request parsing.
2. **Binary / MIME body**. Requests that send binary data completely ignore this for now. This implementation is on the way, right after multipart.
3. **HTTPS** - The workaround for this is putting your app behind a  web server, like Nginx, and using the web-server as a reverse HTTP proxy or FastCGI client. Here’s an example of how to setup nginx to [reverse proxy HTTP requests](https://www.nginx.com/resources/wiki/start/topics/examples/reverseproxycachingexample/) and here’s how to [set up FastCGI](https://www.nginx.com/resources/wiki/start/topics/examples/fastcgiexample/#connecting-nginx-to-the-running-fastcgi-process).

## Get in Touch

If you have any **questions** regarding the project or **how to** do anything with it, please feel free to get in touch either on Twitter [@criolloio](https://twitter.com/criolloio) or by plain old email [criollo@criollo.io](mailto:criollo@criollo.io).

I really encourage you to [submit an issue](https://github.com/thecatalinstan/Criollo/issues/new), as your input is really and truly appreciated.
