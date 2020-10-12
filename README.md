# Set-up an Certificate Authority

This repository is based on a nice tutorial from [jamielinux.com][1]. Root CA is used directly, avoiding to use an Intermediate CA. For most smaller projects this is not necessary anyways.

Prepare the directory:

    mkdir newcerts
    touch index.txt
    echo 1000 > serial


## Root CA

Create the root key

    openssl genrsa -aes256 -out root_ca.key 4096
    chmod 400 root_ca.key

Create the root certificate

    openssl req -config openssl.cnf -key root_ca.key -new -x509 -days 7300 -sha256 -extensions v3_ca -out root_ca.crt
    chmod 444 root_ca.crt

When prompted, privide information like:

    Country Name (2 letter code) [DE]:
    State or Province Name []:
    Locality Name []:
    Organization Name [Simon Christmann]:
    Organizational Unit Name []:Certificate Authority
    Common Name []:Simon Christmann Root CA
    Email Address [simon@christmann.email]:

Verify the certificate:

    openssl x509 -noout -text -in root_ca.crt

### Add the Root CA to your system

#### Mac OS X

    sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain root_ca.crt

#### Android

    hash=$(openssl x509 -inform PEM -subject_hash_old -in root_ca.crt | head -1) && cat root_ca.crt > ${hash}.0 && openssl x509 -inform PEM -text -in root_ca.crt -out /dev/null >> ${hash}.0

Copy this file (e.g. `5ed36f99.0`) to `/system/etc/security/cacerts/` on the Android device. You can use Cyanogenmod's file browser with root access for this. Set the permissions to `chmod 644` and reboot.


## Server certificate

Create key

    openssl genrsa -out example.com.key 2048
    chmod 400 example.com.key

Create Certificate Signing Request (CSR)

    openssl req -config openssl.cnf -key example.com.key -new -sha256 -out example.com.csr

CSR for multiple domains. You have to provide the common name also here in this list:

    openssl req -config openssl.cnf -key example.com.key -new -sha256 -out example.com.csr -reqexts SAN -config <(cat openssl.cnf <(printf "\n[SAN]\nsubjectAltName=DNS:example.com,DNS:www.example.com,DNS:example.org,DNS:www.example.org"))

When prompted, privide information like:

    Country Name (2 letter code) [DE]:
    State or Province Name []:
    Locality Name []:
    Organization Name [Simon Christmann]:
    Organizational Unit Name []:
    Common Name []:example.com
    Email Address [simon@christmann.email]:

Verfify the CSR:

    openssl req -text -noout -verify -in example.com.csr

Sign the certificate (server_cert vs. usr_cert)

    openssl ca -config openssl.cnf -extensions server_cert -days 825 -notext -md sha256 -in example.com.csr -out example.com.crt
    chmod 444 example.com.crt

Verify

    openssl x509 -noout -text -in example.com.crt

### Renew a certificate

Revoke the old one

    openssl ca -config openssl.cnf -revoke home.simon-christmann.de.crt

then create a new CSR and sign it.

### nginx

Chain for nginx:

    cat example.com.crt root_ca.crt > example.com.chain.crt

## Client certificate

    openssl genrsa -aes256 -out simon@christmann.email.key 2048
    openssl req -config openssl.cnf -new -key simon@christmann.email.key -out simon@christmann.email.csr

Sign

    openssl ca -config openssl.cnf -extensions usr_cert -notext -md sha256 -in simon@christmann.email.csr -out simon@christmann.email.crt

Verify

    openssl verify -CAfile root_ca.crt simon@christmann.email.crt

Export client certificate in format for macOS Keychain

    openssl pkcs12 -export -out simon@christmann.email.p12 -inkey simon@christmann.email.key -in simon@christmann.email.crt


## Cheat-sheet

### Remove passphrase from key

    openssl rsa -in my.key -out my_nopw.key

While generating instead of for e.g.

    openssl genrsa -des3 -out key 2048

use

    openssl genrsa       -out key 2048


[1]: https://jamielinux.com/docs/openssl-certificate-authority/introduction.html "OpenSSL Certificate Authority"
[2]: https://mnxsolutions.com/apache/removing-a-passphrase-from-an-ssl-key.html "Removing a passphrase from an SSL Key"
[3]: http://kb.kerio.com/product/kerio-connect/server-configuration/ssl-certificates/adding-trusted-root-certificates-to-the-server-1605.html "Adding trusted root certificates to the server"
[4]: http://nat.guyton.net/2012/01/20/adding-trusted-root-certificate-authorities-to-ios-ipad-iphone/ "Adding Trusted Root Certificate Authorities to iOS (iPad, iPhone)"
[5]: https://support.ssl.com/Knowledgebase/Article/View/19/0/der-vs-crt-vs-cer-vs-pem-certificates-and-how-to-convert-them "DER vs. CRT vs. CER vs. PEM Certificates and How To Convert Them"
[6]: https://blog.zencoffee.org/2013/04/creating-and-signing-an-ssl-cert-with-alternative-names/ "Creating and signing an SSL cert with alternative names"
[7]: http://apple.stackexchange.com/questions/8993/how-can-i-add-a-private-key-to-my-keychain "How can I add a private key to my keychain?"
[8]: http://wiki.pcprobleemloos.nl/android/cacert "Installing CAcert certificates on Android as 'system' credentials without lockscreen - instructions"
[9]: https://de.wikipedia.org/wiki/X.509#Dateinamenserweiterungen_für_Zertifikate "Dateinamenserweiterungen für Zertifikate"
[10]: https://deliciousbrains.com/ssl-certificate-authority-for-local-https-development/ "How to Create Your Own SSL Certificate Authority for Local HTTPS Development"
[11]: https://shellhacks.com/create-csr-openssl-without-prompt-non-interactive/ "HowTo: Create CSR using OpenSSL Without Prompt (Non-Interactive)"