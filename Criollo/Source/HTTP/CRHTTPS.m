//
//  CRHTTPS.m
//  Criollo
//
//  Created by Cătălin Stan on 10/09/2017.
//  Copyright © 2017 Cătălin Stan. All rights reserved.
//

#import "CRHTTPS.h"
#import "CRHTTPServer.h"

#if !SEC_OS_OSX_INCLUDES
typedef CFTypeRef SecKeychainRef;
#endif

@interface CRHTTPS ()

+ (SecKeychainRef)getKeychainWithError:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end

@implementation CRHTTPS

+ (SecKeychainRef)getKeychainWithError:(NSError * _Nullable __autoreleasing * _Nullable)error {
    SecKeychainRef keychain = NULL;
    *error = nil;
#if TARGET_OS_OSX
    NSString *keychainPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSUUID UUID].UUIDString];
    NSString *keychainPassword = [NSUUID UUID].UUIDString;
    OSStatus keychainCreationStatus = SecKeychainCreate(keychainPath.UTF8String, (UInt32)keychainPassword.length, keychainPassword.UTF8String, NO, NULL, &keychain);
    if ( keychainCreationStatus != errSecSuccess ) {
        *error = [[NSError alloc] initWithDomain:CRHTTPServerErrorDomain code:CRHTTPServerInternalError userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat: NSLocalizedString(@"Unable to create keychain. %@",), (__bridge NSString *)SecCopyErrorMessageString(keychainCreationStatus, NULL)]}];
        return NULL;
    }
#endif
    return keychain;
}

+ (NSArray *)parseIdentrityFile:(NSString *)identityFilePath password:(nonnull NSString *)password withError:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    NSError * identityReadError;
    NSData * identityContents = [NSData dataWithContentsOfFile:identityFilePath options:NSDataReadingUncached error:&identityReadError];
    if ( identityContents.length == 0 ) {
        *error = [[NSError alloc] initWithDomain:CRHTTPServerErrorDomain code:CRHTTPServerInvalidIdentityFile userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to parse PKCS12 identity file.",), NSUnderlyingErrorKey: identityReadError, CRHTTPServerIdentityPathKey: identityFilePath ? : @"(null)"}];
        return nil;
    }
    
    CFArrayRef identityImportItems = NULL;
    NSMutableDictionary *identityImportOptions = [NSMutableDictionary dictionary];
    identityImportOptions[(id)kSecImportExportPassphrase] = password ? : @"";
    
#if SEC_OS_OSX_INCLUDES
    // Create a temp keychain and import the private key into it
    SecKeychainRef keychain = [CRHTTPS getKeychainWithError:error];
    if ( *error != nil ) {
        return nil;
    }
    identityImportOptions[(id)kSecImportExportKeychain] = (__bridge id)keychain;
#endif
    
    OSStatus identityImportStatus = SecPKCS12Import((__bridge CFDataRef)identityContents, (__bridge CFDictionaryRef)identityImportOptions, &identityImportItems);
    
    if ( identityImportStatus != errSecSuccess ) {
        NSString *errorMessage;
#if SEC_OS_OSX_INCLUDES
        errorMessage = (__bridge NSString *)SecCopyErrorMessageString(identityImportStatus, NULL);
#else
        if ( identityImportStatus == errSecAuthFailed ) {
            errorMessage = NSLocalizedString(@"Invalid password when importing PKCS12 identity file.",);
        } else {
            errorMessage = NSLocalizedString(@"Unable to parse PKCS12 identity file.",);
        }
#endif
        *error = [[NSError alloc] initWithDomain:CRHTTPServerErrorDomain code:CRHTTPServerInvalidIdentityFile userInfo:@{NSLocalizedDescriptionKey: errorMessage, CRHTTPServerIdentityPathKey: identityFilePath ? : @"(null)"}];
        
#if SEC_OS_OSX_INCLUDES
        if ( keychain != NULL ) {
            SecKeychainDelete(keychain);
        }
#endif
    
        return nil;
    }

    CFDictionaryRef identityDictionary = CFArrayGetValueAtIndex(identityImportItems, 0);
    CFArrayRef certificateImportItems = CFDictionaryGetValue(identityDictionary, kSecImportItemCertChain);
    SecIdentityRef identity = (SecIdentityRef)CFDictionaryGetValue(identityDictionary, kSecImportItemIdentity);

    NSMutableArray *result = [NSMutableArray arrayWithCapacity:CFArrayGetCount(certificateImportItems)];
    [result addObjectsFromArray:(__bridge NSArray * _Nonnull)(certificateImportItems)];
    result[0] = (__bridge id _Nonnull)(identity);
    
    return result;
}

