//
//  CRHTTPConnection_Internal.h
//  Criollo
//
//  Created by Cătălin Stan on 04/06/2021.
//  Copyright © 2021 Cătălin Stan. All rights reserved.
//

#import "CRHTTPConnection.h"

typedef NS_ENUM(long, CRHTTPConnectionSocketTag) {
    CRHTTPConnectionSocketTagBeginReadingRequest = 10,
    CRHTTPConnectionSocketTagReadingRequestBody = 11,
};

NS_ASSUME_NONNULL_BEGIN

@interface CRHTTPConnection ()

@end

NS_ASSUME_NONNULL_END
