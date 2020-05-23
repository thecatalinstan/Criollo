# SecureHTTPServer

This example illustrates how to setup an HTTPS server in an iOS app. The same method of setting up a secure web server is also valid for an Apple TV app or Mac app, be it Cocoa or `launchd`, Swift or Objective-C.

Criollo supports passing in credentials as a PKCS#12 identity and password, or an X509 certificate and private key pair, either PEM or DER encoded. The example shows both PKCS#12 identity and X509 certificate and key pair. 

## Providing the HTTPS Credentials

Criollo makes it as painlessly as possible:

```swift
// Secure with PEM certificate and key
server.certificatePath = Bundle.main.path(forResource: "SecureHTTPServer.bundle", ofType: "pem")
server.privateKeyPath = Bundle.main.path(forResource: "SecureHTTPServer.key", ofType: "pem")
```

or 

```swift
// Secure with PKCS#12 identity and password.
server.identityPath = Bundle.main.path(forResource: "SecureHTTPServer", ofType: "p12")
server.password = "password"
```

## Bundled Credential Files

The files below can be found in the `./Certificates` folder. 

| File | Description |
|:--|:--|
| **SecureHTTPServer.bundle.pem** | PEM-encoded chained X509 certificate and CA bundle |
| **SecureHTTPServer.key.pem** | PEM-encoded RSA private key |
| **SecureHTTPServer.p12*** | PKCS#12 identity including certificate, chained CA bundle and private key |

All certificates, including the CA root and its intermediate certificate are self-signed.

* the password for the identity import is `password`
