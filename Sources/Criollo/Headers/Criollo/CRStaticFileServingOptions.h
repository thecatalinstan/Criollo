//
//  CRStaticFileServingOptions.h
//  
//
//  Created by Cătălin Stan on 18/09/2022.
//

#import <Foundation/Foundation.h>

/// Options for serving static files from disk.
typedef NS_OPTIONS(NSUInteger, CRStaticFileServingOptions) {
    
    /// Files are cached to the os disk cache. Currently, this option only
    /// applies to files smaller than 512KB in size.
    ///
    /// @see `NSDataReadingMappedIfSafe`.
    CRStaticFileServingOptionsCache             = 1 <<   0,

    /// Follow symbolic links.
    CRStaticFileServingOptionsFollowSymlinks    = 1 <<   3,
};
