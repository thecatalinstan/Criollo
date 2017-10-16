//
//  CRHTTPS.m
//  Criollo
//
//  Created by Cătălin Stan on 10/09/2017.
//  Copyright © 2017 Cătălin Stan. All rights reserved.
//

#import "CRHTTPS.h"
#import "CRHTTPS.h"

#if !SEC_OS_OSX_INCLUDES

#import <openssl/bio.h>
#import <openssl/err.h>
#import <openssl/pem.h>
#import <openssl/pkcs12.h>
#import <openssl/x509.h>

typedef CFTypeRef SecKeychainRef;

#endif

NS_ASSUME_NONNULL_BEGIN

@interface CRHTTPS ()

+ (SecKeychainRef _Nullable)getKeychainWithError:(NSError * _Nullable __autoreleasing * _Nullable)error;

#if !SEC_OS_OSX_INCLUDES
+ (NSString * _Nullable)creaIdentrityFileWithPassword:(NSString *)password certificate:(NSData *)certificate certificateKey:(NSData *)certificateKey withError:(NSError *__autoreleasing  _Nullable * _Nullable)error;
#endif

@end

NS_ASSUME_NONNULL_END

@implementation CRHTTPS

+ (SecKeychainRef)getKeychainWithError:(NSError * _Nullable __autoreleasing * _Nullable)error {
    SecKeychainRef keychain = NULL;
    *error = nil;
#if SEC_OS_OSX_INCLUDES
    NSString *keychainPath = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
    NSString *keychainPassword = NSUUID.UUID.UUIDString;
    OSStatus keychainCreationStatus = SecKeychainCreate(keychainPath.UTF8String, (UInt32)keychainPassword.length, keychainPassword.UTF8String, NO, NULL, &keychain);
    if ( keychainCreationStatus != errSecSuccess ) {
        *error = [[NSError alloc] initWithDomain:CRHTTPSErrorDomain code:CRHTTPSInternalError userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat: NSLocalizedString(@"Unable to create keychain. %@",), (__bridge NSString *)SecCopyErrorMessageString(keychainCreationStatus, NULL)]}];
        return NULL;
    }
#endif
    return keychain;
}

