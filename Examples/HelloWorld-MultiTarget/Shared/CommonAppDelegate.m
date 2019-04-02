//
//  CommonAppDelegate.m
//  HelloWorld
//
//  Created by Cătălin Stan on 11/9/15.
//
//

#import "CommonAppDelegate.h"
#import "CommonRequestHandler.h"
#import "HelloWorldViewController.h"

#include <ifaddrs.h>
#include <arpa/inet.h>

@interface CommonAppDelegate ()  <CRServerDelegate> {
}

// see: http://stackoverflow.com/questions/6807788/how-to-get-ip-address-of-iphone-programatically
- (BOOL)getIPAddress:(NSString**)address;

@end

@implementation CommonAppDelegate

- (void)setupServer {

    self.isolationQueue = dispatch_queue_create("IsolationQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(self.isolationQueue, dispatch_get_main_queue());

    self.server = [[CRHTTPServer alloc] initWithDelegate:self];

    CRRouteBlock identifyBlock = [CommonRequestHandler defaultHandler].identifyBlock;
    CRRouteBlock helloBlock = [CommonRequestHandler defaultHandler].helloWorldBlock;
    CRRouteBlock jsonHelloBlock = [CommonRequestHandler defaultHandler].jsonHelloWorldBlock;
    CRRouteBlock statusBlock = [CommonRequestHandler defaultHandler].statusBlock;
    CRRouteBlock redirectBlock = [CommonRequestHandler defaultHandler].redirectBlock;

    [self.server add:identifyBlock];
    [self.server add:@"/" block:helloBlock];
    [self.server add:@"/json" block:jsonHelloBlock];
    [self.server get:@"/status" block:statusBlock];
    [self.server add:@"/controller" viewController:HelloWorldViewController.class withNibName:nil bundle:nil];
    [self.server mount:@"/static" directoryAtPath:[NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:@"Public"] options:CRStaticDirectoryServingOptionsCacheFiles];
    [self.server get:@"/redirect" block:redirectBlock];

    [self willChangeValueForKey:@"isConnected"];
    _isConnected = NO;
    [self didChangeValueForKey:@"isConnected"];

    [self willChangeValueForKey:@"isDisconnected"];
    _isDisconnected = YES;
    [self didChangeValueForKey:@"isDisconnected"];
}

- (void)startListening:(id)sender {
    [self willChangeValueForKey:@"isDisconnected"];
    _isDisconnected = NO;
    [self didChangeValueForKey:@"isDisconnected"];

    NSError*serverError;
    if ( [self.server startListening:&serverError portNumber:PortNumber] ) {
        NSString* address;
        BOOL result = [self getIPAddress:&address];
        if ( !result ) {
            address = @"127.0.0.1";
        }
        self.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%d/", address, PortNumber]];
        [self serverDidStartAtURL:self.baseURL];

        [self willChangeValueForKey:@"isConnected"];
        _isConnected = YES;
        [self didChangeValueForKey:@"isConnected"];

        [self willChangeValueForKey:@"isDisconnected"];
        _isDisconnected = NO;
        [self didChangeValueForKey:@"isDisconnected"];
    } else {
        [self serverDidFailToStartWithError:serverError];

        [self willChangeValueForKey:@"isConnected"];
        _isConnected = NO;
        [self didChangeValueForKey:@"isConnected"];

        [self willChangeValueForKey:@"isDisconnected"];
        _isDisconnected = YES;
        [self didChangeValueForKey:@"isDisconnected"];
    }
}

- (void)stopListening:(id)sender {
    [self willChangeValueForKey:@"isDisconnected"];
    _isDisconnected = NO;
    [self didChangeValueForKey:@"isDisconnected"];

    [self.server closeAllConnections:^{
        [self.server stopListening];
        
        [self willChangeValueForKey:@"isConnected"];
        _isConnected = NO;
        [self didChangeValueForKey:@"isConnected"];
        
        [self willChangeValueForKey:@"isDisconnected"];
        _isDisconnected = YES;
        [self didChangeValueForKey:@"isDisconnected"];
        
        [self serverDidStopListening];        
    }];
}

- (void)closeAllConnections {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self.server closeAllConnections:nil];
    });
}

