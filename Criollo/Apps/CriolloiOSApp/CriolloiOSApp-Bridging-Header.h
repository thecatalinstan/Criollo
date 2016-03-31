//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//
@import Foundation;

// These are C functions because they use POSIX API's

BOOL getIPAddress(NSString** address);
NSString* systemInfo(void);

