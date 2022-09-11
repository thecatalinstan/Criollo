//
//  CRHTTPSHelper.m
//  Criollo
//
//  Created by Cătălin Stan on 10/09/2017.
//  Copyright © 2017 Cătălin Stan. All rights reserved.
//

#import "CRHTTPSHelper.h"

NSString * const CRHTTPSErrorDomain                      = @"CRHTTPSErrorDomain";

NSUInteger const CRHTTPSInternalError                    = 1000;
NSUInteger const CRHTTPSInvalidIdentityError             = 1003;
NSUInteger const CRHTTPSInvalidPasswordError             = 1004;
NSUInteger const CRHTTPSMissingCredentialsError          = 1005;

NSString * const CRHTTPSIdentityPathKey                  = @"CRHTTPSIdentityPath";

#if SEC_OS_OSX_INCLUDES

NSUInteger const CRHTTPSInvalidCertificateError          = 1001;
NSUInteger const CRHTTPSInvalidPrivateKeyError           = 1002;
NSUInteger const CRHTTPSCreateIdentityError              = 1006;

NSString * const CRHTTPSCertificatePathKey               = @"CRHTTPSCertificatePath";
NSString * const CRHTTPSCertificateKeyPathKey            = @"CRHTTPSCertificateKeyPath";

OSStatus keychainCallback(SecKeychainEvent keychainEvent, SecKeychainCallbackInfo *info, void * __nullable context);

#endif

NS_ASSUME_NONNULL_BEGIN

@interface CRHTTPSHelper () {
#if SEC_OS_OSX_INCLUDES
    NSString *_keychainPassword;
    NSString *_keychainPath;
#endif
}

#if SEC_OS_OSX_INCLUDES

@property (nonatomic, nullable) SecKeychainRef keychain;

@property (nonatomic, strong, readonly) NSString *keychainPassword;
@property (nonatomic, strong, readonly) NSString *keychainPath;

- (SecKeychainRef _Nullable)setupKeychain;

#endif

@end

NS_ASSUME_NONNULL_END

@implementation CRHTTPSHelper

- (NSArray *)parseIdentrityFile:(NSString *)identityFilePath password:(nonnull NSString *)password error:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    NSError * identityReadError;
    NSData * identityContents = [NSData dataWithContentsOfFile:identityFilePath options:NSDataReadingUncached error:&identityReadError];
    if (identityContents.length == 0) {
        if (error != NULL) {
            NSMutableDictionary<NSErrorUserInfoKey, id> *info = [NSMutableDictionary dictionaryWithCapacity:3];
            info[NSLocalizedDescriptionKey] = NSLocalizedString(@"Unable to parse PKCS12 identity file.",);
            info[NSUnderlyingErrorKey] = identityReadError;
            info[CRHTTPSIdentityPathKey] = identityFilePath;
            *error = [[NSError alloc] initWithDomain:CRHTTPSErrorDomain code:CRHTTPSInvalidIdentityError userInfo:info];
        }
        return nil;
    }
    
    CFArrayRef identityImportItems = NULL;
    NSMutableDictionary *identityImportOptions = [NSMutableDictionary dictionary];
    identityImportOptions[(id)kSecImportExportPassphrase] = password ? : @"";
    
#if SEC_OS_OSX_INCLUDES
    identityImportOptions[(id)kSecImportExportKeychain] = (__bridge id)self.keychain;
#endif
    
    OSStatus identityImportStatus = SecPKCS12Import((__bridge CFDataRef)identityContents, (__bridge CFDictionaryRef)identityImportOptions, &identityImportItems);
    if ( identityImportStatus != errSecSuccess ) {
        if ( error != nil ) {
            NSUInteger errorCode = (identityImportStatus == errSecAuthFailed || identityImportStatus == errSecPkcs12VerifyFailure) ? CRHTTPSInvalidPasswordError : CRHTTPSInvalidIdentityError;
            NSString *errorMessage;
#if SEC_OS_OSX_INCLUDES
            errorMessage = (NSString *)CFBridgingRelease(SecCopyErrorMessageString(identityImportStatus, NULL));
#else
            if ( errorCode == CRHTTPSInvalidPasswordError ) {
                errorMessage = NSLocalizedString(@"Invalid password when importing PKCS12 identity file.",);
            } else {
                errorMessage = NSLocalizedString(@"Unable to parse PKCS12 identity file.",);
            }
#endif            
            *error = [[NSError alloc] initWithDomain:CRHTTPSErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey: errorMessage, CRHTTPSIdentityPathKey: identityFilePath ? : @"(null)"}];
        }
        
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

