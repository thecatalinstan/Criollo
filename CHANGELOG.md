# Change Log

This file includes all notable changes to Criollo.

`Criollo` uses [Semantic Versioning](http://semver.org/).

---

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




