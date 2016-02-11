//
//  utils.m
//  HelloWorld-ObjC
//
//  Created by Cătălin Stan on 11/19/15.
//
//

@import Foundation;

#include <stdio.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <sys/utsname.h>

// see: http://stackoverflow.com/questions/6807788/how-to-get-ip-address-of-iphone-programatically
BOOL getIPAddress(NSString** address) {
    BOOL result = NO;
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    success = getifaddrs(&interfaces);
    if (success == 0) {
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    *address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    result = YES;
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }

    freeifaddrs(interfaces);
    return result;
}

NSString* systemInfo(void) {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithFormat:@"%s %s %s %s %s", systemInfo.sysname, systemInfo.nodename, systemInfo.release, systemInfo.version, systemInfo.machine];
}
