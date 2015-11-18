//
//  SharedRequestHandler.m
//  HelloWorld
//
//  Created by Cătălin Stan on 11/9/15.
//
//

#import "CommonRequestHandler.h"

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    #import <CriolloiOS/CriolloiOS.h>
#else
    #import <Criollo/Criollo.h>
#endif

#import <sys/utsname.h>

@interface CommonRequestHandler ()

@property (strong) NSString* uname;

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

- (instancetype)init {
    self = [super init];
    if ( self != nil ) {
        struct utsname systemInfo;
        uname(&systemInfo);
        _uname = [NSString stringWithFormat:@"%s %s %s %s %s", systemInfo.sysname, systemInfo.nodename, systemInfo.release, systemInfo.version, systemInfo.machine];
    }
    return self;
}

- (void (^)(CRRequest *, CRResponse *, void (^)()))helloWorldBlock {
    __block void(^_helloWorldBlock)(CRRequest*, CRResponse*, void(^)());
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _helloWorldBlock = ^(CRRequest* request, CRResponse* response, void(^completionHandler)()) {
            [response setValue:@"text/plain; charset=utf-8" forHTTPHeaderField:@"Content-type"];
            [response sendString:@"Hello World"];
            completionHandler();
        };
    });
    return _helloWorldBlock;
}

- (void (^)(CRRequest *, CRResponse *, void (^)()))jsonHelloWorldBlock {
    __block void(^_jsonHelloWorldBlock)(CRRequest*, CRResponse*, void(^)());
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _jsonHelloWorldBlock = ^(CRRequest* request, CRResponse* response, void(^completionHandler)()) {
            [response setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-type"];
            [response sendData:[NSJSONSerialization dataWithJSONObject:@{@"status": @YES, @"message": @"Hello World"} options:0 error:nil]];
            completionHandler();
        };
    });
    return _jsonHelloWorldBlock;
}

- (void (^)(CRRequest *, CRResponse *, void (^)()))statusBlock {
    __block void(^_statusBlock)(CRRequest*, CRResponse*, void(^)());
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _statusBlock = ^(CRRequest *request, CRResponse *response, void (^completionHandler)()) {

            NSDate* startTime = [NSDate date];

            NSMutableString* responseString = [[NSMutableString alloc] init];

            // Bundle Info
            [responseString appendFormat:@"<h1>%@</h1>", [NSBundle mainBundle].bundleIdentifier];
            [responseString appendFormat:@"<h2>Version %@ build %@</h2>", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];

            // Headers
            [responseString appendString:@"<h3>Request Headers:</h2><pre>"];
            [request.allHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
                [responseString appendFormat:@"%@: %@\n", key, obj];
            }];
            [responseString appendString:@"</pre>"];

            // Request enviroment
            [responseString appendString:@"<h3>Request Enviroment:</h2><pre>"];
            [request.env enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
                [responseString appendFormat:@"%@: %@\n", key, obj];
            }];
            [responseString appendString:@"</pre>"];

            // Stack trace
            [responseString appendString:@"<h3>Stack Trace:</h2><pre>"];
            [[NSThread callStackSymbols] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [responseString appendFormat:@"%@\n", obj];
            }];
            [responseString appendString:@"</pre>"];

            [responseString appendString:@"<hr/>"];
            [responseString appendFormat:@"<small>%@</small><br/>", _uname];
            [responseString appendFormat:@"<small>Task took: %.4fms</small>", [startTime timeIntervalSinceNow] * -1000];

            [response setValue:@"text/html; charset=utf-8" forHTTPHeaderField:@"Content-type"];
            [response setValue:@(responseString.length).stringValue forHTTPHeaderField:@"Content-Length"];
            [response sendString:responseString];
            
            completionHandler();
        };
    });
    return _statusBlock;
}

@end
