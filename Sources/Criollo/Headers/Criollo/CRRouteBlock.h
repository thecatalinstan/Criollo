//
//  CRRouteBlock.h
//  
//
//  Created by Cătălin Stan on 18/09/2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CRRequest, CRResponse;

/// A route block is attached to a route for a specified path and HTTP request
/// method. It is run as part of the route traversal process.
///
/// Blocks are added using the `[CRServer addBlock:]` family of functions.
///
/// @param reques The `CRRequest` object for which the block is being executed
/// @param response The `CRResponse` object being sent back
/// @param completionHandler A block that must be called to pass execution on to the next `CRRouteBlock`
typedef void(^CRRouteBlock)(CRRequest *request, CRResponse *response, dispatch_block_t completion);

NS_ASSUME_NONNULL_END