- (void)serverDidStartAtURL:(NSURL *)URL {
    [self logFormat:@"Started HTTP server at %@", URL.absoluteString];

    // Get the list of paths
    NSArray<NSString *> *paths = [[self.server valueForKeyPath:@"routes.@distinctUnionOfObjects.path"] sortedArrayUsingSelector:@selector(compare:)];
    [self logFormat:@"Available paths are:"];
    [paths enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self logFormat:@" * %@", [self.baseURL URLByAppendingPathComponent:[obj substringFromIndex:1]]];
    }];
}

- (void)serverDidFailToStartWithError:(NSError *)error {
    [self logErrorFormat:@"Failed to start HTTP server. %@", error.localizedDescription];
}

- (void)serverDidStopListening {
    [self logFormat:@"Stopped listening"];
}

#pragma mark - CRServerDelegate

#if LogConnections
- (void)server:(CRServer *)server didAcceptConnection:(CRConnection *)connection {
    [self logDebugFormat:@" * Accepted connection from %@:%lu", connection.remoteAddress, connection.remotePort];
}

- (void)server:(CRServer *)server didCloseConnection:(CRConnection *)connection {
    [self logDebugFormat:@" * Disconnected %@:%lu", connection.remoteAddress, connection.remotePort];

}
#endif

#if LogRequests
- (void)server:(CRServer *)server didFinishRequest:(CRRequest *)request {
    NSString* contentLength = [request.response valueForHTTPHeaderField:@"Content-Length"];
    [self logDebugFormat:@" * %@ %@ - %lu %@ - %@", request.response.connection.remoteAddress, request, request.response.statusCode, contentLength ? : @"-", request.env[@"HTTP_USER_AGENT"]];
}
#endif

#pragma mark - Utils

// see: http://stackoverflow.com/questions/6807788/how-to-get-ip-address-of-iphone-programatically
- (BOOL)getIPAddress:(NSString**)address {
    BOOL result = NO;
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    success = getifaddrs(&interfaces);
    if (success == 0) {
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    *address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    result = YES;
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }

    freeifaddrs(interfaces);
    return result;
}

#pragma mark - Logging

- (NSDictionary*)commonTextAttributes {
    static NSDictionary* _commonTextAttributes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableParagraphStyle* style = [[NSMutableParagraphStyle alloc] init];
        style.lineHeightMultiple = 1.1;
        style.lineBreakMode = NSLineBreakByWordWrapping;
        _commonTextAttributes = @{ NSParagraphStyleAttributeName: style };
    });
    return _commonTextAttributes;
}

- (NSDictionary*)linkTextAttributes {
    static NSDictionary* _linkTextAttributes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _linkTextAttributes = @{ NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle) };
    });
    return _linkTextAttributes;
}

- (NSDictionary *)logTextAtributes {
    return [self commonTextAttributes];
}

- (NSDictionary *)logDebugAtributes {
    return [self commonTextAttributes];
}

- (NSDictionary *)logErrorAtributes {
    return [self commonTextAttributes];
}

- (void)logFormat:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString* formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    [self logString:formattedString attributes:self.logTextAtributes];
}

- (void)logDebugFormat:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString* formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    [self logString:formattedString attributes:self.logDebugAtributes];
}

- (void)logErrorFormat:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString* formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    [self logString:formattedString attributes:self.logErrorAtributes];
}

- (void)logString:(NSString *)string attributes:(NSDictionary *)attributes {
    NSAttributedString* attributedString = [[NSAttributedString alloc] initWithString:string attributes:attributes];
    [[NSNotificationCenter defaultCenter] postNotificationName:LogMessageNotificationName object:attributedString];
}


@end
