//
//  CRHTTPS.h
//  Criollo
//
//  Created by Cătălin Stan on 10/09/2017.
//  Copyright © 2017 Cătălin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CRHTTPS : NSObject

+ (nullable NSArray *)parseIdentrityFile:(NSString *)identityFilePath password:(NSString *)password withError:(NSError * _Nullable __autoreleasing * _Nullable)error;
+ (nullable NSArray *)parseCertificateFile:(NSString *)certificatePath certificateKeyFile:(NSString *)certificateKeyPath withError:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
