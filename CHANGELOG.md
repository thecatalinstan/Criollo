# Change Log

This file includes all notable changes to Criollo. Please consult this file for the specifics, before you upgrade.

Criollo uses [Semantic Versioning](http://semver.org/).

---

## [0.5.3](https://github.com/thecatalinstan/Criollo/releases/tag/0.5.3) (04/04/2018)

**Released on Wednesday, April 4, 2018**. This is a service release that adds Travis CI pod validation and splits the bundled OpenSSL libraries into a different submodule.

No APIs are changed.

## [0.5.2](https://github.com/thecatalinstan/Criollo/releases/tag/0.5.2) (04/02/2018)

**Released on Monday, April 2, 2018**. This is a service release that adds Travis CI.

## [0.5.1](https://github.com/thecatalinstan/Criollo/releases/tag/0.5.1) (03/31/2018)

**Released on Saturday, March 31, 2018**. This is a service release that fixes Xcode 9.3 warnings.

##  [0.5.0](https://github.com/thecatalinstan/Criollo/releases/tag/0.5.0) (03/27/2018)

**Released on Tuesday, March 27, 2018**. This release makes Criollo available for tvOS, adds HTTPS support on all platforms, implements a number of tests, as well as addresses a number of bugs.

## [0.4.17](https://github.com/thecatalinstan/Criollo/releases/tag/0.4.17) (07/26/2017)

**Released on Wednesday, July 26, 2017**. This is a maintenance and update release that aims to address various issues arising from Xcode and SDK updates.

## [0.4.16](https://github.com/thecatalinstan/Criollo/releases/tag/0.4.16) (03/21/2017)

**Released on Tuesday, March 21, 2017**. This is a hot-fix release that handles a potential issue when running Criollo servers on iOS devices whereby response data would be buffered instead of sent to the client, thus making it seem like the server was stalling.

#### Fixed

* A racing condition occurred in `[CRConnection sendDataToSocket:forRequest:]`, by which the request would be removed from the current connection’s requests array before the response was sent, thereby causing the execution to enter the *buffering* code path instead of actually sending the data. This has been fixed by adding an additional check for the length of the array. [`6b7f51d`](https://github.com/thecatalinstan/Criollo/commit/6b7f51d69f79adcad6fe7c4ebc49539a490c7d76)

## [0.4.15](https://github.com/thecatalinstan/Criollo/releases/tag/0.4.15) (03/11/2017)

**Released on Sunday, March 11, 2017**. This is a hot-fix release that ensures Carthage compatibility and eliminates some potential warnings related to code formatting standards.

#### Fixed

* Missing shared build schemes were added to ensure Carthage compatibility. [`69e2b75`](https://github.com/thecatalinstan/Criollo/commit/69e2b751b80a6758d04ff5aaa8d24e3ea773ce29)

* Missing new lines at the end of header files were added. [`294e844`](https://github.com/thecatalinstan/Criollo/commit/294e844b261219e90bf0939d63c9ba0fa29bb5fe)

## [0.4.14](https://github.com/thecatalinstan/Criollo/releases/tag/0.4.14) (02/15/2017)

**Released on Wednesday, February 15, 2017**. This is a hot-fix release that closes issue [\#7](https://github.com/thecatalinstan/Criollo/issues/7) that caused incorrect relative path resolution for `NSDirectoryManager` routes mounted at the root path, as well as tweaking some auto-indexing functionality.

#### Fixed

* The resolution of relative paths was attempted also for static routes mounted at `/`, which led to an incorrect result, since the relative path is always the same as the requested path. [`1a1beb4`](https://github.com/thecatalinstan/Criollo/commit/1a1beb4b99c022b1e85a919143fd05d8f13cfdf2)

* Do not display the `../` link for auto-indexed directories when we are at the top level of the mount path. [`858693c`](https://github.com/thecatalinstan/Criollo/commit/858693c44d3fca302c1395c8b30f5567e58dbbbd)

* Fix the generation of auto-indexed links for `NSDirectoryManager` routes mounted at the root path. There was an extra `/` added to the top level link href. [`4ea82e7`](https://github.com/thecatalinstan/Criollo/commit/4ea82e76ff0fcdecb20a26dee93b5dba9fb7bbbc)

## [0.4.13](https://github.com/thecatalinstan/Criollo/releases/tag/0.4.13) (01/10/2017)

**Released on Tuesday, January 10, 2017**. This is a hot-fix release that closes an issue introduced in [`144fab1`](https://github.com/thecatalinstan/Criollo/commit/144fab1c83664fb6408d964d15e4fbb5f1f9d96c) where query string params that do not have a value cause an unhandled exception.

#### Fixed

* An index out bounds exception was raised in the URL encoded string parsing block if the key value pair did not have a value. There is now a check to prevent that. [`f41fb06`](https://github.com/thecatalinstan/Criollo/commit/f41fb06a59135bbee2cfb558e3dc0475b3f27e98)

## [0.4.12](https://github.com/thecatalinstan/Criollo/releases/tag/0.4.12) (01/10/2017)

**Released on Tuesday, January 10, 2017**. This is a hot-fix release that closes an issue that could cause invalid URL-encoded parameters to be lost.

#### Fixed

* When decoding URL-encoded strings, `CRRequest` would remove the keys or values that would not properly decode using `stringByRemovingPercentEscapes`. The current implementation attempts to also pass these strings through `stringByDecodingURLEncodedString` so that some intermediate representation can be salvaged. [`144fab1`](https://github.com/thecatalinstan/Criollo/commit/144fab1c83664fb6408d964d15e4fbb5f1f9d96c)

## [0.4.11](https://github.com/thecatalinstan/Criollo/releases/tag/0.4.11) (01/09/2017)

**Released on Monday, January 9, 2017**. This is a hot-fix release that fixes a bug introduced in version  0.4.8, that could cause premature response termination for certain async operations performed inside nested routers (`CRViewController` or `CRRouteController`).

#### Fixed

* Built-in `CRRouter` subclasses would call the route block’s `completionHandler` right after calling `executeRoutes:resquest:response:withNotFoundBlock:`. This is not valid for routes that perform any async operations and are defined as the last route in the path, as the `completionHandler` gets invoked before the async operation has ended, thus causing the response to finish, causing an `NSInternalInconsistencyException`. [`844cb5f`](https://github.com/thecatalinstan/Criollo/commit/844cb5f9dfd4450e9adaa676a5881a7849b1c787)

## [0.4.10](https://github.com/thecatalinstan/Criollo/releases/tag/0.4.10) (11/11/2016)

**Released on Friday, November 11, 2016**. This release implements MIME (binary) request body parsing.

#### Added

* [`CRRequest`] now automatically parses MIME (binary) request bodies. After parsing such a request, the `files` property will be a dictionary containing the uploaded file as its first value (the key is “0”). Uploaded files are deleted from their temporary location when the `CRRequest` object is deallocated.

## [0.4.9](https://github.com/thecatalinstan/Criollo/releases/tag/0.4.9) (10/24/2016)

**Released on Monday, October 24, 2016**. This is a hot-fix release that fixes a bug introduced in version  0.4.7, that caused routes defined within CRViewControllers to not be resolved correctly.

#### Fixed

* `CRViewController initWithNibName:bundle:prefix` now passes along the correct prefix instead of the default. [`57d71d9`](https://github.com/thecatalinstan/Criollo/commit/57d71d95a9503e42b305a53106e50b3face1784b)

## [0.4.8](https://github.com/thecatalinstan/Criollo/releases/tag/0.4.8) (10/24/2016)

**Released on Monday, October 24, 2016**. This is a hot-fix release that ensures that all responses are finished.

#### Fixed

* `CRRouter` now makes sure that the response is finished once all blocks have been executed. Also, if no data has been sent, the default error handling block will be invoked. The net result of this is that a 404 response will be sent for all request paths that do not actually send something back to the client. [`4f3d0ec`](https://github.com/thecatalinstan/Criollo/commit/4f3d0ec14135854b6a873e83b61dca51ba62ddf2)

## [0.4.7](https://github.com/thecatalinstan/Criollo/releases/tag/0.4.7) (10/24/2016)

**Released on Monday, October 24, 2016**. This is a hot-fix release that addresses failed server initialization when no SSL certificates are provided.

## [0.4.6](https://github.com/thecatalinstan/Criollo/releases/tag/0.4.6) (10/23/2016)

**Released on Sunday, October 23, 2016**. This release implements `multipart/form-data` request body parsing and HTTPS on macOS.

#### Added

* [`CRRequest`] now automatically parses `multipart/formdata` request bodies. After parsing such a request, the `body` property will be a dictionary containing the parsed properties and the `files` property will be a dictionary containing the uploaded files. Uploaded files are deleted from their temporary location when the `CRRequest` object is deallocated.
* [`CRTPServer`] can now deliver content over HTTPS (macOS only). Use the `isSecure`, `certificatePath` and `certificateKeyPath` properties to configure the HTTPS server. Both the key and the certificate bundle are expected to be in PEM format.

## [0.4.5](https://github.com/thecatalinstan/Criollo/releases/tag/0.4.5) (09/12/2016)

**Released on Monday, September 12, 2016**. This release removes CRNib and CRView caching in favor of OS filesystem memory mapping.

## [0.4.4](https://github.com/thecatalinstan/Criollo/releases/tag/0.4.4) (09/07/2016)

**Released on Wednesday, September 7, 2016**. This release includes memory allocation and performance improvements. No API were changed.

## [0.4.1](https://github.com/thecatalinstan/Criollo/releases/tag/0.4.1) (07/26/2016)

**Released on Tuesday, July 26, 2016**. This is a hot-fix release.

#### Fixed
A bug in `CRRoute` that could cause incorrect (greedy) matching of regex path specs. [`a2b0470`](https://github.com/thecatalinstan/Criollo/commit/a2b047072445d087d3e1223e662c9dd6c42f86f7)

## [0.4.0](https://github.com/thecatalinstan/Criollo/releases/tag/0.4.0) (07/26/2016)

**Released on Tuesday, July 26, 2016**. This is a major overhaul of the routing mechanism.

#### Changed

The whole routing subsystem has been changed. The public API’s have also been changed. Check out the `CRRouter` documentation at: [http://cocoadocs.org/docsets/Criollo/0.4.0/Classes/CRRouter.html](http://cocoadocs.org/docsets/Criollo/0.4.0/Classes/CRRouter.html)

## [0.3.1](https://github.com/thecatalinstan/Criollo/releases/tag/0.3.1) (07/25/2016)

**Released on Monday, July 25, 2016**. This is a hot-fix release.

#### Fixed

* A bug in `CRRouteController` that affected the resolution of relative paths. [`f952862`](https://github.com/thecatalinstan/Criollo/commit/f952862b00978eb3eeff1345ca03e09450ccd524)

## [0.3.0](https://github.com/thecatalinstan/Criollo/releases/tag/0.3.0) (07/25/2016)

**Released on Monday, July 25, 2016**. This release has significant API changes. It’s main focus is on extending the functionality of the [`CRRouter`](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/Routing/CRRouter.h) API introduced in version 0.2.0.

The core router logic has been re-written. Also now you can define routes using regular expressions, variable replacements.

#### Added

* [`CRRouter`](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/Routing/CRRouter.h#L28-L37) now has a series of convenience methods for adding blocks to routes. This should make the code much cleaner and it looks damn good in swift. [`7ad5d9ae`](https://github.com/thecatalinstan/Criollo/commit/7ad5d9ae1cd0ca16a3d51870267c67c80b980822)

#### Changed APIs

* All methods containing `HTTPMethod:` in their signatures have been refactored to include `method:`. This affects [`CRRouter`](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/Routing/CRRouter.h). [`c3a4974`](https://github.com/thecatalinstan/Criollo/commit/c3a4974dc9b83518a33052550c4c6a771e953461)

## [0.2.0](https://github.com/thecatalinstan/Criollo/releases/tag/0.2.0) (07/21/2016)

**Released on Thursday, July 21, 2016**. This release has significant API changes and it is meant to ease development for more “real-life” scenarios.

#### Added

* [`CRRouter`](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/Routing/CRRouter.h) is base-class for routing. Functionality previously implemented by `CRServer` is now implemented by this class. `CRServer` now inherits from [`CRRouter`](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/Routing/CRRouter.h). [`10165eb3`](https://github.com/thecatalinstan/Criollo/commit/10165eb3c4627a468e203a1fea566d18da0ba812)
* [`CRRouteController`](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/Routing/CRRouteController.h) is meant to delegate control over a particular set of routes. It is mean for implementing more complex routing patterns. [`CRRouteController`](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/Routing/CRRouteController.h) inherits from [`CRRouter`](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/Routing/CRRouter.h) so it also can define and implement its own routes, relative to the path it was mounted at. [`4dfe99ee`](https://github.com/thecatalinstan/Criollo/commit/4dfe99ee3e10b204214eadfd5d7a9d0de1c5de42)
* The [`CRResponse redirectToURL:statusCode:finish:`] and [`CRResponse redirectToLocation:statusCode:finish:`] methods which control wether the response should be finished after the redirect header is set. [`ba7c915b`](https://github.com/thecatalinstan/Criollo/commit/ba7c915bb4bdb7654af8df872f344bbeb884c621)

#### Changed APIs

* [`CRViewController`](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/Routing/CRViewController.h) now inherits from [`CRRouteController`](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/Routing/CRRoute.h) so it is a router as well. [`4daf1415`](https://github.com/thecatalinstan/Criollo/commit/4daf1415b12c35417ead4bafedb7c721d27335ae)
* The [`templateVariables`] property of [`CRViewController`] has been renamed to [`vars`]. [`ddbbdbaf`](https://github.com/thecatalinstan/Criollo/commit/ddbbdbafa2cb0900b252bddb49114d1f235d2afa)

## [0.1.14](https://github.com/thecatalinstan/Criollo/releases/tag/0.1.14) (04/14/2016)

**Released on Tuesday, April 14, 2016**. This is a maintenance release. The main thing is that the internal structure of the Xcode project has been changed. There is now only one module name `Criollo` for both iOS and OSX.

## [0.1.13](https://github.com/thecatalinstan/Criollo/releases/tag/0.1.13) (04/05/2016)

**Released on Tuesday, April 5, 2016**. This release focuses on optimizing memory usage, stability and generally speaking *speed*. It also includes some API changes to make developers’ lives easier.

### Changed APIs

* Added a callback to `[CRServer closeAllConnections]`, thus becoming `[CRServer closeAllConnections:(dispatch_block_t _Nullable)completion]`. [`538d4ce`](https://github.com/thecatalinstan/Criollo/commit/538d4ce024f961aed239698bb7947fe01f6d1673).

### Additions and Improvements

* Added signal handler in `CRApplication` for `SIGINT`, `SIGTSTP` and `SIGQUIT`. [`1c2500b`](https://github.com/thecatalinstan/Criollo/commit/1c2500b2a1965db25199f06577702c0bd99d366b).
* String parsing in request headers is now done without excessive `memcpy` operations both for HTTP and FastCGI.
* Both OS X and iOS frameworks are now developed with embedded apps. The OS X framework’s app is written in Objective-C, whilst   the iOS app is written in Swift.
* All examples now use Criollo as a pod.

### Fixed

* Fixes a racing condition that could cause a crash when closing a connection that handles a large number of concurrent requests. [`7f90600`](https://github.com/thecatalinstan/Criollo/commit/7f906008611fb64d70558c18230fbcad7a1c27bf)


## [0.1.12](https://github.com/thecatalinstan/Criollo/releases/tag/0.1.12) (03/15/2016)

**Released on Tuesday, March 15, 2016**.

### Fixed

* Missing support for the `HEAD` HTTP request method. [`dbdbe30`](https://github.com/thecatalinstan/Criollo/commit/dbdbe3047d9d374f9ef69869b1903876cb67dab8)

## [0.1.11](https://github.com/thecatalinstan/Criollo/releases/tag/0.1.11) (03/15/2016)

**Released on Tuesday, March 15, 2016**.

### Fixed

* Potential crash when `CRConnection` is deallocated. [`a052003`](https://github.com/thecatalinstan/Criollo/commit/a05200328e98c81d1455a4536cc9c832518c68af)
* `response.HTTPCookie` dictionary was not initialized so no cookies were being sent. [`809334a`](https://github.com/thecatalinstan/Criollo/commit/809334acf0ec3ad9f5fe48e62daf7200e92ea4fe)
* `CRViewController` does not set `Ccontent-length` header. This is temporary. [`11c2236`](https://github.com/thecatalinstan/Criollo/commit/11c22365c29efd96787302d4e65a5eec8cc303bb)


## [0.1.10](https://github.com/thecatalinstan/Criollo/releases/tag/0.1.10) (03/14/2016)

**Released on Monday, March 14, 2016**.

### Added

* `[CRServer delegateQueue]` property and `[CRServer initWithDelegate:delegateQueue:]` initializer. [`4ec8cff`](https://github.com/thecatalinstan/Criollo/commit/4ec8cff6e0f0a0ef587eef345ca3724b19ebb0b7)

### Fixed

* Fixed a potential crash when `[CRMimeTypeHelper setMimeType:forExtension:]` is called with a `nil` extension. [`3414fd8`](https://github.com/thecatalinstan/Criollo/commit/3414fd81bcffa148c8c59c4af3cc6f73001b337a)

## [0.1.9](https://github.com/thecatalinstan/Criollo/releases/tag/0.1.9) (03/13/2016)

**Released on Sunday, March 13, 2016**. This is just a hot-fix release.

### Fixed

* Fixed potential crash in the builtin server error handling block, due to an incorrect format string. [`6c3a0be`](https://github.com/thecatalinstan/Criollo/commit/6c3a0be15e8819cc3a29348e8e1b661ea5674512).

## [0.1.8](https://github.com/thecatalinstan/Criollo/releases/tag/0.1.8) (03/13/2016)

**Released on Sunday, March 13, 2016**. This release is meant to increase the “real-world” usage karma and to stabilize and extend some existing APIs.

#### Changed APIs

* Refactored `[CRServer addStaticDirectoryAtPath:]` to `[CRServer mountStaticDirectoryAtPath:]`. [`24c7b22`](https://github.com/thecatalinstan/Criollo/commit/24c7b2265fb0a9ddd9bbdc5e7badecba8e5d6c8d).
* `CRHTTPMethod` and `CRHTTPVersion` are now enumerated types, instead of existing `NSString` `#define`.
* Refactored the nullability specifiers across the board. Now using `NS_ASSUME_NONNULL` and `nullable`/`_Nullable` as needed.

#### Added

* Added [Read me](https://github.com/thecatalinstan/Criollo/README.md) content and [Wiki](https://github.com/thecatalinstan/Criollo/wiki) articles to help developers get started.
* Added this [Change Log](https://github.com/thecatalinstan/Criollo/CHANGELOG.md)
* Added the [`[CRResponse redirect:]`](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/CRResponse.h#L48-L52)` convenience methods.
* Added the [`[CRResponse write:]`](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/CRResponse.h#L36) and [`[CRResponse send:]`](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/CRResponse.h#L42) convenience functions.****
* Added the `[CRServer mountStaticFileAtPath:]`. [`644ac67`](https://github.com/thecatalinstan/Criollo/commit/644ac6783eaea2294843bdfacbdb79d8c256fb6e) family of functions.
* `CRViewController` sets `Content-Length` header. [`3aabce5`](https://github.com/thecatalinstan/Criollo/commit/3aabce5e85b3de3c2f4d6f255ff2979bed7d71da) if not set before sending the response.

## [0.1.7](https://github.com/thecatalinstan/Criollo/releases/tag/0.1.7) (03/07/2016)

**Released on Monday, March 7, 2016**. This is the first stable and real-world-ready release.




