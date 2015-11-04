//
//  CRResponse.m
//  Criollo
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "CRResponse.h"
#import "CRApplication.h"
#import "CRServer.h"
#import "CRServerConfiguration.h"
#import "CRConnection.h"
#import "GCDAsyncSocket.h"
#import "NSDate+RFC1123.h"


@interface CRResponse ()

- (void)writeData:(NSData*)data finish:(BOOL)flag;

- (void)buildHeaders;
- (void)writeDataToSocketWithTag:(long)tag;

- (void)flush:(BOOL)closeConnection;

@end

@implementation CRResponse

- (instancetype)init
{
    return [self initWithConnection:nil HTTPStatusCode:200 description:nil version:nil];
}

- (instancetype)initWithConnection:(CRConnection*)connection HTTPStatusCode:(NSUInteger)HTTPStatusCode
{
    return [self initWithConnection:connection HTTPStatusCode:HTTPStatusCode description:nil version:nil];
}

- (instancetype)initWithConnection:(CRConnection*)connection HTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString *)description
{
    return [self initWithConnection:connection HTTPStatusCode:HTTPStatusCode description:description version:nil];
}

- (instancetype)initWithConnection:(CRConnection*)connection HTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString *)description version:(NSString *)version
{
    self  = [super init];
    if ( self != nil ) {
        version = version == nil ? CRHTTP11 : version;
        self.message = CFBridgingRelease(CFHTTPMessageCreateResponse(NULL, (CFIndex)HTTPStatusCode, (__bridge CFStringRef)description, (__bridge CFStringRef) version));
        self.connection = connection;
    }
    return self;
}

- (NSUInteger)statusCode
{
    return (NSUInteger)CFHTTPMessageGetResponseStatusCode((__bridge CFHTTPMessageRef _Nonnull)(self.message));
}

- (void)setValue:(NSString*)value forHTTPHeaderField:(NSString *)HTTPHeaderField
{
//    if ( self.alreadySentHeaders ) {
//        [CRApp logErrorFormat:@"Headers already sent."];
//        [[NSException exceptionWithName:NSInternalInconsistencyException reason:@"Headers already sent." userInfo:nil] raise];
//        return;
//    }

    CFHTTPMessageSetHeaderFieldValue((__bridge CFHTTPMessageRef _Nonnull)(self.message), (__bridge CFStringRef)HTTPHeaderField, (__bridge CFStringRef)value);
}

#pragma mark - Write

- (void)writeData:(NSData*)data {
    [self writeData:data finish:NO];
}

- (void)sendData:(NSData*)data {
    [self writeData:data finish:YES];
}

- (void)writeString:(NSString*)string {
    [self writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)sendString:(NSString*)string {
    [self sendData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)writeFormat:(NSString*)format, ... {
    va_list args;
    va_start(args, format);
    NSString* formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    [self writeString:formattedString];
}

- (void)sendFormat:(NSString*)format, ... {
    va_list args;
    va_start(args, format);
    NSString* formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    [self sendString:formattedString];
}

- (void)writeData:(NSData *)data finish:(BOOL)flag {
    [self appendData:data];
    if ( flag ) {
        [self finish];
    }
}

- (void)finish {
    [self flush:NO];
}

- (void)end {
    [self flush:YES];
}

- (void)buildHeaders {
}

- (void)writeDataToSocketWithTag:(long)tag {
}

- (void)flush:(BOOL)closeConnection {
    long tag = closeConnection ? CRConnectionSocketTagFinishSendingResponseAndClosing : CRConnectionSocketTagFinishSendingResponse;
    [self buildHeaders];
    [self writeDataToSocketWithTag:tag];
}


@end
