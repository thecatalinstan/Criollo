//
//  NSHTTPCookie+Criollo.h
//  Criollo
//
//  Created by Cătălin Stan on 5/17/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSHTTPCookie (Criollo)

+ (nullable NSDictionary*)responseHeaderFieldsWithCookies:(nonnull NSArray *)cookies;

@end
