//
//  CRServerConfiguration.h
//  Criollo
//
//  Created by Cătălin Stan on 10/25/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

// Defaults
FOUNDATION_EXPORT NSString* const CRServerDefaultInterface;
FOUNDATION_EXPORT NSUInteger const CRServerDefaultPort;

FOUNDATION_EXPORT NSUInteger const CRConnectionDefaultInitialReadTimeout;
FOUNDATION_EXPORT NSUInteger const CRHTTPConnectionDefaultReadHeaderLineTimeout;
FOUNDATION_EXPORT NSUInteger const CRHTTPConnectionDefaultReadBodyTimeout;
FOUNDATION_EXPORT NSUInteger const CRHTTPConnectionDefaultWriteHeaderTimeout;
FOUNDATION_EXPORT NSUInteger const CRHTTPConnectionDefaultWriteBodyTimeout;
FOUNDATION_EXPORT NSUInteger const CRHTTPConnectionDefaultWriteGeneralTimeout;

FOUNDATION_EXPORT NSUInteger const CRRequestDefaultMaxHeaderLineLength;
FOUNDATION_EXPORT NSUInteger const CRRequestDefaultMaxHeaderLength;
FOUNDATION_EXPORT NSUInteger const CRRequestDefaultBodyBufferSize;

// Keys
FOUNDATION_EXPORT NSString* const CRServerInterfaceKey;
FOUNDATION_EXPORT NSString* const CRServerPortKey;

FOUNDATION_EXPORT NSString* const CRConnectionInitialReadTimeoutKey;
FOUNDATION_EXPORT NSString* const CRHTTPConnectionReadHeaderLineTimeoutKey;
FOUNDATION_EXPORT NSString* const CRHTTPConnectionReadHeaderTimeoutKey;
FOUNDATION_EXPORT NSString* const CRHTTPConnectionReadBodyTimeoutKey;
FOUNDATION_EXPORT NSString* const CRHTTPConnectionWriteHeaderTimeoutKey;
FOUNDATION_EXPORT NSString* const CRHTTPConnectionWriteBodyTimeoutKey;
FOUNDATION_EXPORT NSString* const CRHTTPConnectionWriteGeneralTimeoutKey;

FOUNDATION_EXPORT NSString* const CRRequestMaxHeaderLineLengthKey;
FOUNDATION_EXPORT NSString* const CRRequestMaxHeaderLengthKey;
FOUNDATION_EXPORT NSString* const CRRequestBodyBufferSizeKey;



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

@property (nonatomic, assign) NSUInteger CRRequestBodyBufferSize;

@end
