//
//  CRServer+Private.h
//  Criollo
//
//  Created by Cătălin Stan on 11/20/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRServer.h"

@class CRConnection;

@interface CRServer (Private)

- (void)didCloseConnection:(CRConnection*)connection;

@end
