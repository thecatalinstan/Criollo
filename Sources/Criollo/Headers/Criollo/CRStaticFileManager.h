//
//  CRStaticFileManager.h
//
//
//  Created by Cătălin Stan on 10/03/16.
//

#import <Criollo/CRContentDisposition.h>
#import <Criollo/CRRouteBlock.h>
#import <Criollo/CRStaticFileServingOptions.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CRStaticFileManager : NSObject

@property (nonatomic, readonly, copy) CRRouteBlock routeBlock;

+ (instancetype)managerWithFileAtPath:(NSString *)path
                              options:(CRStaticFileServingOptions)options;

- (instancetype)initWithFileAtPath:(NSString *)path
                           options:(CRStaticFileServingOptions)options
                          fileName:(NSString * _Nullable)fileName
                       contentType:(NSString * _Nullable)contentType
                contentDisposition:(CRContentDisposition _Nullable)contentDisposition
                        attributes:(NSDictionary<NSFileAttributeKey, id> * _Nullable)attributes
NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

NS_ASSUME_NONNULL_END

@end
