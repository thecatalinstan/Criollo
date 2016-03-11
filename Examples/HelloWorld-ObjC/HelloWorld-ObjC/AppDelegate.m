//
//  AppDelegate.m
//  HelloWorld-ObjC
//
//  Created by Cătălin Stan on 11/19/15.
//  Copyright © 2015 Catalin Stan. All rights reserved.
//

#import "AppDelegate.h"
#import "utils.h"
#import "HelloWorldViewController.h"
#import "MultipartViewController.h"

#define PortNumber          10781
#define LogConnections          0
#define LogRequests             1

#define UseFCGI                 0

@interface AppDelegate () <CRServerDelegate>

@property (nonatomic, strong, nonnull) CRServer *server;
@property (nonatomic, strong, nonnull) NSURL *baseURL;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    // Create the server and add some handlers to do some work
#if UseFCGI
    self.server = [[CRFCGIServer alloc] initWithDelegate:self];
#else
    self.server = [[CRHTTPServer alloc] initWithDelegate:self];
#endif

    NSBundle *bundle = [NSBundle mainBundle];

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
    NSString *uname = systemInfo();
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

    [self.server addController:[MultipartViewController class] withNibName:@"MultipartViewController" bundle:nil forPath:@"/multipart"];
    [self.server addController:[HelloWorldViewController class] withNibName:@"HelloWorldViewController" bundle:nil forPath:@"/controller" HTTPMethod:CRHTTPMethodAll recursive:YES];

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

    // Start listening
    NSError *serverError;
    if ( [self.server startListening:&serverError portNumber:PortNumber] ) {

        // Output some nice info to the console

        // Get server ip address
        NSString *address;
        BOOL result = getIPAddress(&address);
        if ( !result ) {
            address = @"127.0.0.1";
        }

        // Set the base url. This is only for logging
        self.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%d", address, PortNumber]];

        [CRApp logFormat:@"Started HTTP server at %@", self.baseURL.absoluteString];

        // Get the list of paths
        NSDictionary<NSString*, NSMutableArray<CRRoute*>*>* routes = [[self.server valueForKey:@"routes"] mutableCopy];
        NSMutableSet<NSURL*>* paths = [NSMutableSet set];

        [routes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray<CRRoute *> * _Nonnull obj, BOOL * _Nonnull stop) {
            if ( [key hasSuffix:@"*"] ) {
                return;
            }
            NSString* path = [key substringFromIndex:[key rangeOfString:@"/"].location + 1];
            [paths addObject:[self.baseURL URLByAppendingPathComponent:path]];
        }];

        NSArray<NSURL*>* sortedPaths =[paths sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"absoluteString" ascending:YES]]];
        [CRApp logFormat:@"Available paths are:"];
        [sortedPaths enumerateObjectsUsingBlock:^(NSURL * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [CRApp logFormat:@" * %@", obj.absoluteString];
        }];

    } else {
        [CRApp logErrorFormat:@"Failed to start HTTP server. %@", serverError.localizedDescription];
        [CRApp terminate:nil];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self.server stopListening];
}

#if LogConnections
- (void)server:(CRServer *)server didAcceptConnection:(CRConnection *)connection {
    [CRApp logFormat:@" * Accepted connection from %@:%d", connection.remoteAddress, connection.remotePort];
}

- (void)server:(CRServer *)server didCloseConnection:(CRConnection *)connection {
    [CRApp logFormat:@" * Disconnected %@:%d", connection.remoteAddress, connection.remotePort];
}
#endif

#if LogRequests
- (void)server:(CRServer *)server didFinishRequest:(CRRequest *)request {
    NSString* contentLength = [request.response valueForHTTPHeaderField:@"Content-Length"];
    [CRApp logFormat:@" * %@ %@ - %lu %@ - %@", request.response.connection.remoteAddress, request, request.response.statusCode, contentLength ? : @"-", request.env[@"HTTP_USER_AGENT"]];
}
#endif


@end
