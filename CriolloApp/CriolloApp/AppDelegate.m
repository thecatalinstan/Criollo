//
//  AppDelegate.m
//  CriolloApp
//
//  Created by Cătălin Stan on 23/03/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import "AppDelegate.h"

#include <stdio.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <sys/utsname.h>

#define PortNumber          10781
#define LogConnections          1
#define LogRequests             1

NS_ASSUME_NONNULL_BEGIN

@interface AppDelegate () <CRServerDelegate> {
    dispatch_queue_t backgroundQueue;
}

@property (nonatomic, strong) CRServer* server;

+ (nullable NSString *)IPAddress;
+ (NSString*)systemInfo;

@end

NS_ASSUME_NONNULL_END

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    BOOL isFastCGI = [[NSUserDefaults standardUserDefaults] boolForKey:@"FastCGI"];
    Class serverClass = isFastCGI ? [CRFCGIServer class] : [CRHTTPServer class];
    self.server = [[serverClass alloc] initWithDelegate:self];

    backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    NSBundle* bundle = [NSBundle mainBundle];

    // Add a header that says who we are :)
    [self.server addBlock:^(CRRequest *request, CRResponse *response, CRRouteCompletionBlock completionHandler) {
        [response setValue:[NSString stringWithFormat:@"%@, %@ build %@", bundle.bundleIdentifier, [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [bundle objectForInfoDictionaryKey:@"CFBundleVersion"]] forHTTPHeaderField:@"Server"];

        if ( ! request.cookies[@"session_cookie"] ) {
            [response setCookie:@"session_cookie" value:[NSUUID UUID].UUIDString path:@"/" expires:nil domain:nil secure:NO];
        }
        [response setCookie:@"persistant_cookie" value:[NSUUID UUID].UUIDString path:@"/" expires:[NSDate distantFuture] domain:nil secure:NO];

        completionHandler();
    }];

    // Prints a simple hello world as text/plain
    CRRouteBlock helloBlock = ^(CRRequest *request, CRResponse *response, CRRouteCompletionBlock completionHandler ) {
        [response setValue:@"text/plain" forHTTPHeaderField:@"Content-type"];
        [response send:@"Hello World"];
        completionHandler();
    };
    [self.server addBlock:helloBlock forPath:@"/"];

    // Prints a hello world JSON object as application/json
    CRRouteBlock jsonHelloBlock = ^(CRRequest *request, CRResponse *response, CRRouteCompletionBlock completionHandler ) {
        [response setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-type"];
        [response send:@{@"status":@(YES), @"mesage": @"Hello world"}];
        completionHandler();
    };
    [self.server addBlock:jsonHelloBlock forPath:@"/json"];

    // Prints some more info as text/html
    NSString *uname = [AppDelegate systemInfo];
    CRRouteBlock statusBlock = ^(CRRequest *request, CRResponse *response, CRRouteCompletionBlock completionHandler ) {

        NSDate *startTime = [NSDate date];

        NSMutableString *responseString = [NSMutableString string];

        // HTML
        [responseString appendString:@"<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\"/><meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\"/><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"/>"];
        [responseString appendFormat:@"<title>%@</title>", bundle.bundleIdentifier];
        [responseString appendString:@"<link rel=\"stylesheet\" href=\"/static/style.css\"/><link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css\" integrity=\"sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7\" crossorigin=\"anonymous\"/><link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap-theme.min.css\" integrity=\"sha384-fLW2N01lMqjakBkx3l/M9EahuwpSfeNvV63J5ezn3uZzapT0u7EYsXMjQV+0En5r\" crossorigin=\"anonymous\"/></head><body>"];

        // Bundle info
        [responseString appendFormat:@"<h1>%@</h1>", bundle.bundleIdentifier ];
        [responseString appendFormat:@"<h2>Version %@ build %@</h2>", [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [bundle objectForInfoDictionaryKey:@"CFBundleVersion"]];

        // Headers
        [responseString appendString:@"<h3>Request Headers:</h3><pre>"];
        [request.allHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [responseString appendFormat:@"%@: %@\n", key, obj];
        }];
        [responseString appendString:@"</pre>"];

        // Request enviroment
        [responseString appendString:@"<h3>Request Enviroment:</h3><pre>"];
        [request.env enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [responseString appendFormat:@"%@: %@\n", key, obj];
        }];
        [responseString appendString:@"</pre>"];

        // Query
        [responseString appendString:@"<h3>Request Query:</h3><pre>"];
        [request.query enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [responseString appendFormat:@"%@: %@\n", key, obj];
        }];
        [responseString appendString:@"</pre>"];

        // Body
        if ( request.body != nil ) {
            [responseString appendString:@"<h3>Request Body:</h3><pre>"];
            [responseString appendFormat:@"%@", request.body];
            [responseString appendString:@"</pre>"];
        }

        // Cookies
        [responseString appendString:@"<h3>Request Cookies:</h3><pre>"];
        [request.cookies enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [responseString appendFormat:@"%@: %@\n", key, obj];
        }];
        [responseString appendString:@"</pre>"];

        // Stack trace
        [responseString appendString:@"<h3>Stack Trace:</h3><pre>"];
        [[NSThread callStackSymbols] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [responseString appendFormat:@"%@\n", obj];
        }];
        [responseString appendString:@"</pre>"];

        // System info
        [responseString appendString:@"<hr/>"];
        [responseString appendFormat:@"<small>%@</small><br/>", uname];
        [responseString appendFormat:@"<small>Task took: %.4fms</small>", [startTime timeIntervalSinceNow] * -1000];

        // HTML
        [responseString appendString:@"</body></html>"];

        [response setValue:@"text/html; charset=utf-8" forHTTPHeaderField:@"Content-type"];
        [response setValue:@(responseString.length).stringValue forHTTPHeaderField:@"Content-Length"];
        [response sendString:responseString];

        completionHandler();

    };
    [self.server addBlock:statusBlock forPath:@"/status"];

    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        [response setValue:@"text/plain" forHTTPHeaderField:@"Content-type"];
        [response sendString:[NSString stringWithFormat:@"%@\r\n\r\n--%@\r\n\r\n--", request, request.body]];
    } forPath:@"/post" HTTPMethod:CRHTTPMethodPost];

