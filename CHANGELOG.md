# Change Log

This file includes all notable changes to Criollo.

*Please note that during this early stage of development, **APIs are extremely prone to non-backward-compatible changes.** Please consult this file for the specifics, before you upgrade.*

Criollo uses [Semantic Versioning](http://semver.org/).

---

## [0.4.7](https://github.com/thecatalinstan/Criollo/releases/tag/0.4.7) (10/24/2016)

**Released on Monday, October 24, 2016**. This is a hotfix release that addersses failed server initialization when no SSL certifcates are provided.

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
A bug in `CRRouteController` that affected the resolution of relative paths. [`f952862`](https://github.com/thecatalinstan/Criollo/commit/f952862b00978eb3eeff1345ca03e09450ccd524)

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

**Released on Sunday, March 13, 2016**. This is just a hotfix release.

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




