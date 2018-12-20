//
//  CRSocket.m
//  Criollo macOS
//
//  Created by Cătălin Stan on 19/12/2018.
//  Copyright © 2018 Cătălin Stan. All rights reserved.
//

#import "CRSocket.h"

#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>

#include <arpa/inet.h>
#include <netinet/in.h>

#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

@interface CRSocket ()

@property (nonatomic) BOOL delegateProvidesAcceptHandler;
@property (nonatomic) BOOL delegateProvidesReadHandler;

@property (nonatomic) int descriptor;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, weak) dispatch_queue_t delegateQueue;

@property (nonatomic, strong) dispatch_source_t readSource;

- (BOOL)fillAddrinfo:(struct addrinfo **)ai forInterface:(NSString *)interface serviceName:(NSString *)serviceName error:(NSError * _Nullable __autoreleasing *)error;

@end

@implementation CRSocket

- (instancetype)initWithDelegate:(id<CRSocketDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue {
    self = [super init];
    if ( self != nil ) {
        _delegate = delegate;
        
        _delegateProvidesAcceptHandler = [_delegate respondsToSelector:@selector(socket:didAccept:addr:len:)];
        _delegateProvidesReadHandler = [_delegate respondsToSelector:@selector(socket:didReadData:size:descriptor:)];
        
        _descriptor = -1;
        _queue = nil;
        
        _delegateQueue = delegateQueue;
    }
    return self;
}

- (BOOL)listen:(NSString *)interface port:(NSUInteger)port error:(NSError * _Nullable __autoreleasing *)error {
    struct addrinfo *ai;
    if ( ! [self fillAddrinfo:&ai forInterface:interface serviceName:[NSString stringWithFormat:@"%lu", (unsigned long)port] error:error] ) {
        return NO;
    }
    
    // Get the socket
    _descriptor = socket(ai->ai_family, ai->ai_socktype, ai->ai_protocol);
    if ( _descriptor == -1 ) {
        if ( error != NULL ) {
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%s", strerror(errno)] }];
        }
        return NO;
    }
    
    // Sock options
    int yes=1;
    if ( setsockopt(_descriptor, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes)) == -1 ) {
        if ( error != NULL ) {
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%s", strerror(errno)] }];
        }
        return NO;
    }
    
    if ( fcntl(_descriptor, F_SETFL, O_NONBLOCK) == -1 ) {
        if ( error != NULL ) {
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%s", strerror(errno)] }];
        }
        return NO;
    }
    
    // Bind the port
    if ( bind(_descriptor, ai->ai_addr, ai->ai_addrlen) == -1 ) {
        if ( error != NULL ) {
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%s", strerror(errno)] }];
        }
        return NO;
    }
    
    if ( listen(_descriptor, UINT16_MAX) == -1 ) {
        if ( error != NULL ) {
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%s", strerror(errno)] }];
        }
        return NO;
    }
    
    // Clean the addrinfo
    freeaddrinfo(ai);
    
    _queue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
    dispatch_set_target_queue(_queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
    
    if ( !_delegateQueue ) {
        _delegateQueue = _queue;
    }
    dispatch_set_context(_delegateQueue, (__bridge void * _Nullable)(self));
    
    _readSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, _descriptor, 0, _queue);
    
    __weak CRSocket *weak_socket = self;
    dispatch_source_set_event_handler (_readSource, ^{
        CRSocket *socket  = weak_socket;
        
        unsigned long current = 0;
        unsigned long total = dispatch_source_get_data(socket->_readSource);
        
        while (current < total) {
            ++current;
            
            struct sockaddr_storage in_addr;
            socklen_t in_len = sizeof(in_addr);
            int new_sock;
            do {
                new_sock = accept(socket->_descriptor, (struct sockaddr *)&in_addr, &in_len);
            } while ( new_sock == -1 && errno == EAGAIN );
            
            if ( new_sock == -1 ) {
                return;
            }
            
            if ( fcntl(new_sock, F_SETFL, O_NONBLOCK) == -1 ) {
                return;
            }
            
            if ( socket->_delegateProvidesAcceptHandler ) {
//                struct sockaddr *sa = calloc(1, sizeof(struct sockaddr));
//                memcpy(sa, (struct sockaddr *)&in_addr, sizeof(struct sockaddr));
                struct sockaddr *sa = (struct sockaddr *)&in_addr;
                dispatch_async(socket->_delegateQueue, ^{
                    [socket->_delegate socket:socket didAccept:new_sock addr:sa len:in_len];
//                    free(sa);
                });
            }
            
            dispatch_source_t read_src = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, new_sock, 0, socket->_queue);
            dispatch_source_set_event_handler(read_src, ^{
                size_t available = dispatch_source_get_data(read_src);
                
                // reading is done
                if ( available <= 0 ) {
                    return;
                }
                
                size_t total_read = 0;
                while(total_read < available) {
                    void *buf = calloc(1, available - total_read);
                    size_t bytes_read;
                    do {
                        bytes_read = recv(new_sock, buf, available, 0);
                    } while ( bytes_read <= 0 && errno == EAGAIN );
                    
                    if ( bytes_read <= 0 ) {
                        perror("recv");
                        dispatch_source_cancel(read_src);
                        shutdown(new_sock, 2);
                        close(new_sock);
                        return;
                    }
                    
                    if ( socket->_delegateProvidesReadHandler ) {
                        dispatch_async(socket->_delegateQueue, ^{
                            [socket->_delegate socket:socket didReadData:buf size:bytes_read descriptor:new_sock];
                            free(buf);
                        });
                    } else {
                        free(buf);
                    }
                    
                    char *msg = "HTTP/1.1 200 OK\nContent-type:text/plain\n\nHello World!\n";
                    dispatch_data_t res = dispatch_data_create(msg, strlen(msg), NULL, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
                    dispatch_write(new_sock, res, socket->_queue, ^(dispatch_data_t  _Nullable data, int error) {
                        if ( error != 0 ) {
                            fprintf(stderr, "dispatch_write: %s", strerror(error));
                        }
                        shutdown(new_sock, SHUT_RDWR);
                        close(new_sock);
                    });
                    
                    total_read += bytes_read;
                }
                
                return;
            });
            dispatch_resume(read_src);
        }
    });
    
    dispatch_resume(_readSource);
    
    return YES;
}

#pragma mark - Tools

- (BOOL)fillAddrinfo:(struct addrinfo **)ai forInterface:(NSString *)interface serviceName:(NSString *)serviceName error:(NSError *__autoreleasing  _Nullable *)error {
    
    if ( ai == NULL ) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Missing addrinfo pointer" userInfo:nil];
    }
    
    // Configure the socket addr structs
    struct addrinfo hints;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_PASSIVE;
    
    int status = getaddrinfo(interface.UTF8String, serviceName.UTF8String, &hints, ai);
    if ( status != 0 ) {
        if ( error != NULL ) {
            NSDictionary *info = @{ NSLocalizedDescriptionKey: [NSString stringWithFormat:@"getaddrinfo: %s", gai_strerror(status)] };
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:CRUnableToResolveAddress userInfo:info];
        }
        return NO;
    }
    
    return YES;
}

@end
