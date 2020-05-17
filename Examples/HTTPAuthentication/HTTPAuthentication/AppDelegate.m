//
//  AppDelegate.m
//  HTTPAuthentication
//
//  Created by Cătălin Stan on 17/05/2020.
//  Copyright © 2020 Criollo. All rights reserved.
//

#import "AppDelegate.h"

static NSString *const interface = @"127.0.0.1";
static uint16_t const port = 10781;

@interface AppDelegate () <CRServerDelegate>

@property (nonatomic, strong) CRHTTPServer *server;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.server = [[CRHTTPServer alloc] init];
    self.server.delegate = self;
    
    __weak typeof(self) wself = self;
    
    // Authentication filter
    [self.server add:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completion) {
        
        // The user is authenticated, proceed
        if ([wself validateAuthotization:request.env[@"HTTP_AUTHORIZATION"]]) {
            completion();
            return;
        }
        
        // Send an unauthorized (401), followed by a WWW-Authenticate header
        [response setStatusCode:401 description:nil];
        [response setValue:[NSString stringWithFormat:@"Basic realm=\"%@\"", @"asdfasdf"] forHTTPHeaderField:@"WWW-Authenticate"];
        [response setValue:@"0" forHTTPHeaderField:@"Content-Length"];
        [response finish];
    }];
    
    // Hello world /
    [self.server get:@"/" block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completion) {
        [response send:@"Hello world!"];
        completion();
    }];
    
    // Static directory /pub
    [self.server mount:@"/pub" directoryAtPath:@"~" options:CRStaticDirectoryServingOptionsAutoIndex];
    
    // Static file /info.plist
    [self.server mount:@"/Info.plist"
            fileAtPath:[NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"Contents/Info.plist"]
               options:CRStaticFileServingOptionsCache
              fileName:@"Info.plist"
           contentType:@"application/xml"
    contentDisposition:CRStaticFileContentDispositionInline];
    
    // Quit app /quit
    [self.server get:@"/quit" block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completion) {
        [response send:@"Bye!"];
        completion();
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [CRApplication.sharedApplication terminate:nil];
        });
    }];
    
    NSError *error;
    if (![self.server startListening:&error]) {
        NSLog(@"%@", error);
        [CRApplication.sharedApplication terminate:self.server];
        return;
    }
}

#pragma mark - CRServerDelegate

- (void)serverDidStartListening:(CRServer *)server {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%d", interface, port]];
    NSArray<NSString *> * routePaths = [self.server valueForKeyPath:@"routes.path"];
    NSMutableArray<NSURL *> *paths = [NSMutableArray arrayWithCapacity:routePaths.count];
    [routePaths enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ( [obj isKindOfClass:[NSNull class]] ) {
            return;
        }
        [paths addObject:[baseURL URLByAppendingPathComponent:obj]];
    }];
    NSArray<NSURL*>* sortedPaths =[paths sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"absoluteString" ascending:YES]]];
    [CRApp logFormat:@"Available paths are:"];
    [sortedPaths enumerateObjectsUsingBlock:^(NSURL * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [CRApp logFormat:@" %@", obj.absoluteString];
    }];
}

#pragma mark - Authentication

- (BOOL)validateAuthotization:(NSString *)authorization {
    authorization = [authorization componentsSeparatedByString:@" "].lastObject;
    if (!authorization.length) {
        return NO;
    }
    
    // This should be done more rigurously to support multiple languages
    NSData *data;
    if (!(data = [[NSData alloc] initWithBase64EncodedString:authorization options:NSDataBase64DecodingIgnoreUnknownCharacters])) {
        return NO;
    }
    
    if (!(authorization = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding])) {
        return NO;
    }
    
    // For the purspose of this demo, we'll allow any credentials
    return YES;
}

@end
