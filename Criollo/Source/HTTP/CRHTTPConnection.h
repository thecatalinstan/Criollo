//
//  CRHTTPConnection.h
//  Criollo
//
//  Created by Cătălin Stan on 10/25/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRConnection.h"

@class CRRequest, CRResponse;

#define CRHTTPConnectionSocketTagSendingResponse                      20

#define CRHTTPConnectionSocketTagBeginReadingRequest                  10
#define CRHTTPConnectionSocketTagReadingRequestHeader                 11
#define CRHTTPConnectionSocketTagReadingRequestBody                   12

#define CRHTTPConnectionSocketTagFinishSendingResponse                90
#define CRHTTPConnectionSocketTagFinishSendingResponseAndClosing      91

@interface CRHTTPConnection : CRConnection

@end
