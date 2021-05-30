//
//  CRFCGIConnection.h
//  Criollo
//
//  Created by Cătălin Stan on 10/25/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import <Criollo/CRConnection.h>

#define CRFCGIConnectionSocketTagReadRecordHeader                       11
#define CRFCGIConnectionSocketTagReadRecordContent                      12

#define CRFCGIConnectionSocketTagSendingResponse                        20

NS_ASSUME_NONNULL_BEGIN

@interface CRFCGIConnection : CRConnection

@end

NS_ASSUME_NONNULL_END
