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

+ (CRRouteBlock _Nonnull)errorHandlingBlockWithStatus:(NSUInteger)statusCode;

- (void)didCloseConnection:(CRConnection * _Nonnull)connection;

@end
