
//
//  StatusFileViewController.m
//  Status
//
//  Created by Cătălin Stan on 23/04/15.
//  Copyright (c) 2015 Catalin Stan. All rights reserved.
//

#import "StatusFileViewController.h"
#import <Cocoa/Cocoa.h>

@implementation StatusFileViewController

- (NSString*)presentViewController:(BOOL)writeData
{
    NSString* path = [self.request.get[@"path"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSError* error;
    NSURLResponse* response;
    NSURLRequest* fileUrlRequest;
    NSData* fileData;
    
    if ( path.length == 0 ) {
        error = [[NSError alloc] initWithDomain:[NSBundle mainBundle].bundleIdentifier code:-1 userInfo:@{NSLocalizedDescriptionKey:@"No file provided"}];
    }

    if ( error == nil ) {
        @try {
            NSURL* fileUrl = [NSURL fileURLWithPath:path];
            fileUrlRequest = [[NSURLRequest alloc] initWithURL:fileUrl];
        } @catch (NSException* ex) {
            error = [[NSError alloc] initWithDomain:[NSBundle mainBundle].bundleIdentifier code:-1 userInfo:@{NSLocalizedDescriptionKey: ex.reason}];
        }
    }
    if ( error == nil ) {
        fileData = [NSURLConnection sendSynchronousRequest:fileUrlRequest returningResponse:&response error:&error];
    }
    
    
    if ( error != nil ) {
        [self.response setHTTPStatus:500];
        [self.response setValue:@"text/plain" forHTTPHeaderField:@"Content-type"];
        [self.response writeString:error.localizedDescription];
        if ( path.length != 0 ) {
            [self.response writeString:@"\n"];
            [self.response writeString:path];
        }
    } else {
        [self.response setHTTPStatus:200];
        [self.response setValue:response.MIMEType forHTTPHeaderField:@"Content-type"];
        [self.response setValue:@(fileData.length).stringValue forHTTPHeaderField:@"Content-length"];
        [self.response write:fileData];
    }
    
    [self.response finish];

    return nil;
}

@end
