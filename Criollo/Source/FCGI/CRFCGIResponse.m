//
//  CRFCGIResponse.m
//  Criollo
//
//  Created by Cătălin Stan on 10/30/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRFCGIResponse.h"

@interface CRFCGIResponse () {
    BOOL _alreadySentHeaders;
}

- (void)sendEndResponseRecord:(BOOL)closeConnection;

@end

@implementation CRFCGIResponse

- (void)sendEndResponseRecord:(BOOL)closeConnection {
    
}

@end
