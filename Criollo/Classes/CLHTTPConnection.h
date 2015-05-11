//
//  CLHTTPConnection.h
//  Criollo
//
//  Created by Cătălin Stan on 28/04/15.
//
//

// Socket Timeouts
#define CLSocketReadInitialTimeout                      30
#define CLSocketReadHeaderLineTimeout                   30
#define CLSocketReadBodyTimeout                         30
#define CLSocketWriteHeaderTimeout                      30
#define CLSocketWriteBodyTimeout                        -1
#define CLSocketWriteGeneralTimeout                     30

// Socket tags
#define CLSocketTagBeginReadingRequest                  10
#define CLSocketTagReadingRequestHeader                 11
#define CLSocketTagReadingRequestBody                   12
#define CLSocketTagSendingResponse                      20
#define CLSocketTagSendingResponseHeaders               21
#define CLSocketTagSendingResponseBody                  22
#define CLSocketTagFinishSendingResponse                90
#define CLSocketTagFinishSendingResponseAndClosing      91

// Limits
#define CLRequestMaxHeaderLineLength                    1024
#define CLRequestMaxHeaderLength                        (10 * 1024)

// Buffers
#define CLRequestBodyBufferSize                         (1024 * 1024)

#import <Criollo/CLApplication.h>

@class GCDAsyncSocket;

@interface CLHTTPConnection : NSObject

@property (nonatomic, strong) GCDAsyncSocket* socket;

- (instancetype)initWithSocket:(GCDAsyncSocket*)socket;
- (instancetype)initWithSocket:(GCDAsyncSocket*)socket delegateQueue:(dispatch_queue_t)delegateQueue NS_DESIGNATED_INITIALIZER;


@end