+ (NSArray *)parseIdentrityFile:(NSString *)identityFilePath password:(nonnull NSString *)password withError:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    NSError * identityReadError;
    NSData * identityContents = [NSData dataWithContentsOfFile:identityFilePath options:NSDataReadingUncached error:&identityReadError];
    if ( identityContents.length == 0 ) {
        *error = [[NSError alloc] initWithDomain:CRHTTPSErrorDomain code:CRHTTPSInvalidIdentityFile userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to parse PKCS12 identity file.",), NSUnderlyingErrorKey: identityReadError, CRHTTPSIdentityPathKey: identityFilePath ? : @"(null)"}];
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
        *error = [[NSError alloc] initWithDomain:CRHTTPSErrorDomain code:CRHTTPSInvalidIdentityFile userInfo:@{NSLocalizedDescriptionKey: errorMessage, CRHTTPSIdentityPathKey: identityFilePath ? : @"(null)"}];
        
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
    
    NSError * pemCertReadError;
    NSData * pemCertContents = [NSData dataWithContentsOfFile:certificatePath options:NSDataReadingUncached error:&pemCertReadError];
    if ( pemCertContents.length == 0 ) {
        *error = [[NSError alloc] initWithDomain:CRHTTPSErrorDomain code:CRHTTPSInvalidCertificateBundle userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to parse PEM certificate bundle.",), NSUnderlyingErrorKey: pemCertReadError, CRHTTPSCertificatePathKey: certificatePath ? : @"(null)", CRHTTPSCertificateKeyPathKey:certificateKeyPath ? : @"(null)"}];
        return nil;
    }
    
    // Read the contents of the PEM private key file and fetch SecKeyRef
    NSError * pemKeyReadError;
    NSData * pemKeyContents = [NSData dataWithContentsOfFile:certificateKeyPath options:NSDataReadingUncached error:&pemKeyReadError];
    if ( pemKeyContents.length == 0 ) {
        *error = [[NSError alloc] initWithDomain:CRHTTPSErrorDomain code:CRHTTPSInvalidCertificatePrivateKey userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to parse PEM RSA key file.",), NSUnderlyingErrorKey: pemKeyReadError, CRHTTPSCertificatePathKey:certificatePath ? : @"(null)", CRHTTPSCertificateKeyPathKey:certificateKeyPath ? : @"(null)"}];
        return nil;
    }
    
#if !SEC_OS_OSX_INCLUDES
    
    NSString *password = NSUUID.UUID.UUIDString;
    
    NSError *identityCreateError;
    NSString *identityPath = [self creaIdentrityFileWithPassword:password certificate:pemCertContents certificateKey:pemKeyContents withError:&identityCreateError];
    if ( identityPath.length == 0 ) {
        *error = [[NSError alloc] initWithDomain:CRHTTPSErrorDomain code:CRHTTPSIdentityCreateError userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to create temporary PKS12 identity file.",), NSUnderlyingErrorKey: identityCreateError, CRHTTPSCertificatePathKey: certificatePath ? : @"(null)", CRHTTPSCertificateKeyPathKey:certificateKeyPath ? : @"(null)"}];
        return nil;
    }
    
    NSArray *result = [self parseIdentrityFile:identityPath password:password withError:error];
    [NSFileManager.defaultManager removeItemAtPath:identityPath error:nil];
    return result;
    
#else
    
    CFArrayRef certificateImportItems = NULL;
    OSStatus certificateImportStatus = SecItemImport((__bridge CFDataRef)pemCertContents , NULL, NULL, NULL, 0, NULL, NULL, &certificateImportItems);
    if ( certificateImportStatus != errSecSuccess ) {
        *error = [[NSError alloc] initWithDomain:CRHTTPSErrorDomain code:CRHTTPSInvalidCertificateBundle userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat: NSLocalizedString(@"Unable to parse PEM certificate bundle. %@",), (__bridge NSString *)SecCopyErrorMessageString(certificateImportStatus, NULL)], CRHTTPSCertificatePathKey:certificatePath ? : @"(null)", CRHTTPSCertificateKeyPathKey:certificateKeyPath ? : @"(null)"}];
        return nil;
    }
    
    // Check if the first item in the import is a certificate
    SecCertificateRef certificate = (SecCertificateRef) CFArrayGetValueAtIndex(certificateImportItems, 0);
    if ( CFGetTypeID(certificate) != SecCertificateGetTypeID() ) {
        *error = [[NSError alloc] initWithDomain:CRHTTPSErrorDomain code:CRHTTPSInvalidCertificateBundle userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat: NSLocalizedString(@"Expected a PEM certificate, but got %@ instead.",), (__bridge id)certificate], CRHTTPSCertificatePathKey:certificatePath ? : @"(null)", CRHTTPSCertificateKeyPathKey:certificateKeyPath ? : @"(null)"}];
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
        *error = [[NSError alloc] initWithDomain:CRHTTPSErrorDomain code:CRHTTPSInvalidCertificatePrivateKey userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat: NSLocalizedString(@"Unable to parse PEM RSA key file. %@",), (__bridge NSString *)SecCopyErrorMessageString(keyImportStatus, NULL)], CRHTTPSCertificatePathKey: certificatePath ? : @"(null)", CRHTTPSCertificateKeyPathKey: certificateKeyPath ? : @"(null)"}];
        
        if ( keychain != NULL ) {
            SecKeychainDelete(keychain);
        }
        return nil;
    }
    
    // Check if the first item in the import is a privatekey
    SecKeyRef key = (SecKeyRef) CFArrayGetValueAtIndex(keyImportItems, 0);
    if ( CFGetTypeID(key) != SecKeyGetTypeID() ) {
        *error = [[NSError alloc] initWithDomain:CRHTTPSErrorDomain code:CRHTTPSInvalidCertificatePrivateKey userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat: NSLocalizedString(@"Expected a RSA private key, but got %@ instead.",), (__bridge id)key], CRHTTPSCertificatePathKey: certificatePath ? : @"(null)", CRHTTPSCertificateKeyPathKey: certificateKeyPath ? : @"(null)"}];
       
        if ( keychain != NULL ) {
            SecKeychainDelete(keychain);
        }
        return nil;
    }
    
    // Create an identity from the keychain and the certificate
    SecIdentityRef identity;
    OSStatus identityCreationStatus = SecIdentityCreateWithCertificate(keychain, certificate, &identity);
    if ( identityCreationStatus != errSecSuccess ) {
        *error = [[NSError alloc] initWithDomain:CRHTTPSErrorDomain code:CRHTTPSInvalidCertificatePrivateKey userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat: NSLocalizedString(@"Unable to get a suitable identity. %@",), (__bridge NSString *)SecCopyErrorMessageString(identityCreationStatus, NULL)], CRHTTPSCertificatePathKey: certificatePath ? : @"(null)", CRHTTPSCertificateKeyPathKey: certificateKeyPath ? : @"(null)"}];
        
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
    if ( keychain != NULL ) {
        SecKeychainDelete(keychain);
    }
    
    return result;
