//
//  CRHTTPServer.h
//  Criollo
//
//  Created by Cătălin Stan on 10/25/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRServer.h"

@class CRHTTPServerConfiguration;

@interface CRHTTPServer : CRServer

@property (nonatomic) BOOL isSecure;
@property (nonatomic, strong, nullable) NSArray *certificates;

@end
