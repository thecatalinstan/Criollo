//
//  CRServerConfiguration.h
//  Criollo
//
//  Created by Cătălin Stan on 10/25/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString* const CRServerDefaultInterface;
FOUNDATION_EXPORT NSUInteger const CRServerDefaultPort;

FOUNDATION_EXPORT NSUInteger const CRConnectionDefaultInitialReadTimeout;

FOUNDATION_EXPORT NSString* const CRServerInterfaceKey;
FOUNDATION_EXPORT NSString* const CRServerPortKey;

FOUNDATION_EXPORT NSString* const CRConnectionInitialReadTimeoutKey;

@interface CRServerConfiguration : NSObject

@property (nonatomic, strong) NSString* CRServerInterface;
@property (nonatomic, assign) NSUInteger CRServerPort;

@property (nonatomic, assign) NSUInteger CRConnectionInitialReadTimeout;

@end
