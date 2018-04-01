//
//  APIController.m
//  Criollo macOS App
//
//  Created by Cătălin Stan on 19/07/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import "APIController.h"
#import "SystemInfoHelper.h"

@implementation APIController

- (instancetype)initWithPrefix:(NSString *)prefix {
    self = [super initWithPrefix:prefix];
    if ( self != nil ) {
        // Prints some more info as text/html
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *uname = [SystemInfoHelper systemInfo];
        
        [self add:@"/env" block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
            [response send:request.env];
        }];

        [self get:@"/status" block:^(CRRequest *request, CRResponse *response, CRRouteCompletionBlock completionHandler ) {

            @autoreleasepool {
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
            }
        }];

        [self get:@"/info" block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
            @autoreleasepool {
                NSDictionary *info = @{
                                       @"IPAddress": [SystemInfoHelper IPAddress],
                                       @"systemInfo": [SystemInfoHelper systemInfo],
                                       @"systemVersion": [SystemInfoHelper systemVersion],
                                       @"processName": [SystemInfoHelper processName],
                                       @"processRunningTime": [SystemInfoHelper processRunningTime],
                                       @"memoryInfo": [SystemInfoHelper memoryInfo:nil],
                                       @"requestsServed": [SystemInfoHelper requestsServed],
                                       @"criolloVersion": [SystemInfoHelper criolloVersion],
                                       @"bundleVersion": [SystemInfoHelper bundleVersion]
                                       };
                @try {
                    [response sendData:[NSJSONSerialization dataWithJSONObject:info options:NSJSONWritingPrettyPrinted error:nil]];
                } @catch (NSException *exception) {
                    NSError* error = [NSError errorWithDomain:CRErrorDomain code:100 userInfo:@{NSLocalizedDescriptionKey: exception.reason}];
                    [CRRouter errorHandlingBlockWithStatus:500 error:error](request, response, completionHandler);
                }
            }

        }];

    }
    return self;
}

@end