#if SEC_OS_OSX_INCLUDES

- (NSArray *)parseCertificateFile:(NSString *)certificatePath privateKeyFile:(NSString *)privateKeyPath error:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    NSError * certReadError;
    NSData * certContents = [NSData dataWithContentsOfFile:certificatePath options:NSDataReadingUncached error:&certReadError];
    if ( certContents.length == 0 ) {
        if ( error != nil ) {
            *error = [[NSError alloc] initWithDomain:CRHTTPSErrorDomain code:CRHTTPSInvalidCertificateError userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to parse certificate file.",), NSUnderlyingErrorKey: certReadError, CRHTTPSCertificatePathKey: certificatePath ? : @"(null)", CRHTTPSCertificateKeyPathKey:privateKeyPath ? : @"(null)"}];
        }
        return nil;
    }
    
    NSError * keyReadError;
    NSData * keyContents = [NSData dataWithContentsOfFile:privateKeyPath options:NSDataReadingUncached error:&keyReadError];
    if ( keyContents.length == 0 ) {
        if ( error != nil )  {
            *error = [[NSError alloc] initWithDomain:CRHTTPSErrorDomain code:CRHTTPSInvalidPrivateKeyError userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to parse private key file.",), NSUnderlyingErrorKey: keyReadError, CRHTTPSCertificatePathKey:certificatePath ? : @"(null)", CRHTTPSCertificateKeyPathKey:privateKeyPath ? : @"(null)"}];
        }
        return nil;
    }
    
    CFArrayRef certificateImportItems = NULL;
    OSStatus certificateImportStatus = SecItemImport((__bridge CFDataRef)certContents , NULL, NULL, NULL, 0, NULL, NULL, &certificateImportItems);
    if ( certificateImportStatus != errSecSuccess ) {
        if ( error != nil ) {
            NSString *secErrorString = (NSString *)CFBridgingRelease(SecCopyErrorMessageString(certificateImportStatus, NULL));
            *error = [[NSError alloc] initWithDomain:CRHTTPSErrorDomain code:CRHTTPSInvalidCertificateError userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat: NSLocalizedString(@"Unable to parse certificate bundle. %@",), secErrorString], CRHTTPSCertificatePathKey:certificatePath ? : @"(null)", CRHTTPSCertificateKeyPathKey:privateKeyPath ? : @"(null)"}];
        }
        return nil;
    }
    
    // Check if the first item in the import is a certificate
    SecCertificateRef certificate = (SecCertificateRef) CFArrayGetValueAtIndex(certificateImportItems, 0);
    if ( CFGetTypeID(certificate) != SecCertificateGetTypeID() ) {
        if ( error != nil ) {
            *error = [[NSError alloc] initWithDomain:CRHTTPSErrorDomain code:CRHTTPSInvalidCertificateError userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat: NSLocalizedString(@"Expected a certificate, but got %@ instead.",), (__bridge id)certificate], CRHTTPSCertificatePathKey:certificatePath ? : @"(null)", CRHTTPSCertificateKeyPathKey:privateKeyPath ? : @"(null)"}];
        }
        return nil;
    }
    
    // Import the key into the keychain
    CFArrayRef keyImportItems = NULL;
    OSStatus keyImportStatus = SecItemImport((__bridge CFDataRef)keyContents , NULL, NULL, NULL, 0, NULL, self.keychain, &keyImportItems);
    if ( keyImportStatus != errSecSuccess ) {
        if ( error != nil ) {
            NSString *secErrorMessage = (NSString *)CFBridgingRelease(SecCopyErrorMessageString(keyImportStatus, NULL));
            *error = [[NSError alloc] initWithDomain:CRHTTPSErrorDomain code:CRHTTPSInvalidPrivateKeyError userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat: NSLocalizedString(@"Unable to parse private key file. %@",), secErrorMessage], CRHTTPSCertificatePathKey: certificatePath ? : @"(null)", CRHTTPSCertificateKeyPathKey: privateKeyPath ? : @"(null)"}];
        }
        return nil;
    }
    
    // Check if the first item in the import is a privatekey
    SecKeyRef key = (SecKeyRef) CFArrayGetValueAtIndex(keyImportItems, 0);
    if ( CFGetTypeID(key) != SecKeyGetTypeID() ) {
        if ( error != nil ) {
            *error = [[NSError alloc] initWithDomain:CRHTTPSErrorDomain code:CRHTTPSInvalidPrivateKeyError userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat: NSLocalizedString(@"Expected a private key, but got %@ instead.",), (__bridge id)key], CRHTTPSCertificatePathKey: certificatePath ? : @"(null)", CRHTTPSCertificateKeyPathKey: privateKeyPath ? : @"(null)"}];
        }
        return nil;
    }
    
    // Create an identity from the keychain and the certificate
    SecIdentityRef identity;
    OSStatus identityCreationStatus = SecIdentityCreateWithCertificate(self.keychain, certificate, &identity);
    if ( identityCreationStatus != errSecSuccess ) {
        if ( error != nil ) {
            NSString *secErrorMessage = (NSString *)CFBridgingRelease(SecCopyErrorMessageString(identityCreationStatus, NULL));
            *error = [[NSError alloc] initWithDomain:CRHTTPSErrorDomain code:CRHTTPSCreateIdentityError userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat: NSLocalizedString(@"Unable to get a suitable identity. %@",), secErrorMessage], CRHTTPSCertificatePathKey: certificatePath ? : @"(null)", CRHTTPSCertificateKeyPathKey: privateKeyPath ? : @"(null)"}];
        }
        return nil;
    }
    
    // Create the outut array
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:CFArrayGetCount(certificateImportItems)];
    [result addObjectsFromArray:(__bridge NSArray * _Nonnull)(certificateImportItems)];
    result[0] = (__bridge id _Nonnull)(identity);
    
    return result;
}

