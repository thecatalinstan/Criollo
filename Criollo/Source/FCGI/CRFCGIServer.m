//
//  CRFCGIServer.m
//  Criollo
//
//  Created by Cătălin Stan on 10/25/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRFCGIServer.h"
#import "CRFCGIConnection.h"

@implementation CRFCGIServer

- (CRConnection*)newConnectionWithSocket:(GCDAsyncSocket*)socket {
    CRFCGIConnection* connection = [[CRFCGIConnection alloc] initWithSocket:socket server:self];
    return connection;
}

@end
