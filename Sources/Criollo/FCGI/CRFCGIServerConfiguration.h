//
//  CRFCGIServerConfiguration.h
//
//
//  Created by Cătălin Stan on 10/30/15.
//

#import <Foundation/Foundation.h>

#import "CRServerConfiguration.h"

@interface CRFCGIServerConfiguration : CRServerConfiguration

@property (nonatomic, assign) NSUInteger CRFCGIConnectionReadRecordTimeout;
@property (nonatomic, assign) NSUInteger CRFCGIConnectionSocketWriteBuffer;

@end
