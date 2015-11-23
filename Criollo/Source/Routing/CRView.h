//
//  CRView.h
//  Criollo
//
//  Created by Cătălin Stan on 5/17/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

@interface CRView : NSObject 

@property (nonatomic, readonly, strong, nonnull) NSString *contents;

- (nonnull instancetype)initWithContents:(nullable NSString *)contents NS_DESIGNATED_INITIALIZER;

- (nonnull NSString*)render:(nullable NSDictionary *)templateVariables;

@end
