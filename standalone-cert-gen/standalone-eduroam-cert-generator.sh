#!/bin/bash

# eduroam-cert-generator.sh: CA Generator

# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "ASIS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
#
# ChangeLog:
# ---------------------------------------------------------------------------- #
# v1.0.0 (2022-04) Standalone version (standalone-cert-generator.sh)
# ---------------------------------------------------------------------------- #

############################################################################################################
# Global variables
#
# Current date
date=$(date +'%Y_%m_%d_%H_%M')
# Folder to store the generated certs
folder="certs"
# Executable file path
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
# files
files=("ca.cnf" "client.cnf" "inner-server.cnf" "ocsp.cnf" "passwords.mk" "server.cnf" "xpextensions")
# Backup files folder
tmpl_folder="/templates"
# Selected string char set
string_mask=""
# CN value
commonname=""
# Domain value
domain=""
# Organization name value
organizationname=""
# Email value
email=""
# Country name value
countryname=""
# Province or region value
state=""
# Locality value
locality=""
# CRL (Certificate Revocation List) url value
crl=""
# OCSP (Online Certificate Status Protocol) url value
ocsp=""
# Password value
password=""

# Functions block
############################################################################################################
# checkDefaults function: the function check if the backup files exists, if not, files are created         #
############################################################################################################
function checkDefaults()
{

  mkdir -p "$parent_path/$folder"

  if [ ! -e "$parent_path/$folder/index.txt.attr" ]; then
    touch "$parent_path/$folder/index.txt.attr"
  fi

}

############################################################################################################
# Funcion copyFromTemplate: allows to copy the template files                                              #
############################################################################################################
function copyFromTemplate()
{
  
  cd "$parent_path"

  for i in "${files[@]}"
  do
    if [ $i != "ca.cnf" ]; then
      cp "$parent_path$tmpl_folder/$i.tmpl" "$parent_path/$folder/$i"
    fi
  done

}

############################################################################################################
# fillData function, sets user data to config files                                                        #
############################################################################################################
function fillData()
{

  for i in "${files[@]}"
  do
    if [ $i != "ca.cnf" ]; then
      cnf_file_path="$parent_path/$folder/$i"
      
      # DEFAULT_CHARSET
      sed -i "s|DEFAULT_CHARSET|$string_mask|" "$cnf_file_path"
      # DEFAULT_COUNTRY_NAME
      sed -i "s|DEFAULT_COUNTRY_NAME|$countryname|" "$cnf_file_path"
      # DEFAULT_STATE
      sed -i "s|DEFAULT_STATE|$state|" "$cnf_file_path"
      # DEFAULT_LOCALITY
      sed -i "s|DEFAULT_LOCALITY|$locality|" "$cnf_file_path"
      # DEFAULT_ORGANIZATION_NAME
      sed -i "s|DEFAULT_ORGANIZATION_NAME|$organizationname|" "$cnf_file_path"
      # DEFAULT_CRL
      sed -i "s|DEFAULT_CRL|$crl|" "$cnf_file_path"
      # DEFAULT OCSP
      sed -i "s|DEFAULT_OCSP|$ocsp|" "$cnf_file_path"
      # DEFAULT PASSWORD
      sed -i "s|DEFAULT_PASSWORD|$password|" "$cnf_file_path"
      # DEFAULT COMMON NAME
      sed -i "s|DEFAULT_COMMON_NAME|$commonname|" "$cnf_file_path"
      # DEFAULT EMAIL
      sed -i "s|DEFAULT_EMAIL|$email|" "$cnf_file_path"
      # DEFAULT COMMON SERVER NAME
      sed -i "s|DEFAULT_SERVER_COMMON_NAME|$commonname|" "$cnf_file_path"

    fi
  done

}

############################################################################################################
# makeAll function, allows to create all CA files                                                          #
############################################################################################################
function makeAll()
{

  errors=0;

  cd "$parent_path";
  cp "Makefile" "$parent_path/$folder";
  cd "$parent_path/$folder";
  make all > "$date.log";

  errors=$(cat "$date.log" | grep 'error' | wc -l);

  if [ $errors != 0 ]; then
    exit 1;
  else
    exit 0;
  fi

}

if  [ "$1" ] && [ "$2" ] && [ "$3" ] && [ "$4" ] && [ "$5" ] && [ "$6" ] && [ "$7" ] && [ "$8" ] && [ "$9" ] && [ "${10}" ] && [ "${11}" ]; then
  
  string_mask="$1";
  countryname="$2";
  state="$3";
  locality="$4";
  organizationname="$5";
  crl="$6";
  ocsp="$7";
  password="$8";
  commonname="$9";
  email="${10}";
  servercommonname="${11}";

  checkDefaults
  copyFromTemplate
  fillData
  makeAll

fi


exit 0;