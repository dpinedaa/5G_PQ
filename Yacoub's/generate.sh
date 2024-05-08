#!/bin/bash


# Read certificate chain contents
#openssl x509 -in certchain.pem -text

# Generate new self-signed certificate
#openssl req -new -x509 -days 365 -nodes -out certchain.pem -keyout private.pem


# Generate new self-signed certificate
#openssl req -x509 -new -newkey falcon512 -days 365 -nodes -out certchainfalcon512.pem -keyout privatefalcon512.pem

# Generate new self-signed certificate
openssl req -x509 -new -newkey dilithium5 -days 365 -nodes \
    -out certchaindilithium5.pem -keyout privatedilithium5.pem \
    -subj "/C=UZ/ST=Tashkent/L=Tashkent/O=strangebit/OU=IT/CN=strangebit.com/emailAddress=dmitriy.kuptsov@gmail.com"
    
    
    
    
#---------------------------------------------------------------------------------
# Added by Yacoub May 8th
# RSA
# Root

#openssl req -x509 -config ../../openssl.cnf -newkey rsa:4096 -subj "/C=UZ/ST=Tashkent/L=Tashkent/O=strangebit/OU=IT/CN=Root_CA/emailAddress=dmitriy.kuptsov@gmail.com" -out root/cacert.pem -keyout root/cakey.pem -extensions v3_rca -days 730 -batch

# Server

#openssl req -new -config ../../openssl.cnf -newkey rsa:4096 -subj "/C=UZ/ST=Tashkent/L=Tashkent/O=strangebit/OU=IT/CN=strangebit.com/emailAddress=dmitriy.kuptsov@gmail.com" -out svrcert.csr -keyout svrkey.pem -batch

#openssl ca -config ../../openssl.cnf -name RootCA -cert root/cacert.pem -keyfile root/cakey.pem -extensions v3_server -out svrcert.pem -batch -days 365 -infiles svrcert.csr


#---------------------------------------------------------------------------------
# ECDSA
# Root

# openssl ecparam -name prime256v1 -genkey -out root/cakey.pem
# openssl req -x509 -config ../../openssl.cnf -key root/cakey.pem -out root/cacert.pem -subj "/C=UZ/ST=Tashkent/L=Tashkent/O=strangebit/OU=IT/CN=Root_CA/emailAddress=dmitriy.kuptsov@gmail.com" -extensions v3_rca -days 730 -batch

# Server

# openssl ecparam -name prime256v1 -genkey -out svrkey.pem
# openssl req -new -config ../../openssl.cnf -key svrkey.pem -out svrcert.csr -subj "/C=UZ/ST=Tashkent/L=Tashkent/O=strangebit/OU=IT/CN=strangebit.com/emailAddress=dmitriy.kuptsov@gmail.com" -batch

# openssl ca -config ../../openssl.cnf -name RootCA -cert root/cacert.pem -keyfile root/cakey.pem -extensions v3_server -out svrcert.pem -batch -days 365 -infiles svrcert.csr

#---------------------------------------------------------------------------------
# Falcon512

# Root

# openssl req -x509 -config ../../openssl.cnf -newkey falcon512 -subj "/C=UZ/ST=Tashkent/L=Tashkent/O=strangebit/OU=IT/CN=Root_CA/emailAddress=dmitriy.kuptsov@gmail.com" -out root/cacert.pem -keyout root/cakey.pem -extensions v3_rca -days 730 -batch

# Server

# openssl req -new -config ../../openssl.cnf -newkey falcon512 -subj "/C=UZ/ST=Tashkent/L=Tashkent/O=strangebit/OU=IT/CN=strangebit.com/emailAddress=dmitriy.kuptsov@gmail.com" -out svrcert.csr -keyout svrkey.pem -batch

# openssl ca -config ../../openssl.cnf -name RootCA -cert root/cacert.pem -keyfile root/cakey.pem -extensions v3_server -out svrcert.pem -batch -days 365 -infiles svrcert.csr

#---------------------------------------------------------------------------------
# dilithium2

# Root

# openssl req -x509 -config ../../openssl.cnf -newkey dilithium2 -subj "/C=UZ/ST=Tashkent/L=Tashkent/O=strangebit/OU=IT/CN=Root_CA/emailAddress=dmitriy.kuptsov@gmail.com" -out root/cacert.pem -keyout root/cakey.pem -extensions v3_rca -days 730 -batch

# Server

# openssl req -new -config ../../openssl.cnf -newkey dilithium2 -subj "/C=UZ/ST=Tashkent/L=Tashkent/O=strangebit/OU=IT/CN=strangebit.com/emailAddress=dmitriy.kuptsov@gmail.com" -out svrcert.csr -keyout svrkey.pem -batch

# openssl ca -config ../../openssl.cnf -name RootCA -cert root/cacert.pem -keyfile root/cakey.pem -extensions v3_server -out svrcert.pem -batch -days 365 -infiles svrcert.csr

#---------------------------------------------------------------------------------
# sphincssha2128fsimple

# Root

# openssl req -x509 -config ../../openssl.cnf -newkey sphincssha2128fsimple -subj "/C=UZ/ST=Tashkent/L=Tashkent/O=strangebit/OU=IT/CN=Root_CA/emailAddress=dmitriy.kuptsov@gmail.com" -out root/cacert.pem -keyout root/cakey.pem -extensions v3_rca -days 730 -batch

# Server

# openssl req -new -config ../../openssl.cnf -newkey sphincssha2128fsimple -subj "/C=UZ/ST=Tashkent/L=Tashkent/O=strangebit/OU=IT/CN=strangebit.com/emailAddress=dmitriy.kuptsov@gmail.com" -out svrcert.csr -keyout svrkey.pem -batch

# openssl ca -config ../../openssl.cnf -name RootCA -cert root/cacert.pem -keyfile root/cakey.pem -extensions v3_server -out svrcert.pem -batch -days 365 -infiles svrcert.csr



