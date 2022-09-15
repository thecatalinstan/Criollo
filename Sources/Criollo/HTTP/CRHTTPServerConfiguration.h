//
//  CRHTTPServerConfiguration.h
//
//
//  Created by Cătălin Stan on 10/30/15.
//

#import <Foundation/Foundation.h>

#import "CRServerConfiguration.h"

@interface CRHTTPServerConfiguration : CRServerConfiguration

@property (nonatomic, assign) NSUInteger CRHTTPConnectionReadHeaderTimeout;
@property (nonatomic, assign) NSUInteger CRHTTPConnectionReadBodyTimeout;

@property (nonatomic, assign) NSUInteger CRRequestMaxHeaderLength;

@property (nonatomic, assign) NSUInteger CRRequestBodyBufferSize;

@end
