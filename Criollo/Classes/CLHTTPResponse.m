//
//  CLHTTPResponse.m
//  Criollo
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <Criollo/CLApplication.h>
#import <Criollo/CLHTTPMessage.h>
#import <Criollo/CLHTTPConnection.h>
#import <Criollo/GCDAsyncSocket.h>

#import "CLHTTPResponse.h"
#import "NSDate+RFC1123.h"


@interface CLHTTPResponse (Private)

- (void)writeHeaders;
- (void)writeData:(NSData*)data withTag:(long)tag;
- (void)sendStatusLine:(BOOL)closeConnection;

@end

@implementation CLHTTPResponse{
    BOOL alreadySentHeaders;
}

- (instancetype)initWithHTTPConnection:(CLHTTPConnection*)connection HTTPStatusCode:(NSUInteger)HTTPStatusCode
{
    return [self initWithHTTPConnection:connection HTTPStatusCode:HTTPStatusCode description:nil];
}

- (instancetype)initWithHTTPConnection:(CLHTTPConnection*)connection HTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString *)description
{
    return [self initWithHTTPConnection:connection HTTPStatusCode:HTTPStatusCode description:description version:nil];
}

- (instancetype)initWithHTTPConnection:(CLHTTPConnection*)connection HTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString *)description version:(NSString *)version
{
    self  = [super init];
    if ( self != nil ) {
        version = version == nil ? CLHTTP11 : version;
        self.message = CFHTTPMessageCreateResponse(NULL, (CFIndex)HTTPStatusCode, (__bridge CFStringRef)description, (__bridge CFStringRef) version);
        self.connection = connection;
    }
    return self;
}

- (NSUInteger)statusCode
{
    return (NSUInteger)CFHTTPMessageGetResponseStatusCode(self.message);
}

- (void)setValue:(NSString*)value forHTTPHeaderField:(NSString *)HTTPHeaderField
{
    if ( alreadySentHeaders ) {
        [CLApp logErrorFormat:@"Headers already sent."];
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:@"Headers already sent." userInfo:nil] raise];
        return;
    }
    
    CFHTTPMessageSetHeaderFieldValue(self.message, (__bridge CFStringRef)HTTPHeaderField, (__bridge CFStringRef)value);
}

#pragma mark - Write

- (void)writeHeaders
{
    if ( alreadySentHeaders ) {
        return;
    }

    if ( [self valueForHTTPHeaderField:@"Date"] == nil ) {
        [self setValue:[[NSDate date] rfc1123String] forHTTPHeaderField:@"Date"];
    }
    
    if ( [self valueForHTTPHeaderField:@"Content-Type"] == nil ) {
        [self setValue:@"text/plain; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    }

    if ( [self valueForHTTPHeaderField:@"Connection"] == nil ) {
        [self setValue:@"keep-alive" forHTTPHeaderField:@"Connection"];
    }
    
    [self setBody:nil];
    [self.connection.socket writeData:self.data withTimeout:CLSocketWriteHeaderTimeout tag:CLSocketTagSendingResponse];
    
    alreadySentHeaders = YES;
}

- (void)writeData:(NSData *)data withTag:(long)tag
{
    [self writeHeaders];
    [self.connection.socket writeData:data withTimeout:CLSocketWriteGeneralTimeout tag:tag];
}

- (void)writeData:(NSData*)data
{
    [self writeData:data withTag:CLSocketTagSendingResponse];
}

- (void)sendData:(NSData*)data
{
    [self writeData:data withTag:CLSocketTagFinishSendingResponse];
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
    long tag = closeConnection ? CLSocketTagFinishSendingResponseAndClosing : CLSocketTagFinishSendingResponse;
    
    NSMutableData* finishData = [NSMutableData data];
    [finishData appendData:[GCDAsyncSocket CRLFData]];
    [finishData appendData:[GCDAsyncSocket CRLFData]];
    [self writeData:finishData.copy withTag:tag];
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
