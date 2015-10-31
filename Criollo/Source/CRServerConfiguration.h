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

@property (nonatomic, assign) NSUInteger CRConnectionKeepAliveTimeout;
@property (nonatomic, assign) NSUInteger CRConnectionMaxKeepAliveConnections;

- (void)readConfiguration;

@end