//    [self.server addController:[MultipartViewController class] withNibName:@"MultipartViewController" bundle:nil forPath:@"/multipart"];
//    [self.server addController:[HelloWorldViewController class] withNibName:@"HelloWorldViewController" bundle:nil forPath:@"/controller" HTTPMethod:CRHTTPMethodAll recursive:YES];

    // Serve static files from "/Public" (relative to bundle)
    NSString* staticFilesPath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"Public"];
    [self.server mountStaticDirectoryAtPath:staticFilesPath forPath:@"/static" options:CRStaticDirectoryServingOptionsCacheFiles];

    // Redirecter
    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSURL* redirectURL = [NSURL URLWithString:(request.query[@"redirect"] ? : @"")];
        if ( redirectURL ) {
            [response redirectToURL:redirectURL];
        }
        completionHandler();
    } forPath:@"/redirect" HTTPMethod:CRHTTPMethodGet];
    
    [self.server mountStaticDirectoryAtPath:@"~" forPath:@"/pub" options:CRStaticDirectoryServingOptionsAutoIndex];

    [self startServer];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self.server stopListening];
}

- (void)startServer {
    NSError *serverError;

    if ( [self.server startListening:&serverError portNumber:PortNumber] ) {

        // Get server ip address

        NSString* address = [AppDelegate IPAddress];
        if ( !address ) {
            address = @"127.0.0.1";
        }

        // Set the base url. This is only for logging
        NSURL* baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%d", address, PortNumber]];

        [CRApp logFormat:@"%@ Started HTTP server at %@", [NSDate date], baseURL.absoluteString];

        // Get the list of paths
        NSDictionary<NSString*, NSMutableArray<CRRoute*>*>* routes = [[self.server valueForKey:@"routes"] mutableCopy];
        NSMutableSet<NSURL*>* paths = [NSMutableSet set];

        [routes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray<CRRoute *> * _Nonnull obj, BOOL * _Nonnull stop) {
            if ( [key hasSuffix:@"*"] ) {
                return;
            }
            NSString* path = [key substringFromIndex:[key rangeOfString:@"/"].location + 1];
            [paths addObject:[baseURL URLByAppendingPathComponent:path]];
        }];

        NSArray<NSURL*>* sortedPaths =[paths sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"absoluteString" ascending:YES]]];
        [CRApp logFormat:@"Available paths are:"];
        [sortedPaths enumerateObjectsUsingBlock:^(NSURL * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            dispatch_async( backgroundQueue, ^{
                [CRApp logFormat:@" * %@", obj.absoluteString];
            });
        }];

    } else {
        [CRApp logErrorFormat:@"%@ Failed to start HTTP server. %@", [NSDate date], serverError.localizedDescription];
        [CRApp terminate:nil];
    }
}

#if LogConnections
- (void)server:(CRServer *)server didAcceptConnection:(CRConnection *)connection {
    NSString* remoteAddress = connection.remoteAddress.copy;
    NSUInteger remotePort = connection.remotePort;
    dispatch_async( backgroundQueue, ^{
        [CRApp logFormat:@"Accepted connection from %@:%d", remoteAddress, remotePort];
    });
}

- (void)server:(CRServer *)server didCloseConnection:(CRConnection *)connection {
    NSString* remoteAddress = connection.remoteAddress.copy;
    NSUInteger remotePort = connection.remotePort;
    dispatch_async( backgroundQueue, ^{
        [CRApp logFormat:@"Disconnected %@:%d", remoteAddress, remotePort];
    });
}
#endif


- (void)server:(CRServer *)server didFinishRequest:(CRRequest *)request {
#if LogRequests
    NSString* contentLength = [request.response valueForHTTPHeaderField:@"Content-Length"];
    NSString* userAgent = request.env[@"HTTP_USER_AGENT"];
    NSString* remoteAddress = request.env[@"HTTP_X_FORWARDED_FOR"].length > 0 ? request.env[@"HTTP_X_FORWARDED_FOR"] : request.env[@"REMOTE_ADDR"];
    NSUInteger statusCode = request.response.statusCode;
    dispatch_async( backgroundQueue, ^{
        [CRApp logFormat:@"%@ %@ %@ - %lu %@ - %@", [NSDate date], remoteAddress, request, statusCode, contentLength ? : @"-", userAgent];
    });
#endif
}

#pragma mark - Utils

+ (NSString *)IPAddress {
    static NSString* address;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct ifaddrs *interfaces = NULL;
        struct ifaddrs *temp_addr = NULL;
        int success = 0;
        success = getifaddrs(&interfaces);
        if (success == 0) {
            temp_addr = interfaces;
            while(temp_addr != NULL) {
                if(temp_addr->ifa_addr->sa_family == AF_INET) {
                    if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                        address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    }
                }
                temp_addr = temp_addr->ifa_next;
            }
        }
        freeifaddrs(interfaces);
    });
    return address;
}

+ (NSString*)systemInfo {
    static NSString* systemInfo;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct utsname unameStruct;
        uname(&unameStruct);
        systemInfo = [NSString stringWithFormat:@"%s %s %s %s %s", unameStruct.sysname, unameStruct.nodename, unameStruct.release, unameStruct.version, unameStruct.machine];
    });
    return systemInfo;
}

@end