- (instancetype)init {
    self = [super init];
    if ( self != nil ) {
        _keychain = [self setupKeychain];
    }
    return self;
}

- (void)dealloc {
    if ( _keychain !=  NULL ) {
        SecKeychainDelete(_keychain);
        CFRelease(_keychain);
        _keychain = NULL;
        
        SecKeychainRemoveCallback((SecKeychainCallback)keychainCallback);
    }
}

- (NSString *)keychainPath {
    if ( _keychainPath.length == 0 ) {
        _keychainPath = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
    }
    return _keychainPath;
}

- (NSString *)keychainPassword {
    if ( _keychainPassword.length == 0 ) {
        _keychainPassword = NSUUID.UUID.UUIDString;
    }
    return _keychainPassword;
}

- (SecKeychainRef)setupKeychain {

    NSString *keychainPath = self.keychainPath;
    NSString *keychainPassword = self.keychainPassword;

    SecAccessRef access = NULL;
    OSStatus accessCreationStatus = SecAccessCreate((CFStringRef)keychainPath.lastPathComponent, NULL, &access);
    if ( accessCreationStatus != errSecSuccess ) {
        return NULL;
    }
  
    SecKeychainRef keychain = NULL;
    OSStatus keychainCreationStatus = SecKeychainCreate(keychainPath.UTF8String, (UInt32)keychainPassword.length, keychainPassword.UTF8String, NO, access, &keychain);
    if ( keychainCreationStatus != errSecSuccess ) {
        return NULL;
    }
    
    OSStatus callbackStatus = SecKeychainAddCallback((SecKeychainCallback)keychainCallback, kSecEveryEventMask, (__bridge void *)self);
    if ( callbackStatus != errSecSuccess ) {
        return NULL;
    }
    
    return keychain;
}

#endif

@end

#if SEC_OS_OSX_INCLUDES

OSStatus keychainCallback(SecKeychainEvent keychainEvent, SecKeychainCallbackInfo *info, void * __nullable context) {
    CRHTTPSHelper *httpsHelper = (__bridge CRHTTPSHelper *)context;
    if (info->keychain != httpsHelper.keychain) {
        return errSecInvalidKeychain;
    }
    
    OSStatus status = errSecSuccess;
    if (keychainEvent == kSecLockEvent) {
        NSString *password = httpsHelper.keychainPassword;
        status = SecKeychainUnlock(info->keychain, (UInt32)password.length, password.UTF8String, TRUE);
    }
    
    return status;
}

#endif
