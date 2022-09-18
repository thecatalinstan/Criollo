//
//  CRHTTPVersion.m
//  
//
//  Created by Cătălin Stan on 18/09/2022.
//

#import <Criollo/CRHTTPVersion.h>

CRHTTPVersion const CRHTTPVersion1_0 = @"HTTP/1.0";
CRHTTPVersion const CRHTTPVersion1_1 = @"HTTP/1.1";
CRHTTPVersion const CRHTTPVersion2_0 = @"HTTP/2.0";
CRHTTPVersion const CRHTTPVersion3_0 = @"HTTP/3.0";

CRHTTPVersion CRHTTPVersionFromString(NSString * versionSpec) {
    CRHTTPVersion version;
    if ([versionSpec isEqualToString:CRHTTPVersion1_0]) {
        version = CRHTTPVersion1_0;
    } else if ([versionSpec isEqualToString:CRHTTPVersion1_1]) {
        version = CRHTTPVersion1_1;
    } else if ([versionSpec isEqualToString:CRHTTPVersion2_0]) {
        version = CRHTTPVersion2_0;
    } else if (@available(macOS 10.15, *)) {
        if ([versionSpec isEqualToString:CRHTTPVersion3_0]) {
            version = CRHTTPVersion3_0;
        }
    }
    return version;
}
