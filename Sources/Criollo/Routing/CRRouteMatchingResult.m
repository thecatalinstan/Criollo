//
//  CRRouteMatchingResult.m
//
//
//  Created by Cătălin Stan on 24/07/16.
//

#import "CRRouteMatchingResult_Internal.h"

@implementation CRRouteMatchingResult

- (instancetype)initWithRoute:(CRRoute *)route matches:(NSArray<NSString *> *)matches {
    self = [super init];
    if (self != nil) {
        _route = route;
        _matches = matches;
    }
    return self;
}

@end
