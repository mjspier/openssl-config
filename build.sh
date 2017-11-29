#!/bin/bash

# password for pruvate keys
PASS=toor

# helper function
function title {
    echo "############################"
    echo "# $1 "
    echo "############################"
}

# Clean and create folders
sudo rm -rf ./ca/* ./certs/* ./crl/*
mkdir certs crl

echo "clean up folders"
array=( root-ca client-ca tls-ca)
for i in "${array[@]}" ; do
    # create folders and database
    mkdir -p ca/$i/db 
    mkdir -p ca/$i/private
    cp /dev/null ca/$i/db/$i.db
    cp /dev/null ca/$i/db/$i.db.attr
    echo 01 > ca/$i/db/$i.crt.srl
    echo 01 > ca/$i/db/$i.crl.srl
    # create cert
done


title "Build root-ca"
openssl req -new -config etc/root-ca.conf -out ca/root-ca.csr -keyout ca/root-ca/private/root-ca.key -passout pass:$PASS
openssl ca -selfsign -config etc/root-ca.conf -in ca/root-ca.csr -out ca/root-ca.crt -enddate 20301231235959Z -key $PASS -batch

title "Build client-ca"
openssl req -new -config etc/client-ca.conf -out ca/client-ca.csr -keyout ca/client-ca/private/client-ca.key -passout pass:$PASS
openssl ca -config etc/root-ca.conf -in ca/client-ca.csr -out ca/client-ca.crt -key $PASS -batch
openssl ca -gencrl -config etc/client-ca.conf -out crl/client-ca.crl -key $PASS 

title "Build tls-ca"
openssl req -new -config etc/tls-ca.conf -out ca/tls-ca.csr -keyout ca/tls-ca/private/tls-ca.key -passout pass:$PASS
openssl ca -config etc/root-ca.conf -in ca/tls-ca.csr -out ca/tls-ca.crt -key $PASS -batch

title "Build server cert"
SAN=DNS:localhost openssl req -new -config etc/server.conf -out certs/server.csr -keyout certs/server.key -passout pass:$PASS
openssl ca -config etc/tls-ca.conf -in certs/server.csr -out certs/server.crt -key $PASS -batch
cat certs/server.crt ca/tls-ca.crt ca/root-ca.crt > certs/server-chain.pem

title "Build client cert"
CN=Client openssl req -new -config etc/client.conf -out certs/client.csr -keyout certs/client.key -passout pass:$PASS
openssl ca -config etc/client-ca.conf -in certs/client.csr -out certs/client.crt -policy extern_pol  -key $PASS -batch
openssl pkcs12 -export -out certs/client.pfx -inkey certs/client.key -in certs/client.crt -passin pass:$PASS -passout pass:toor

title "Test crl"
openssl verify -crl_check -CAfile <(cat ca/root-ca.crt ca/client-ca.crt crl/client-ca.crl) certs/client.crt

title "Test revoke"
openssl ca -config etc/client-ca.conf -revoke certs/client.crt -crl_reason keyCompromise -key $PASS
openssl ca -gencrl -config etc/client-ca.conf -out crl/client-ca.crl -key $PASS 
openssl verify -crl_check -CAfile <(cat ca/root-ca.crt ca/client-ca.crt crl/client-ca.crl) certs/client.crt
