//
//  CriolloGlobals.h
//
//
//  Created by Cătălin Stan on 11/20/15.
//

#define CR_OBJC_ABSTRACT {\
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"%s must be implemented in a subclass.", __PRETTY_FUNCTION__] userInfo:nil];\
}
