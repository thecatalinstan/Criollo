//
//  CRRouter.h
//  Criollo
//
//  Created by Cătălin Stan on 11/8/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

@class CRRequest, CRResponse;

typedef void(^CRRouteHandlerBlock)(CRRequest* request, CRResponse* response);

@protocol CRRouter <NSObject>

- (BOOL)canHandleHTTPMethod:(NSString*)HTTPMethod forPath:(NSString*)path;

- (void)addHandlerBlock:(CRRouteHandlerBlock)handlerBlock forPath:(NSString*)path HTTPMethod:(NSString*)HTTPMethod;

- (void)addHandlerBlock:(CRRouteHandlerBlock)handlerBlock;
- (void)addHandlerBlock:(CRRouteHandlerBlock)handlerBlock forPath:(NSString*)path;

- (void)addHandlerBlockForGet:(CRRouteHandlerBlock)handlerBlock;
- (void)addHandlerBlockForGet:(CRRouteHandlerBlock)handlerBlock forPath:(NSString*)path;

- (void)addHandlerBlockForPost:(CRRouteHandlerBlock)handlerBlock;
- (void)addHandlerBlockForPost:(CRRouteHandlerBlock)handlerBlock forPath:(NSString*)path;

- (void)addHandlerBlockForPut:(CRRouteHandlerBlock)handlerBlock;
- (void)addHandlerBlockForPut:(CRRouteHandlerBlock)handlerBlock forPath:(NSString*)path;

- (void)addHandlerBlockForDelete:(CRRouteHandlerBlock)handlerBlock;
- (void)addHandlerBlockForDelete:(CRRouteHandlerBlock)handlerBlock forPath:(NSString*)path;
@end
