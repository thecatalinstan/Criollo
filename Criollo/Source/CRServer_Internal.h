//
//  CRServer_Internal.h
//  Criollo
//
//  Created by Cătălin Stan on 11/20/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRServer.h"

@class CRConnection;

@interface CRServer ()

@property (nonatomic, strong, nonnull) CRServerConfiguration * configuration;
@property (nonatomic, strong, nonnull) NSMutableArray<CRConnection *> * connections;

+ (nonnull CRRouteBlock)errorHandlingBlockWithStatus:(NSUInteger)statusCode error:(NSError * _Nullable)error;

- (void)didCloseConnection:(CRConnection * _Nonnull)connection;

@end
