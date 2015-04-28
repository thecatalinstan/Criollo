//
//  CLHTTPConnection.h
//  Criollo
//
//  Created by Cătălin Stan on 28/04/15.
//
//

#define CLSocketReadInitialTimeout          30
#define CLSocketReadHeaderLineTimeout       30
#define CLSocketWriteHeaderTimeout          30
#define CLSocketWriteBodyTimeout            -1

#define CLSocketTagReadingRequestHeader     10

//#define HTTP_REQUEST_BODY                  11
//#define HTTP_REQUEST_CHUNK_SIZE            12
//#define HTTP_REQUEST_CHUNK_DATA            13
//#define HTTP_REQUEST_CHUNK_TRAILER         14
//#define HTTP_REQUEST_CHUNK_FOOTER          15
//#define HTTP_PARTIAL_RESPONSE              20
//#define HTTP_PARTIAL_RESPONSE_HEADER       21
//#define HTTP_PARTIAL_RESPONSE_BODY         22
//#define HTTP_CHUNKED_RESPONSE_HEADER       30
//#define HTTP_CHUNKED_RESPONSE_BODY         31
//#define HTTP_CHUNKED_RESPONSE_FOOTER       32
//#define HTTP_PARTIAL_RANGE_RESPONSE_BODY   40
//#define HTTP_PARTIAL_RANGES_RESPONSE_BODY  50
//#define HTTP_RESPONSE                      90
//#define HTTP_FINAL_RESPONSE                91

#define CLRequestMaxHeaderLineLength     8190


@class GCDAsyncSocket;

@interface CLHTTPConnection : NSObject

@property (nonatomic, strong) GCDAsyncSocket* socket;

- (instancetype)initWithSocket:(GCDAsyncSocket*)socket;
- (instancetype)initWithSocket:(GCDAsyncSocket*)socket delegateQueue:(dispatch_queue_t)delegateQueue NS_DESIGNATED_INITIALIZER;

@end
