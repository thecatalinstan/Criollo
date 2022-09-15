//
//  CRHTTPResponse.h
//
//
//  Created by Cătălin Stan on 10/30/15.
//

#import <Criollo/CRResponse.h>

@interface CRHTTPResponse : CRResponse

@property (nonatomic, readonly) BOOL isChunked;

@end
