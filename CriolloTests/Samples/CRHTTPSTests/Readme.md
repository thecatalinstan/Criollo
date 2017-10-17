# `CRHTTPSTests` Sample Files

Here's a description of the files used in the `CRHTTPS` test suite:

| File | Description |
|:--|:--|
| **CRHTTPSTests.pem** | PEM-encoded X509 certificate |
| **CRHTTPSTests.der** | DER-encoded X509 certificate |
| **CRHTTPSTests.key.pem** | PEM-encoded RSA private key |
| **CRHTTPSTests.key.der** | DER-encoded RSA private key |
| **CRHTTPSTests.bundle.pem** | PEM-encoded chained X509 certificate and CA bundle |
| **CRHTTPSTests.bundle.der** | PEM-encoded chained X509 certificate and CA bundle |
| **CRHTTPSTests.p12*** | PKCS#12 identity including certificate, chained CA bundle and private key |
| **CRHTTPSTests.junk** | 4096 bytes of junk |

All certificates, including the CA root and its intermediate certificate are self-signed.

* the password for the identity import is `password`