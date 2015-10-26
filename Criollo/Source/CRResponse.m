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


@interface CRResponse (Private)

@property (nonatomic, readonly) BOOL isChunked;

- (void)writeHeaders;
- (void)writeData:(NSData*)data withTag:(long)tag;
- (void)sendStatusLine:(BOOL)closeConnection;

@end

@implementation CRResponse{
    BOOL alreadySentHeaders;
}

- (instancetype)initWithHTTPConnection:(CRConnection*)connection HTTPStatusCode:(NSUInteger)HTTPStatusCode
{
    return [self initWithHTTPConnection:connection HTTPStatusCode:HTTPStatusCode description:nil];
}

- (instancetype)initWithHTTPConnection:(CRConnection*)connection HTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString *)description
{
    return [self initWithHTTPConnection:connection HTTPStatusCode:HTTPStatusCode description:description version:nil];
}

- (instancetype)initWithHTTPConnection:(CRConnection*)connection HTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString *)description version:(NSString *)version
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
    if ( alreadySentHeaders ) {
        [CRApp logErrorFormat:@"Headers already sent."];
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:@"Headers already sent." userInfo:nil] raise];
        return;
    }
    
    CFHTTPMessageSetHeaderFieldValue((__bridge CFHTTPMessageRef _Nonnull)(self.message), (__bridge CFStringRef)HTTPHeaderField, (__bridge CFStringRef)value);
}

- (BOOL)isChunked {
    return [[self valueForHTTPHeaderField:@"Transfer-encoding"] isEqualToString:@"chunked"];
}

#pragma mark - Write

- (void)writeHeaders
{
    if ( alreadySentHeaders ) {
        return;
    }

//    if ( [self valueForHTTPHeaderField:@"Date"] == nil ) {
//        [self setValue:[[NSDate date] rfc1123String] forHTTPHeaderField:@"Date"];
//    }

    if ( [self valueForHTTPHeaderField:@"Content-Type"] == nil ) {
        [self setValue:@"text/plain; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    }

    if ( [self valueForHTTPHeaderField:@"Connection"] == nil ) {
        NSString* connectionHeader = @"keep-alive";
        if ( [self.version isEqualToString:CRHTTP10] ) {
            connectionHeader = @"close";
        }
        [self setValue:connectionHeader forHTTPHeaderField:@"Connection"];
    }

    if ( [self valueForHTTPHeaderField:@"Content-length"] == nil ) {
        [self setValue:@"chunked" forHTTPHeaderField:@"Transfer-encoding"];
    }
    
    [self setBody:nil];
    [self.connection.socket writeData:self.data withTimeout:self.connection.server.configuration.CRHTTPConnectionWriteHeaderTimeout tag:CRSocketTagSendingResponse];

    alreadySentHeaders = YES;
}

- (void)writeData:(NSData *)data withTag:(long)tag
{
    [self writeHeaders];
    if ( self.isChunked ) {
        NSMutableData* chunkedData = [NSMutableData data];

        // Chunk size + CRLF
        [chunkedData appendData: [[NSString stringWithFormat:@"%lx", data.length] dataUsingEncoding:NSUTF8StringEncoding]];
        [chunkedData appendData: [CRConnection CRLFData]];

        // The actual data
        [chunkedData appendData:data];
        [chunkedData appendData: [CRConnection CRLFData]];

        data = chunkedData;
    }
    [self.connection.socket writeData:data withTimeout:self.connection.server.configuration.CRHTTPConnectionWriteBodyTimeout tag:tag];
}

- (void)writeData:(NSData*)data
{
    [self writeData:data withTag:CRSocketTagSendingResponse];
}

- (void)sendData:(NSData*)data
{
    [self writeData:data withTag:CRSocketTagFinishSendingResponse];
}

- (void)writeString:(NSString*)string
{
    [self writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)sendString:(NSString*)string
{
    [self sendData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)writeFormat:(NSString*)format, ...
{
    va_list args;
    va_start(args, format);
    NSString* formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    [self writeString:formattedString];
}

- (void)sendFormat:(NSString*)format, ...
{
    va_list args;
    va_start(args, format);
    NSString* formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    [self sendString:formattedString];
}

- (void)sendStatusLine:(BOOL)closeConnection
{
    long tag = closeConnection ? CRSocketTagFinishSendingResponseAndClosing : CRSocketTagFinishSendingResponse;
    
    NSMutableData* statusData = [NSMutableData data];
    if ( self.isChunked ) {
        [statusData appendData: [@"0" dataUsingEncoding:NSUTF8StringEncoding]];
        [statusData appendData:[CRConnection CRLFData]];
    }
    [statusData appendData:[CRConnection CRLFData]];
    [self.connection.socket writeData:statusData withTimeout:self.connection.server.configuration.CRHTTPConnectionWriteBodyTimeout tag:tag];
}

- (void)finish
{
    [self sendStatusLine:NO];
}

- (void)end
{
    [self sendStatusLine:YES];
}



@end
