//
//  NSData+CRLF.h
//  Criollo
//
//  Created by Cătălin Stan on 05/06/2021.
//  Copyright © 2021 Cătălin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (CRLF)

@property (class, readonly) NSData *CRLF;
@property (class, readonly) NSData *CRLFCRLF;
@property (class, readonly) NSData *zeroCRLFCRLF;
@property (class, readonly) NSData *space;

@end

NS_ASSUME_NONNULL_END
