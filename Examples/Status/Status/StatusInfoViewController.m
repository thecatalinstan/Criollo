//
//  StatusInfoViewController.m
//  Status
//
//  Created by Cătălin Stan on 12/04/15.
//  Copyright (c) 2015 Catalin Stan. All rights reserved.
//

#import <stdlib.h>
#import <stdio.h>
#import <sys/types.h>
#import <sys/sysctl.h>

#import "StatusInfoViewController.h"
#import <FCGIKit/FCGIKit.h>

@implementation StatusInfoViewController

- (void)viewDidLoad
{
    [self.response setValue:( @"text/plain; charset=utf-8" ) forHTTPHeaderField:@"Content-type"];
}

- (NSString *)presentViewController:(BOOL)writeData
{
    
    @try {
        NSProcessInfo* processInfo = [NSProcessInfo processInfo];

        NSMutableArray* outputLines = [NSMutableArray array];

        [outputLines addObject:[NSString stringWithFormat:@"%@, Mac OS X %@", self.machineModel, processInfo.operatingSystemVersionString]];
        
        [outputLines addObject:[self cmd:@"/usr/bin/uname" args:@"-a"]];
        [outputLines addObject:[self cmd:@"/usr/bin/uptime" args:nil]];
        [outputLines addObject:[self cmd:@"/bin/df" args:@"-h"]];
        [outputLines addObject:[self cmd:@"/bin/ps" args:@"-A"]];
        
        NSString* output = [outputLines componentsJoinedByString:@"\n\n"];
        
        if ( writeData ) {
            [self.response writeString:output];
            
            if ( self.automaticallyFinishesResponse ) {
                [self.response finish];
            }
        }
        return output;
    } @catch(NSException* exception) {
        NSError* error = [NSError errorWithDomain:[NSBundle mainBundle].bundleIdentifier code:1 userInfo:@{NSUnderlyingErrorKey: exception}];
        [self failWithError:error];
    }
}

- (NSString*)cmd:(NSString*)cmd args:(NSString*)arg
{
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *file = pipe.fileHandleForReading;
    
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = cmd;
    if(arg != nil) {
        task.arguments = @[arg];
    }
    task.standardOutput = pipe;
    [task launch];
    
    NSData *data = [file readDataToEndOfFile];
    [file closeFile];
    
    return [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
}

- (BOOL)automaticallyFinishesResponse
{
    return YES;
}

- (NSString *)machineModel
{
    size_t len = 0;
    sysctlbyname("hw.model", NULL, &len, NULL, 0);
    
    if (len) {
        char *model = malloc(len*sizeof(char));
        sysctlbyname("hw.model", model, &len, NULL, 0);
        NSString *model_ns = [NSString stringWithUTF8String:model];
        free(model);
        return model_ns;
    }
    
    return @"Just an Apple Computer"; //incase model name can't be read
}

- (void)failWithError:(NSError*)error
{
    NSString* errorDescription;
    NSString* errorTitle;
    NSDictionary* errorUserInfo;
    NSUInteger errorCode;
    
    if ( error.userInfo[NSUnderlyingErrorKey] ) {
        if ( [error.userInfo[NSUnderlyingErrorKey] isKindOfClass:[NSError class] ] ) {
            NSError* underlyingError = error.userInfo[NSUnderlyingErrorKey];
            errorTitle = underlyingError.domain;
            errorCode = underlyingError.code;
            errorDescription = underlyingError.localizedDescription;
            errorUserInfo = underlyingError.userInfo;
        } else if ( [error.userInfo[NSUnderlyingErrorKey] isKindOfClass:[NSException class] ] ) {
            NSException* underlyingError = error.userInfo[NSUnderlyingErrorKey];
            errorTitle = underlyingError.name;
            errorCode = NSNotFound;
            errorDescription = underlyingError.reason;
            errorUserInfo = underlyingError.userInfo;
        } else {
            errorTitle = error.domain;
            errorCode = error.code;
            errorDescription = error.localizedDescription;
            errorUserInfo = error.userInfo;
        }
    } else {
        errorTitle = error.domain;
        errorCode = error.code;
        errorDescription = error.localizedDescription;
        errorUserInfo = error.userInfo;
    }
    
    [self.response setHTTPStatus:500];
    
    NSMutableDictionary* outputDictionary = [NSMutableDictionary dictionary];
    outputDictionary[@"status"] = @(NO);
    outputDictionary[@"error"] = @{
                                   @"domain": errorTitle,
                                   @"code": @(errorCode),
                                   @"description": errorDescription,
                                   };
    
    [self.response writeString:outputDictionary.description];
    
    [self.response finish];
}


@end
