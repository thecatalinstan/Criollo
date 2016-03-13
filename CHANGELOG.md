# Change Log

This file includes all notable changes to Criollo.

`Criollo` uses [Semantic Versioning](http://semver.org/).

---

## [0.1.18](https://github.com/thecatalinstan/Criollo/releases/tag/0.1.18) (03/13/2016)

**Released on Sunday, March 13, 2016**. This release is meant to increase the “real-world” usage karma and to stabilize and extend some existing APIs.

#### Changed APIs

* Refactored `[CRServer addStaticDirectoryAtPath:]` to [[`CRServer mountStaticDirectoryAtPath:]`](https://github.com/thecatalinstan/Criollo/commit/24c7b2265fb0a9ddd9bbdc5e7badecba8e5d6c8d).
* `CRHTTPMethod` and `CRHTTPVersion` are now enumerated types, instead of existing `NSString` `#define`. 
* Refactored the nullability specifiers across the board. Now using `NS_ASSUME_NONNULL` and `nullable`/`_Nullable` as needed.

#### Added

* Added [Read me](https://github.com/thecatalinstan/Criollo/README.md) content and [Wiki](https://github.com/thecatalinstan/Criollo/wiki) articles to help developers get started.
* Added this [Change Log](https://github.com/thecatalinstan/Criollo/CHANGELOG.md)
* Added the [`[CRResponse redirect:]`](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/CRResponse.h#L48-L52)` convenience methods.
* Added the [`[CRResponse write:]`](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/CRResponse.h#L36) and [`[CRResponse send:]`](https://github.com/thecatalinstan/Criollo/blob/master/Criollo/Source/CRResponse.h#L42) convenience functions.****
* Added the [`[CRServer mountStaticFileAtPath:]`](https://github.com/thecatalinstan/Criollo/commit/644ac6783eaea2294843bdfacbdb79d8c256fb6e) family of functions.
* `CRViewController` sets [Content-Length header](https://github.com/thecatalinstan/Criollo/commit/3aabce5e85b3de3c2f4d6f255ff2979bed7d71da) if not set before sending the response.

## [0.1.17](https://github.com/thecatalinstan/Criollo/releases/tag/0.1.17) (03/07/2016)

**Released on Monday, March 7, 2016**. This is the first stable and real-world-ready release.


 

