# PKI playground

This is a PKI playground to get more familiar with the subject and try some scenarios.


## Self

Self-signed cert which can be used for https.


## Tree

The tree folder is a PKI tree example.
The PKI tree looks like this:

```
            root-ca
               |
    ------------------------
    |                      |
  client-ca              tls-ca
    |                      |
client-cert           server-cert
```

Tree can be build with the build.sh script.


## Configure Apache 

### install
```
sudo apt-get install apache2
sudo a2enmod ssl
```
### configuration /etc/apache2/sites-enabled/default-ssl.conf
```
SSLEngine on
SSLCertificateFile	    $PWD/certs/server-chain.pem
SSLCertificateKeyFile   $PWD/certs/server.key
SSLCACertificatePath    $PWD/ca
SSLCACertificateFile    $PWD/ca/client-ca-chain.pem
SSLCARevocationCheck    chain
SSLCARevocationPath     $PWD/crl
SSLCARevocationFile     $PWD/crl/client-ca.crl
SSLVerifyClient require
SSLVerifyDepth  3
```
