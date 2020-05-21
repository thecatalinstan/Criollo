# Examples

Here’s a list of the examples to help you get started.

## Hello World

This example contains the full code of the “Hello World” app developed in the [“Getting Started” guide](https://github.com/thecatalinstan/Criollo/wiki/Getting-Started).

- [https://github.com/thecatalinstan/Criollo/tree/master/Examples/HelloWorld](https://github.com/thecatalinstan/Criollo/tree/master/Examples/HelloWorld). 

## HelloWorld-ObjC and HelloWorld-Swift

These are two standalone `launchd` daemons. The same exact functionality is replicated in Objective-C and Swift.

- [https://github.com/thecatalinstan/Criollo/tree/master/Examples/HelloWorld-ObjC](https://github.com/thecatalinstan/Criollo/tree/master/Examples/HelloWorld-ObjC)
- [https://github.com/thecatalinstan/Criollo/tree/master/Examples/HelloWorld-Swift](https://github.com/thecatalinstan/Criollo/tree/master/Examples/HelloWorld-Swift). 

## HelloWorld-MultiTarget

This example creates a `launchd` daemon app, an iOS app, a tvOS app and a macOS Cocoa app, using a shared code-base. The code structure in this one is a little more complicated, as it needs to reuse the same code base for different targets.

You should have previous knowledge of developing for the platforms as well as of creating multi-platform projects to make understanding this example easier.

- [https://github.com/thecatalinstan/Criollo/tree/master/Examples/HelloWorld-MultiTarget](https://github.com/thecatalinstan/Criollo/tree/master/Examples/HelloWorld-MultiTarget).

## HTTPAuthentication

This example showns a possible way of implementing an authentication _filter_. It uses basic HTTP authentication, but
the logic canbeapplied to virtually any authentication method.

The main idea is to add the `CRRouteBlock` that performs the authentication (validation/challenge) on all the route paths that will require it, and to NOT proceed with the route, unless authorization succeeds. This effectively means not calling the `CRRouteCompletionBlock` if authentication fails.

- [https://github.com/thecatalinstan/Criollo/tree/master/Examples/HTTPAuthentication](https://github.com/thecatalinstan/Criollo/tree/master/Examples/HTTPAuthentication).


## LongRequest

This example demonstrates how to handle requests that could potentially take longer that the builtin time limit to complete.

- [https://github.com/thecatalinstan/Criollo/tree/master/Examples/LongRequest](https://github.com/thecatalinstan/Criollo/tree/master/Examples/LongRequest)

## SecureHTTPServer

This example demonstrates how to setup an HTTPS server in an iOS app. The same of setting up a secure web server is also valid for an Apple TV app or  a Mac app, be it Cocoa or `launchd`, Swift or Objective-C.

- [https://github.com/thecatalinstan/Criollo/tree/master/Examples/SecureHTTPServer](https://github.com/thecatalinstan/Criollo/tree/master/Examples/SecureHTTPServer)

## ServerStats

This example illustrates how to embed a Criollo HTTP server inside a macOS Cocoa app. It also shows how you can control and get info about the server from the app and display it to the user.

- [https://github.com/thecatalinstan/Criollo/tree/master/Examples/ServerStats](https://github.com/thecatalinstan/Criollo/tree/master/ServerStats)

---

Check out the [Criollo Blog](https://criollo.io/blog) for news, ideas and updates on Criollo.
