//
//  SharedRequestHandler.m
//  HelloWorld
//
//  Created by Cătălin Stan on 11/9/15.
//
//

#import <CSSystemInfoHelper/CSSystemInfoHelper.h>

#import "CommonRequestHandler.h"

@interface CommonRequestHandler ()

@end

@implementation CommonRequestHandler

+ (instancetype)defaultHandler {
    static CommonRequestHandler* _defaultHandler;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultHandler = [[CommonRequestHandler alloc] init];
    });
    return _defaultHandler;
}

- (CRRouteBlock)identifyBlock {
    __block CRRouteBlock _identifyBlock;
    if ( _identifyBlock == nil ) {
        NSBundle *bundle = [NSBundle mainBundle];
        _identifyBlock = ^(CRRequest* request, CRResponse* response, CRRouteCompletionBlock completionHandler) {
            [response setValue:[NSString stringWithFormat:@"%@, %@ build %@", bundle.bundleIdentifier, [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [bundle objectForInfoDictionaryKey:@"CFBundleVersion"]] forHTTPHeaderField:@"Server"];

            if ( ! request.cookies[@"session_cookie"] ) {
                [response setCookie:@"session_cookie" value:[NSUUID UUID].UUIDString path:@"/" expires:nil domain:nil secure:NO];
            }
            [response setCookie:@"persistant_cookie" value:[NSUUID UUID].UUIDString path:@"/" expires:[NSDate distantFuture] domain:nil secure:NO];

            completionHandler();
        };
    };
    return _identifyBlock;
}

- (CRRouteBlock) helloWorldBlock {
    __block CRRouteBlock _helloWorldBlock;
    if ( _helloWorldBlock == nil ) {
        _helloWorldBlock = ^(CRRequest* request, CRResponse* response, CRRouteCompletionBlock completionHandler) {
            [response setValue:@"text/plain; charset=utf-8" forHTTPHeaderField:@"Content-type"];
            [response sendString:@"Hello World"];
            completionHandler();
        };
    };
    return _helloWorldBlock;
}

- (CRRouteBlock)jsonHelloWorldBlock {
    __block CRRouteBlock _jsonHelloWorldBlock;
    if ( _jsonHelloWorldBlock == nil ) {
        _jsonHelloWorldBlock = ^(CRRequest* request, CRResponse* response, CRRouteCompletionBlock completionHandler) {
            [response setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-type"];
            [response send:@{@"status": @YES, @"message": @"Hello World"}];
            completionHandler();
        };
    };
    return _jsonHelloWorldBlock;
}

- (CRRouteBlock)statusBlock {
    __block CRRouteBlock _statusBlock;
    if ( _statusBlock == nil ) {
        _statusBlock = ^(CRRequest* request, CRResponse* response, CRRouteCompletionBlock completionHandler) {

            NSDate *startTime = [NSDate date];
            NSBundle *bundle = [NSBundle mainBundle];

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
            [responseString appendFormat:@"<small>%@</small><br/>", CSSystemInfoHelper.sharedHelper.systemInfoString];
            [responseString appendFormat:@"<small>Task took: %.4fms</small>", [startTime timeIntervalSinceNow] * -1000];

            // HTML
            [responseString appendString:@"</body></html>"];
            
            [response setValue:@"text/html; charset=utf-8" forHTTPHeaderField:@"Content-type"];
            [response setValue:@(responseString.length).stringValue forHTTPHeaderField:@"Content-Length"];
            [response sendString:responseString];
            
            completionHandler();
        };
    };
    return _statusBlock;
}

- (CRRouteBlock)redirectBlock {
    __block CRRouteBlock _redirectBlock;
    if ( _redirectBlock == nil ) {
        _redirectBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
            NSURL* redirectURL = [NSURL URLWithString:(request.query[@"redirect"] ? : @"")];
            if ( redirectURL ) {
                [response redirectToURL:redirectURL];
            }
            completionHandler();
        };
    };
    return _redirectBlock;
}

@end
