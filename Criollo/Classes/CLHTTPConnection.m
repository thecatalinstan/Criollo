//
//  CLHTTPConnection.m
//  Criollo
//
//  Created by Cătălin Stan on 28/04/15.
//
//

#import <Criollo/CLApplication.h>
#import <Criollo/GCDAsyncSocket.h>

#import "CLHTTPConnection.h"

@interface CLHTTPConnection () <GCDAsyncSocketDelegate>

- (void)initialize;

@end

@implementation CLHTTPConnection

- (instancetype)init
{
    return [self initWithSocket:nil delegateQueue:nil];
}

- (instancetype)initWithSocket:(GCDAsyncSocket *)socket
{
    NSString* acceptedSocketDelegateQueueLabel = [[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:[NSString stringWithFormat:@"SocketDelegateQueue-%hu", socket.connectedPort]];
    dispatch_queue_t acceptedSocketDelegateQueue = dispatch_queue_create([acceptedSocketDelegateQueueLabel cStringUsingEncoding:NSASCIIStringEncoding], NULL);
    return  [self initWithSocket:socket delegateQueue:acceptedSocketDelegateQueue];
}

- (instancetype)initWithSocket:(GCDAsyncSocket *)socket delegateQueue:(dispatch_queue_t)delegateQueue
{
    self = [super init];
    if (self != nil) {
        self.socket = socket;
        [self.socket setDelegate:self delegateQueue:delegateQueue];
        
        dispatch_async(self.socket.delegateQueue, ^{ @autoreleasepool {
            [self initialize];
        }});
    }
    return self;
}

#pragma mark - Request Processing

- (void)initialize
{
    [self.socket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:CLSocketReadInitialTimeout maxLength:CLRequestMaxHeaderLineLength tag:CLRequestMaxHeaderLineLength];
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    
    //    if (tag == FCGIRecordAwaitingHeaderTag) {
    //        FCGIRecord* record = [FCGIRecord recordWithHeaderData:data];
    //        if (record.contentLength == 0) {
    //            [self handleRecord:record fromSocket:sock];
    //        } else {
    //            dispatch_set_context(sock.delegateQueue, (void *)(CFBridgingRetain(record)));
    //            [sock readDataToLength:(record.contentLength + record.paddingLength) withTimeout:FCGITimeout tag:FCGIRecordAwaitingContentAndPaddingTag];
    //        }
    //    } else if (tag == FCGIRecordAwaitingContentAndPaddingTag) {
    //        FCGIRecord* record = CFBridgingRelease(dispatch_get_context(sock.delegateQueue));
    //        [record processContentData:data];
    //        [self handleRecord:record fromSocket:sock];
    //    }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if ( err != nil ) {
        [CLApp presentError:err];
    }
    
    sock = nil;
}


@end
