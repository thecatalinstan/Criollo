//
//  CRServerConfiguration.h
//  Criollo
//
//  Created by Cătălin Stan on 10/25/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CRServerConfiguration : NSObject

@property (nonatomic, strong) NSString* CRServerInterface;
@property (nonatomic, assign) NSUInteger CRServerPort;

@property (nonatomic, assign) NSUInteger CRConnectionInitialReadTimeout;
@property (nonatomic, assign) NSUInteger CRHTTPConnectionReadHeaderLineTimeout;
@property (nonatomic, assign) NSUInteger CRHTTPConnectionReadHeaderTimeout;
@property (nonatomic, assign) NSUInteger CRHTTPConnectionReadBodyTimeout;
@property (nonatomic, assign) NSUInteger CRHTTPConnectionWriteHeaderTimeout;
@property (nonatomic, assign) NSUInteger CRHTTPConnectionWriteBodyTimeout;
@property (nonatomic, assign) NSUInteger CRHTTPConnectionWriteGeneralTimeout;

@property (nonatomic, assign) NSUInteger CRRequestMaxHeaderLineLength;
@property (nonatomic, assign) NSUInteger CRRequestMaxHeaderLength;

@property (nonatomic, assign) NSUInteger CRHTTPConnectionKeepAliveTimeout;
@property (nonatomic, assign) NSUInteger CRHTTPConnectionMaxKeepAliveConnections;

@property (nonatomic, assign) NSUInteger CRRequestBodyBufferSize;

@end
