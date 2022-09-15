//
//  NSData+CRLF.h
//
//
//  Created by Cătălin Stan on 05/06/2021.
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
