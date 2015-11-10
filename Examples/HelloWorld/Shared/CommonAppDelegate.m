//
//  CommonAppDelegate.m
//  HelloWorld
//
//  Created by Cătălin Stan on 11/9/15.
//
//

#import "CommonAppDelegate.h"
#import "CommonRequestHandler.h"

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

    CRRouteHandlerBlock helloBlock = [CommonRequestHandler defaultHandler].helloWorldBlock;
    CRRouteHandlerBlock statusBlock = [CommonRequestHandler defaultHandler].statusBlock;

    [self.server addHandlerBlock:helloBlock];
    [self.server addHandlerBlock:statusBlock forPath:@"/status" HTTPMethod:@"GET"];

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
    [self didChangeValueForKey:@"isDisconnected"];    _isConnected = NO;

    NSError*serverError;
    if ( [self.server startListeningOnPortNumber:PortNumber error:&serverError] ) {
        NSString* address;
        BOOL result = [self getIPAddress:&address];
        if ( !result ) {
            address = @"127.0.0.1";
        }
        NSURL* URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%d/", address, PortNumber]];
        [self serverDidStartAtURL:URL];

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

    [self.server stopListening];
    
    [self willChangeValueForKey:@"isConnected"];
    _isConnected = NO;
    [self didChangeValueForKey:@"isConnected"];

    [self willChangeValueForKey:@"isDisconnected"];
    _isDisconnected = YES;
    [self didChangeValueForKey:@"isDisconnected"];

}

- (void)closeAllConnections {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self.server closeAllConnections];
    });
}

- (void)serverDidStartAtURL:(NSURL *)URL {
    [self logFormat:@"Started HTTP server at %@", URL.absoluteString];
}

- (void)serverDidFailToStartWithError:(NSError *)error {
    [self logErrorFormat:@"Failed to start HTTP server. %@", error.localizedDescription];
}

#pragma mark - CRServerDelegate

- (void)serverDidStartListening:(CRServer *)server {
#if LogDebug
    [self logDebugFormat:@" * Started listening on %@:%lu", server.configuration.CRServerInterface.length == 0 ? @"*" : server.configuration.CRServerInterface, server.configuration.CRServerPort];
#endif
}

- (void)serverDidStopListening:(CRServer *)server {
    [self logFormat:@"Stopped listening."];
}

- (void)server:(CRServer *)server didAcceptConnection:(CRConnection *)connection {
#if LogDebug
    [self logDebugFormat:@" * Connection from %@:%lu", connection.remoteAddress, connection.remotePort];
#endif
}

- (void)server:(CRServer *)server didCloseConnection:(CRConnection *)connection {
#if LogDebug
    [self logDebugFormat:@" * Disconnected."];
#endif
}

- (void)server:(CRServer *)server didReceiveRequest:(CRRequest *)request {
#if LogDebug
    [self logDebugFormat:@" * Received request %@", request];
#endif
}

- (void)server:(CRServer *)server didFinishRequest:(CRRequest *)request {
    [self logFormat:@" * %@ - %@ - %lu", request.response.connection.remoteAddress, request, request.response.statusCode];
}

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
