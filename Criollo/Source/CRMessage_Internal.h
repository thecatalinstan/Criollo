//
//  CRMessage_Internal.h
//  Criollo
//
//  Created by Cătălin Stan on 11/20/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRMessage.h"

@interface CRMessage ()

@property (nonatomic, readonly) NSData* serializedData;
@property (nonatomic, strong) id message;
@property (nonatomic, readonly) BOOL headersComplete;

@end
