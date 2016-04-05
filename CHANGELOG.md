# Change Log

This file includes all notable changes to Criollo.

`Criollo` uses [Semantic Versioning](http://semver.org/).

---

## [0.1.13](https://github.com/thecatalinstan/Criollo/releases/tag/0.1.13) (04/05/2016)

**Released on Tuesday, April 5, 2016**. 

This release focuses on optimizing memory usage, stability and generally speaking *speed*. It also includes some API changes to make developers’ lives easier.

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
* `CRViewController` does not set `Ccontent-length` header. This is temoporary. [`11c2236`](https://github.com/thecatalinstan/Criollo/commit/11c22365c29efd96787302d4e65a5eec8cc303bb)


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




