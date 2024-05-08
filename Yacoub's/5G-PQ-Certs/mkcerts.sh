#!/bin/bash

# Script to:
# 1. Create various Root CA, Intermediate CA, OCSP signing, Web Server, & Web Client certificates
#	included signature algorithms: RSA, ECDSA, EdDSA, Falcon512 & 1024, Dilithium 2, 3 & 5, SPHINCS+-SHAKE256, SPHINCS+-SHA-256, SPHINCS+-Haraka

# Requires OQS OpenSSL installed

BASE_DIR=$(pwd)

###############################################################################
################################## IMPORTANT ##################################
###############################################################################
# The variables in this section MUST be set for proper execution of this script.

# You may also need to edit the openssl.cnf file included in this repo to set
# the OCSP URL. Look for the lines that say:

# ---------------EDIT BELOW WITH YOUR DESIRED OCSP SERVER URL
# authorityInfoAccess    = OCSP;URI:http://ocsp:8080	

# under the relevant x509 extension headers section. 

#ABSOLUTE path to the OQS OpenSSL executable:
#qopenssl= $BASE_DIR/openssl/apps/openssl

#ABSOLUTE path to openssl config file (openssl.cnf):
conffile=$BASE_DIR/openssl.cnf
#You will have to change a lot in this script f you don't use the config file included with this repo

#Algorithms to generate certs with:
ALGS=("rsa" "ecdsa" "falcon512" "dilithium2" "sphincssha256128ssimple")
# rsa, ecdsa, & eddsa are specially coded - for PQ algorithms, make sure the name matches exactly with what is listed by liboqs, and it should work if OpenSSL has been compiled with support for those algorithms

#--------------------------- CERTIFICATE SUBJECT DN ---------------------------
declare -A subject
declare -A CN
declare -A pass
# ------------ Customize below at will ------------
# ------ Individual Params ------
#Country Name  (2 letter code):
C="UZ"
#State or Province Name (full name):
ST="Tashkent"
#Locality Name (eg. City):
L="Tashkent"
#Organization Name (company):
O="strangebit"
#Organizational Unit Name (eg. section):
OU="IT"
#e-mail address:
emailAddress="dmitriy.kuptsov@gmail.com"

#Common Names (eg. Server FQDN):
CN[root]="Root_CA"
CN[svr]="strangebit.com"

# -------- Complete DN ----------
subject[root]="/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=${CN[root]}/emailAddress=$emailAddress"
subject[svr]="/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=${CN[svr]}/emailAddress=$emailAddress"

#Private Key Passphrases:
#By default, the root key passphrase is used for all
#pass[root]="abc123"
#pass[svr]=${pass[root]}
#------------------------------------------------------------------------------
###############################################################################


# -----------------------------------------------------------------------------
# logging helpers
# -----------------------------------------------------------------------------

function _log {
	level=$1
	msg=$2

	case "$level" in
		info)
			tag="\e[1;36minfo\e[0m"
			;;
		err)
			tag="\e[1;31merr \e[0m"
			;;
		warn)
			tag="\e[1;33mwarn\e[0m"
			;;
		ok)
			tag="\e[1;32m ok \e[0m"
			;;
		fail)
			tag="\e[1;31mfail\e[0m"
			;;
		*)
			tag="	"
			;;
	esac
	echo -e "`date +%Y-%m-%dT%H:%M:%S` [$tag] $msg"
}

function _err {
	msg=$1
	_log "err" "$msg"
}

function _warn {
	msg=$1
	_log "warn" "$msg"
}

function _info {
	msg=$1
	_log "info" "$msg"
}

function _success {
	msg=$1
	_log "ok" "$msg"
}

function _fail {
	msg=$1
	_log "fail" "$msg"
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

haserr=0
for ALG in ${ALGS[@]}; do
	_info "================== $ALG =================="
	#Directory buildout
	mkdir -p $BASE_DIR/certs/$ALG && cd $BASE_DIR/certs/$ALG	
	mkdir -p root/newcerts
	touch root/index.txt
	echo 01 > root/serial

	#ROOT CA
	_info "Generating Root CA cert..."
	if [ $ALG == "rsa" ]; then
		openssl req -x509 -config $conffile -newkey rsa:4096 -subj "${subject[root]}" -out root/cacert.pem -keyout root/cakey.pem -extensions v3_rca -days 730 -batch;
	elif [ $ALG == "ecdsa" ]; then
		openssl ecparam -name prime256v1 -genkey -out root/cakey.pem;				#Generate EC private key
		openssl req -x509 -config $conffile -key root/cakey.pem -out root/cacert.pem -subj "${subject[root]}" -extensions v3_rca -days 730 -batch;
	else
		openssl req -x509 -config $conffile -newkey $ALG -subj "${subject[root]}" -out root/cacert.pem -keyout root/cakey.pem -extensions v3_rca -days 730 -batch;
	fi
	#openssl x509 -purpose -in root/cacert.pem ;
	#if [ $? -eq 0 ]; then
	#	_success "Root CA cert/key generated"
	#else
	#	haserr=1
	#	_err "Error"
	#fi


	#HTTPS SVR
	_info "Generating HTTPS Server cert..."
	if [ $ALG == "rsa" ]; then
		openssl req -new -config $conffile -newkey rsa:4096 -subj "${subject[svr]}" -out svrcert.csr -keyout svrkey.pem -batch;
	elif [ $ALG == "ecdsa" ]; then
		openssl ecparam -name prime256v1 -genkey -out svrkey.pem;				#Generate EC private key
		openssl req -new -config $conffile -key svrkey.pem -out svrcert.csr -subj "${subject[svr]}" -batch;
	else
		openssl req -new -config $conffile -newkey $ALG -subj "${subject[svr]}" -out svrcert.csr -keyout svrkey.pem -batch;
	fi
	#openssl req -text -noout -verify -in svrcert.csr -config $conffile;
	openssl ca -config $conffile -name RootCA -cert root/cacert.pem -keyfile root/cakey.pem -extensions v3_server -out svrcert.pem -batch -days 365 -infiles svrcert.csr;
	#openssl x509 -purpose -in svrcert.pem ;
	openssl verify -verbose -CAfile root/cacert.pem -untrusted svrcert.pem;
	#if [ $? -eq 0 ]; then
	#	_success "Server cert/key generated"
	#else
	#	haserr=1
	#	_err "Error"
	#fi

done

if [ $haserr -eq 0 ]; then
	_success "All certificates generated successfully"
else
	_warn "Failed to generate some certificates"
fi

cd $BASE_DIR
exit 0
