//
//  CRStaticDirectoryServingOptions.h
//  
//
//  Created by Cătălin Stan on 18/09/2022.
//

/// Options for mounting static directories.
typedef NS_OPTIONS(NSUInteger, CRStaticDirectoryServingOptions) {
    
    /// Files are cached to the os disk cache. Currently, this option only
    /// applies to files smaller than 512KB in size.
    ///
    /// @see `NSDataReadingMappedIfSafe`.
    CRStaticDirectoryServingOptionsCacheFiles               = 1 <<   0,

    /// Generate an HTML index for the directory's contents.
    CRStaticDirectoryServingOptionsAutoIndex                = 1 <<   1,

    /// Show hidden files in the auto-generated directory index.
    CRStaticDirectoryServingOptionsAutoIndexShowHidden      = 1 <<   2,
    
    /// Follow symbolic links
    CRStaticDirectoryServingOptionsFollowSymlinks           = 1 <<   3,
};
