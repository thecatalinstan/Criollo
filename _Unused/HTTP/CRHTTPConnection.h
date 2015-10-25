//
//  CRHTTPConnection.h
//  Criollo
//
//  Created by Cătălin Stan on 28/04/15.
//
//

// Socket Timeouts
#define CRSocketReadInitialTimeout                      30
#define CRSocketReadHeaderLineTimeout                   30
#define CRSocketReadBodyTimeout                         30
#define CRSocketWriteHeaderTimeout                      30
#define CRSocketWriteBodyTimeout                        -1
#define CRSocketWriteGeneralTimeout                     30

// Socket tags
#define CRSocketTagBeginReadingRequest                  10
#define CRSocketTagReadingRequestHeader                 11
#define CRSocketTagReadingRequestBody                   12
#define CRSocketTagSendingResponse                      20
#define CRSocketTagSendingResponseHeaders               21
#define CRSocketTagSendingResponseBody                  22
#define CRSocketTagFinishSendingResponse                90
#define CRSocketTagFinishSendingResponseAndClosing      91

// Limits
#define CRRequestMaxHeaderLineLength                    1024
#define CRRequestMaxHeaderLength                        (10 * 1024)

// Buffers
#define CRRequestBodyBufferSize                         (1024 * 1024)

@class GCDAsyncSocket;

@interface CRHTTPConnection : NSObject




@end