+ (NSArray *)parseCertificateFile:(NSString *)certificatePath certificateKeyFile:(NSString *)certificateKeyPath withError:(NSError *__autoreleasing  _Nullable *)error {
    
#if !SEC_OS_OSX_INCLUDES
    *error = [[NSError alloc] initWithDomain:CRHTTPServerErrorDomain code:CRHTTPServerInternalError userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Parsing certificate bundles and private keys is not yet implemented on iOS",), CRHTTPServerCertificatePathKey: certificatePath ? : @"(null)", CRHTTPServerCertificateKeyPathKey: certificateKeyPath ? : @"(null)"}];
    return @[];
#else
    NSError * pemCertReadError;
    NSData * pemCertContents = [NSData dataWithContentsOfFile:certificatePath options:NSDataReadingUncached error:&pemCertReadError];
    if ( pemCertContents.length == 0 ) {
        *error = [[NSError alloc] initWithDomain:CRHTTPServerErrorDomain code:CRHTTPServerInvalidCertificateBundle userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to parse PEM certificate bundle.",), NSUnderlyingErrorKey: pemCertReadError, CRHTTPServerCertificatePathKey: certificatePath ? : @"(null)", CRHTTPServerCertificateKeyPathKey:certificateKeyPath ? : @"(null)"}];
        return nil;
    }
    
    CFArrayRef certificateImportItems = NULL;
    OSStatus certificateImportStatus = SecItemImport((__bridge CFDataRef)pemCertContents , NULL, NULL, NULL, 0, NULL, NULL, &certificateImportItems);
    if ( certificateImportStatus != errSecSuccess ) {
        *error = [[NSError alloc] initWithDomain:CRHTTPServerErrorDomain code:CRHTTPServerInvalidCertificateBundle userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat: NSLocalizedString(@"Unable to parse PEM certificate bundle. %@",), (__bridge NSString *)SecCopyErrorMessageString(certificateImportStatus, NULL)], CRHTTPServerCertificatePathKey:certificatePath ? : @"(null)", CRHTTPServerCertificateKeyPathKey:certificateKeyPath ? : @"(null)"}];
        return nil;
    }
    
    // Check if the first item in the import is a certificate
    SecCertificateRef certificate = (SecCertificateRef) CFArrayGetValueAtIndex(certificateImportItems, 0);
    if ( CFGetTypeID(certificate) != SecCertificateGetTypeID() ) {
        *error = [[NSError alloc] initWithDomain:CRHTTPServerErrorDomain code:CRHTTPServerInvalidCertificateBundle userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat: NSLocalizedString(@"Expected a PEM certificate, but got %@ instead.",), (__bridge id)certificate], CRHTTPServerCertificatePathKey:certificatePath ? : @"(null)", CRHTTPServerCertificateKeyPathKey:certificateKeyPath ? : @"(null)"}];
        return nil;
    }
    
    // Read the contents of the PEM private key file and fetch SecKeyRef
    NSError * pemKeyReadError;
    NSData * pemKeyContents = [NSData dataWithContentsOfFile:certificateKeyPath options:NSDataReadingUncached error:&pemKeyReadError];
    if ( pemKeyContents.length == 0 ) {
        *error = [[NSError alloc] initWithDomain:CRHTTPServerErrorDomain code:CRHTTPServerInvalidCertificatePrivateKey userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to parse PEM RSA key file.",), NSUnderlyingErrorKey: pemKeyReadError, CRHTTPServerCertificatePathKey:certificatePath ? : @"(null)", CRHTTPServerCertificateKeyPathKey:certificateKeyPath ? : @"(null)"}];
        return nil;
    }
    
    // Create a temp keychain and import the private key into it
    SecKeychainRef keychain = [CRHTTPS getKeychainWithError:error];
    if ( *error != nil ) {
        return nil;
    }
    
    // Import the key into the keychain
    CFArrayRef keyImportItems = NULL;
    OSStatus keyImportStatus = SecItemImport((__bridge CFDataRef)pemKeyContents , NULL, NULL, NULL, 0, NULL, keychain, &keyImportItems);
    if ( keyImportStatus != errSecSuccess ) {
        *error = [[NSError alloc] initWithDomain:CRHTTPServerErrorDomain code:CRHTTPServerInvalidCertificatePrivateKey userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat: NSLocalizedString(@"Unable to parse PEM RSA key file. %@",), (__bridge NSString *)SecCopyErrorMessageString(keyImportStatus, NULL)], CRHTTPServerCertificatePathKey: certificatePath ? : @"(null)", CRHTTPServerCertificateKeyPathKey: certificateKeyPath ? : @"(null)"}];
        
        if ( keychain != NULL ) {
            SecKeychainDelete(keychain);
        }
        return nil;
    }
    
    // Check if the first item in the import is a privatekey
    SecKeyRef key = (SecKeyRef) CFArrayGetValueAtIndex(keyImportItems, 0);
    if ( CFGetTypeID(key) != SecKeyGetTypeID() ) {
        *error = [[NSError alloc] initWithDomain:CRHTTPServerErrorDomain code:CRHTTPServerInvalidCertificatePrivateKey userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat: NSLocalizedString(@"Expected a RSA private key, but got %@ instead.",), (__bridge id)key], CRHTTPServerCertificatePathKey: certificatePath ? : @"(null)", CRHTTPServerCertificateKeyPathKey: certificateKeyPath ? : @"(null)"}];
       
        if ( keychain != NULL ) {
            SecKeychainDelete(keychain);
        }
        return nil;
    }
    
    // Create an identity from the keychain and the certificate
    SecIdentityRef identity;
    OSStatus identityCreationStatus = SecIdentityCreateWithCertificate(keychain, certificate, &identity);
    if ( identityCreationStatus != errSecSuccess ) {
        *error = [[NSError alloc] initWithDomain:CRHTTPServerErrorDomain code:CRHTTPServerInvalidCertificatePrivateKey userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat: NSLocalizedString(@"Unable to get a suitable identity. %@",), (__bridge NSString *)SecCopyErrorMessageString(identityCreationStatus, NULL)], CRHTTPServerCertificatePathKey: certificatePath ? : @"(null)", CRHTTPServerCertificateKeyPathKey: certificateKeyPath ? : @"(null)"}];
        
        if ( keychain != NULL ) {
            SecKeychainDelete(keychain);
        }
        return nil;
    }
    
    // Create the outut array
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:CFArrayGetCount(certificateImportItems)];
    [result addObjectsFromArray:(__bridge NSArray * _Nonnull)(certificateImportItems)];
    result[0] = (__bridge id _Nonnull)(identity);
    
    // Cleanup
    SecKeychainDelete(keychain);
    
    return result;
#endif
}

@end
