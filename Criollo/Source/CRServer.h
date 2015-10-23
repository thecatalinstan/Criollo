//
//  CRServer.h
//  Criollo
//
//  Created by Catalin Stan on 7/24/15.
//  Copyright (c) 2015 Cătălin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CRServer, GCDAsyncSocket;

FOUNDATION_EXPORT NSUInteger const CRErrorSocketError;
FOUNDATION_EXPORT NSUInteger const CRErrorRequestMalformedRequest;
FOUNDATION_EXPORT NSUInteger const CRErrorRequestUnsupportedMethod;

FOUNDATION_EXPORT NSUInteger const CRDefaultPortNumber;

FOUNDATION_EXPORT NSString* const CRRequestKey;
FOUNDATION_EXPORT NSString* const CRResponseKey;

@protocol CRServerDelegate <NSObject>

@end

@interface CRServer : NSObject

//@property (atomic, assign) NSUInteger portNumber;
//@property (nonatomic, strong) NSString* interface;
//
//@property (nonatomic, strong) GCDAsyncSocket* httpSocket;
//@property (nonatomic, strong) NSMutableArray* connections;
//
//@property (nonatomic, strong) dispatch_queue_t delegateQueue;
//@property (nonatomic, strong) NSOperationQueue* workerQueue;
//
//- (instancetype)initWithDelegate:(id<CRServerDelegate>)delegate;
//- (instancetype)initWithDelegate:(id<CRServerDelegate>)delegate portNumber:(NSUInteger)portNumber;
//- (instancetype)initWithDelegate:(id<CRServerDelegate>)delegate portNumber:(NSUInteger)portNumber interface:(NSString*)interface;

//- (BOOL)canHandleRequest:(CRHTTPRequest*)request;
//- (void)startListening;
//- (void)stopListening;
//- (void)didCloseConnection:(CRHTTPConnection*)connection;

//+ (NSData *)CRLFCRLFData;

@end
