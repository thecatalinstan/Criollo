//
//  CRHTTPMethod.m
//  
//
//  Created by Cătălin Stan on 18/09/2022.
//

#import <Criollo/CRHTTPMethod.h>

CRHTTPMethod const CRHTTPMethodNone = @"NONE";
CRHTTPMethod const CRHTTPMethodGet = @"GET";
CRHTTPMethod const CRHTTPMethodHead = @"HEAD";
CRHTTPMethod const CRHTTPMethodPost = @"POST";
CRHTTPMethod const CRHTTPMethodPut = @"PUT";
CRHTTPMethod const CRHTTPMethodDelete = @"DELETE";
CRHTTPMethod const CRHTTPMethodConnect = @"CONNECT";
CRHTTPMethod const CRHTTPMethodOptions = @"OPTIONS";
CRHTTPMethod const CRHTTPMethodPatch = @"PATCH";
CRHTTPMethod const CRHTTPMethodAny = @"ALL";

CRHTTPMethod CRHTTPMethodMake(NSString *methodSpec) {
    CRHTTPMethod HTTPMethod;
    if ([methodSpec isEqualToString:CRHTTPMethodGet]) {
        HTTPMethod = CRHTTPMethodGet;
    } else if ([methodSpec isEqualToString:CRHTTPMethodHead]) {
        HTTPMethod = CRHTTPMethodHead;
    } else if ([methodSpec isEqualToString:CRHTTPMethodPost]) {
        HTTPMethod = CRHTTPMethodPost;
    } else if ([methodSpec isEqualToString:CRHTTPMethodPut]) {
        HTTPMethod = CRHTTPMethodPut;
    } else if ([methodSpec isEqualToString:CRHTTPMethodDelete]) {
        HTTPMethod = CRHTTPMethodDelete;
    } else if ([methodSpec isEqualToString:CRHTTPMethodConnect]) {
        HTTPMethod = CRHTTPMethodConnect;
    } else if ([methodSpec isEqualToString:CRHTTPMethodOptions]) {
        HTTPMethod = CRHTTPMethodOptions;
    } else if ([methodSpec isEqualToString:CRHTTPMethodPatch]) {
        HTTPMethod = CRHTTPMethodPatch;
    } else if ([methodSpec isEqualToString:CRHTTPMethodAny]) {
        HTTPMethod = CRHTTPMethodAny;
    }
    return HTTPMethod;
}