#endif
}

#if !SEC_OS_OSX_INCLUDES
+ (NSString *)creaIdentrityFileWithPassword:(NSString *)password certificate:(NSData *)certificate certificateKey:(NSData *)certificateKey withError:(NSError * _Nullable __autoreleasing *)error {
    
    *error = nil;
    
    // Attempt to parse cert as DER encoded
    const unsigned char *cert_data = (unsigned char *)certificate.bytes;
    X509 *cert = d2i_X509(NULL, &cert_data, certificate.length);
    if ( cert == NULL ) {
        // Attempt to parse cert as PEM encoded
        BIO *bpCert = BIO_new_mem_buf(certificate.bytes, (int)certificate.length);
        cert = PEM_read_bio_X509(bpCert, NULL, NULL, NULL);
        if ( cert == NULL ) {
            char *err = ERR_error_string(ERR_get_error(), NULL);
            *error = [NSError errorWithDomain:CRSSLErrorDomain code:CRSSLInvalidCertificateBundle userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithUTF8String:err] ? : @"(null)"}];
            BIO_free(bpCert);
            return nil;
        }
        BIO_free(bpCert);
    }

    // Attempt to parse key as DER encoded
    const unsigned char *key_data = (unsigned char *)certificateKey.bytes;
    EVP_PKEY *key = d2i_AutoPrivateKey(NULL, &key_data, certificateKey.length);
    if ( key == NULL ) {
        // Attempt to parse key as PEM encoded
        BIO *bpkey = BIO_new_mem_buf(certificateKey.bytes, (int)certificateKey.length);
        key = PEM_read_bio_PrivateKey(bpkey, NULL, NULL, NULL);
        if ( key == NULL ) {
            char *err = ERR_error_string(ERR_get_error(), NULL);
            *error = [NSError errorWithDomain:CRSSLErrorDomain code:CRSSLInvalidCertificateBundle userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithUTF8String:err] ? : @"(null)"}];
            X509_free(cert);
            BIO_free(bpkey);
            return nil;
        }
        BIO_free(bpkey);
    }
    
    NSString *identityPath = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
    
    PKCS12 *p12 = PKCS12_create(password.UTF8String, identityPath.lastPathComponent.UTF8String, key, cert, NULL, 0, 0, 0, 0, 0);
    if ( p12 == NULL ) {
        ERR_print_errors_fp(stderr);
        char *err = ERR_error_string(ERR_get_error(), NULL);
        *error = [NSError errorWithDomain:CRSSLErrorDomain code:CRSSLIdentityCreateError userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithUTF8String:err] ? : @"(null)"}];
        X509_free(cert);
        EVP_PKEY_free(key);
        return nil;
    }

    X509_free(cert);
    EVP_PKEY_free(key);
    
    FILE *fpIdentity = fopen(identityPath.UTF8String, "wb");
    if ( fpIdentity == NULL ) {
        ERR_print_errors_fp(stderr);
        char *err = ERR_error_string(ERR_get_error(), NULL);
        *error = [NSError errorWithDomain:CRSSLErrorDomain code:CRSSLIdentityCreateError userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithUTF8String:err] ? : @"(null)"}];
        X509_free(cert);
        EVP_PKEY_free(key);
        return nil;
    }
    
    i2d_PKCS12_fp(fpIdentity, p12);
    
    fclose(fpIdentity);
    PKCS12_free(p12);
    
    return identityPath;
}
#endif

@end
