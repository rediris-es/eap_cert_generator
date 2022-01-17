#!/bin/bash
# eduroam-cert-generator.sh
# License: GNUv2
# @see ../LICENSE file for license info
#
# ---------------------------------------------------------------------------- #
# v0.1.0 (2021-12) First release of eduroam-cert-generator.sh (beta version)
# v0.2.0 (2021-12) Minor changes (beta version)
# v1.0.0 (2022-01) First Release (RC.1)
# ---------------------------------------------------------------------------- #
#
############################################################################################################
# Global variables
#
# Colors for console text print
red='\033[0;91m'
green='\033[0;32m'
blue='\033[1;34m'
yellow='\033[1;33m'
nc='\033[0m'
#
# Errors
#
cn_error=0
cn_server_error=0
# Current date
date=$(date +'%Y_%m_%d_%H_%M')
# Files to modify and must exists
files=("ca.cnf" "client.cnf" "dh" "inner-server.cnf" "ocsp.cnf" "passwords.mk" "server.cnf" "xpextensions")
# Files to store default values
file_defaults=("ca.cnf" "client.cnf" "inner-server.cnf" "ocsp.cnf" "server.cnf")
# Folder to store files with default values 
file_defaults_folder='current_defaults'
# Backup folder
bck_folder="/../templates"
# Backup folder for previous generated CAs
backup_previous_ca="/../previousCAs"
# Executable file path
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
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
#
# User menu options
#
# If no previous CA exists
no_previous_ca=0
# If only wants to re make the server certificate
only_server=0
# Second level domain
rev_string=""
# Second level domain with protocol
rev_string_with_protocol=""
# Protocol for the CRL value
crl_protocol="https"
# protocol for the OCSP value
ocsp_protocol="https"
#
# Functions block
############################################################################################################

############################################################################################################
# print function, allows print messages with a colour based on the variable messageType ($1)               #
############################################################################################################
function print()
{

  messageType=$1
  message=$2

  if [ "$message" != "" ] && [ "$messageType" != "" ]; then
    case $messageType in
      0)
        printf "OK    ${green}$message${nc}\n\n"
      ;;
      1)
        printf "WARN    ${yellow}$message${nc}\n\n"
      ;;
      2)
        printf "NOK    ${red}$message${nc}\n\n"
      ;;
      3)
        printf "INFO    ${blue}$message${nc}\n\n"
      ;;

    esac
  else
    if [ "$message" != "" ]; then
      printf "$mesasge" 
    fi
  fi
}

############################################################################################################
# help function, prints help when user types -h                                                            #
############################################################################################################
function help()
{

  printf "\n                             Información general                   "
  printf "\n"
  printf "\nEste script le solicitará, de forma guiada, los valores necesarios para generar \n"
  printf "los distintos certificados que su organiazación necesite.\n\n\n"
  printf "Si no existe ningún certificado previo, le solicitará la información directamente.\n"
  printf "En caso de que exista un certificado previo, le consultará si desea crear uno nuevo o continuar\n"
  printf "con los datos existentes. Esto también se aplica para el certificado de servidor.\n\n\n"

  exit 0

}

############################################################################################################
# finish function, stops the execution when an interruption is captured                                    #
############################################################################################################
function finish()
{
	printf "\n\n"
	print 2 "Proceso interrumpido.\n"
  print 2 "Puede reiniciarlo lanzando el script de nuevo.\n\n\n"
  exit 1
}

############################################################################################################
# checkDefaults function: the function check if the backup files exists, if not, files are created         #
############################################################################################################
function checkDefaults()
{
  
  if [ ! -d "$parent_path/../$file_defaults_folder" ];
  then
    mkdir "$parent_path/../$file_defaults_folder";
  fi
  for i in "${file_defaults[@]}"
  do
    if [ ! -e "$parent_path/../$file_defaults_folder/$i" ]
    then
      touch "$parent_path/../$file_defaults_folder/$i"
    fi
  done

  if [ ! -e "$parent_path/../index.txt.attr" ]; then
    touch "$parent_path/../index.txt.attr"
  fi

}

############################################################################################################
# checkExistingCA function, checks if exists a previous CA.                                                #
############################################################################################################
function checkExistingCA()
{
    
  # Inner variables
  option=2
  ca_dir="/../rsa"
  ecc_dir="/../ecc"

  # Verificación de existencia de directorios y ficheros para preguntar al usuario qué opción desea tomar
  if [ -d "$parent_path$ca_dir" ] || [ -d "$parent_path$ecc_dir" ]; then
    if [ -f "$parent_path$ca_dir/ca.crt" ] || [ -f "$parent_path$ecc_dir/ca.crt" ]; then
      printf "\nYa EXISTE una CA, ¿quiere mantener esta CA o crear una nueva?\n"
      printf "    ${green}1 :${nc} quiero crear una NUEVA CA, borrará la existente (los usuarios deberán instalar de nuevo la CA mediante eduroam CAT).\n"
      printf "    ${green}2 :${nc} quiero MANTENER la existente [RECOMENDADO].\n"
      printf "    ---------------------------------------------------------"
      printf "    ${red}3 :${nc} : SALIR.\n\n"
      printf "Seleccione una opción [$option]: "
      read option

      while [ "$option" != 1  ] && [ "$option" != 2 ] && [ "$option" != 3 ]; do
        printf "Indica una opción válida (${green}1, 2 ó 3${nc}): "
        read option
      done

      if [ "$option" == 1 ]; then
        printf "\n"
        print 0 "Se generará una nueva CA."
        # Se mueve la CA a una carpeta de backcup y se indica mo no existente previamente
        mkdir -p "$parent_path$backup_previous_ca/$date"
        printf "${green}Backup folder:${nc} $parent_path$backup_previous_ca/$date"
        if [ -d "$parent_path$ca_dir" ]; then
          mv "$parent_path$ca_dir" "$parent_path$backup_previous_ca/$date"
        fi
        if [ -d "$parent_path$ecc_dir" ]; then
          mv "$parent_path$ecc_dir" "$parent_path$backup_previous_ca/$date"
        fi
        if [ -f "$parent_path$file_defaults_folder" ]; then
          mv "$parent_path$file_defaults_folder" "$parent_path$backup_previous_ca/$date"
        fi

        cd "$parent_path/../"
        make clean
        cd "-"
        copyFromTemplate
        
        printf "\n"
        no_previous_ca=1
      fi

      if [ "$option" == 2 ]; then

        print 0 "Se mantiene la CA existente."

        # Verificación de existencia de directorio y fichero de certificado de servidor
        if [ -d  "$parent_path$ca_dir" ] || [ -d "$parent_path$ecc_dir" ]; then
          if [ -f  "$parent_path$ca_dir/server.crt" ] || [ -f "$parent_path$ecc_dir/server.crt" ]; then
            printf "EXISTE un certificado de servidor, ¿quieres mantenerlo o quieres proporcionar nuevos datos?\n"
            printf "    ${green}1 :${nc} proporcionar NUEVOS DATOS.\n"
            printf "    ${green}2 :${nc} generar uno NUEVO con los MISMOS DATOS (facilitando que los usuarios no tengan que realizar cambios).\n"
            printf "    ---------------------------------------------------------\n"
            printf "    ${red}3 :${nc} : SALIR.\n\n"
            printf "Seleccione una opción [$option]: "
            read option
            
            while [ "$option" != 1  ] && [ "$option" != 2 ] && [ "$option" != 3 ]; do
              printf "Indica una opción válida (${green}1, 2 ó 3${nc}): "
              read option
            done
            
            if [ "$option" == 3 ]; then
              print 2 "Abortando."
              exit 0
            fi

            mkdir -p "$parent_path$backup_previous_ca/$date"
            if [ "$option" == 1 ]; then
              mv "$parent_path/../server.cnf" "$parent_path$backup_previous_ca/$date"
              cp "$parent_path/../bck/server.cnf.tmpl" "$parent_path/../server.cnf"
              server_file="$parent_path/../server.cnf"

              # read current_defaults/server.cnf
              content=`grep DEFAULT_PASSWORD $parent_path/../current_defaults/server.cnf | cut -d"=" -f2`
              sed -i "s|DEFAULT_PASSWORD|$content|" "$server_file"
              # DEFAULT_CHARSET
              content=`grep DEFAULT_CHARSET $parent_path/../current_defaults/server.cnf | cut -d"=" -f2`
              sed -i "s|DEFAULT_CHARSET|$content|" "$server_file"
              # DEFAULT_COUNTRY_NAME
              content=`grep DEFAULT_COUNTRY_NAME $parent_path/../current_defaults/server.cnf | cut -d"=" -f2`
              sed -i "s|DEFAULT_COUNTRY_NAME|$content|" "$server_file"
              # DEFAULT_STATE
              content=`grep DEFAULT_STATE $parent_path/../current_defaults/server.cnf | cut -d"=" -f2`
              sed -i "s|DEFAULT_STATE|$content|" "$server_file"
              # DEFAULT_LOCALITY
              content=`grep DEFAULT_LOCALITY $parent_path/../current_defaults/server.cnf | cut -d"=" -f2`
              sed -i "s|DEFAULT_LOCALITY|$content|" "$server_file"
              # DEFAULT_ORGANIZATION_NAME
              content=`grep DEFAULT_ORGANIZATION_NAME $parent_path/../current_defaults/server.cnf | cut -d"=" -f2`
              sed -i "s|DEFAULT_ORGANIZATION_NAME|$content|" "$server_file"
              # DEFAULT_CRL
              content=`grep DEFAULT_CRL $parent_path/../current_defaults/server.cnf | cut -d"=" -f2`
              sed -i "s|DEFAULT_CRL|$content|" "$server_file"
              # # DEFAULT ocsp
              content=`grep DEFAULT_OCSP $parent_path/../current_defaults/server.cnf | cut -d"=" -f2`
              sed -i "s|DEFAULT_OCSP|$content|" "$server_file"
              # DEFAULT password
              content=`grep DEFAULT_PASSWORD $parent_path/../current_defaults/server.cnf | cut -d"=" -f2`
              sed -i "s|DEFAULT_PASSWORD|$content|" "$server_file"
              # DEFAULT COMMON NAME
              content=`grep DEFAULT_COMMON_NAME $parent_path/../current_defaults/server.cnf | cut -d"=" -f2`
              sed -i "s|DEFAULT_COMMON_NAME|$content|" "$server_file"
              # DEFAULT email
              rev_string=`grep DEFAULT_EMAIL $parent_path/../current_defaults/server.cnf | cut -d"=" -f2 | cut -d"@" -f2`
              servercommonname=`grep DEFAULT_SERVER_COMMON_NAME $parent_path/../current_defaults/server.cnf | cut -d"=" -f2`

            fi

            if [ -f "$parent_path$ca_dir/server.crt" ]; then
              mv "$parent_path$ca_dir/server.crt" "$parent_path$backup_previous_ca/$date"
            fi
            if [ -f "$parent_path$ca_dir/server.crt" ]; then
              mv "$parent_path$ecc_dir/server.crt" "$parent_path$backup_previous_ca/$date"
            fi

            printf "\n"

            only_server=$option
          fi
        fi
      fi

      if [ "$option" == 3 ]; then
        print 2 "Abortando."
        exit 0;
      fi

    else
      print 0 "Generando nueva CA."
      no_previous_ca=1
    fi
  else
    copyFromTemplate
    print 0 "Generando nueva CA."
    no_previous_ca=1
  fi

} 

############################################################################################################
# Funcion copyFromTemplate: allows to copy the template files                                              #
############################################################################################################
function copyFromTemplate()
{
  
  cd "$parent_path"

  process_completed=0

  # Check if necessary files exists 
  for i in "${files[@]}"
  do
    if [ -d "$parent_path$bck_folder" ]
    then
      # Check if backup files exists
      if [ ! -f "$parent_path$bck_folder/$i.tmpl" ]
      then
        print 2 "No existe el fichero plantilla: $i.tmpl."
        process_completed=1
      fi
    else
      print 2 "No exite el directorio de backup. Abortando."
      process_completed=1
    fi
  done

  if [ $process_completed == 0 ]
  then
      
      mkdir -p "$parent_path$backup_previous_ca/$date"
      for i in "${files[@]}"
      do
        if [ -f "$parent_path/../$i"  ]; then
          mv "$parent_path/../$i" "$parent_path$backup_previous_ca/$date"
        fi;
      done

      print 3 "Copying clean files."
      echo ""
      for i in "${files[@]}"
      do
        cp "$parent_path$bck_folder/$i.tmpl" "$parent_path/../$i"
      done

  else
    print 2 "No existen los ficheros necesarios para comenzar el proceso."
    print 2 "Carpeta de ficheros de backup inexistente."
    print 2 "Abortando."
    exit 1
  fi

}

############################################################################################################
# askForCN function, asks for the FQDName                                                                  #
############################################################################################################
function askForCN()
{

  printf "\n"
  if [ commonname == "" ]; then
    aux=$commonname
    printf "FQDN/Nombre común (p. ej. ${green}$commonname${nc}): "
  else
    printf "FQDN/Nombre común (p. ej. ${green}eduroam.organizacion.es${nc}): "
  fi
  read commonname

  while [ "$commonname" == "" ]; do
    printf "\n${red}El FQDN es obligatorio${nc}, no puede quedar vacío.\n"
    printf "\nPor favor, indica un FQDN válido: "
    read commonname
  done

  if [ "$commonname" != "" ] && [[ "$commonname" =~ ^[^.*]+(\.[^.*]+){2,} ]]; then
    printf "\nSe ha leído ${yellow}${commonname}${nc}, ¿continuar? [s/n]: "
  else
    if [ "$commonname" != "" ]; then
      printf "\nSe ha leído ${yellow}${commonname}${nc}, ${red}no parece un nombre válido${nc}, ¿continuar? [s/n]: "
    fi
  fi

  read option

  while [ "$option" != "" ] && [ "$option" != 'S' ] && [ "$option" != 'Y' ] && [ "$option" != 's' ] && [ "$option" != 'y' ] && [ "$option" != 'N' ] && [ "$option" != 'n' ]; do
    printf "Opción no válida. ¿Continuar con esta opción? [s/n]: "
    read option
  done

  if [ "$option" == 's' ] || [ "$option" == 'S' ] || [ "$option" == 'Y' ] || [ "$option" == 'y' ]; then
    cn_error=0
  fi

  if [ "$option" == 'n' ] || [ "$option" == 'N' ]; then
    cn_error=1
  fi

  if [ "$cn_error" != 1 ]; then

    protocol="$(echo "$commonname" | grep :// | wc -l )"
    if [ $protocol -eq 0 ]; then
      url=$commonname
    else
      protocol="$(echo $commonname | grep :// | sed -e's,^\(.*://\).*,\1,g')"
      url=$(echo $commonname | sed -e s,$protocol,,g)
    fi

    path="$(echo $url | grep / | cut -d/ -f1 | wc -l)"
    if [ $path -eq 0 ]; then
      url=$url;
    else
      url="$(echo $url | grep / | cut -d/ -f1)"
    fi

    domain=$url

    dots="$(echo $url | grep -o '\.' | wc -l)";
    if [ $dots -gt 1 ]; then
      rev_string="$(echo $url | rev | cut -d. -f1)"
      rev_string=$rev_string".$(echo $url | rev | cut -d. -f2)"
      rev_string="$(echo $rev_string|rev)"
      if [ $protocol != 0 ]; then
        rev_string_with_protocol="$protocol$rev_string"
      else
        rev_string_with_protocol="http://$rev_string"
      fi
    fi

    echo ""
    print 0 "$url"
  fi

}

############################################################################################################
# askServerCN function, asks for server FQDName                                                            #
############################################################################################################
function askServerCN()
{
  
  printf "\n"
  if [ servercommonname == "" ]; then
    aux=$servercommonname
    printf "FQDN/Nombre común para el certificado del servidor (p. ej. ${green}$servercommonname${nc}): "
  else
    aux="radius.$rev_string"
    printf "FQDN/Nombre común para el certificado del servidor (p. ej. ${green}radius.$rev_string${nc}): "
  fi

  read servercommonname

  printf "\n"
  if [ "$servercommonname" == "" ]; then
    servercommonname=$aux
  fi
  if [ "$servercommonname" != "" ] && [[ "$servercommonname" =~ ^[^.*]+(\.[^.*]+){2,} ]]; then
    printf "\nSe ha leído ${yellow}${servercommonname}${nc}, ¿continuar? [s/n]: "
    read option
  else
    if [ "$servercommonname" != "" ]; then
      printf "\nSe ha leído ${yellow}${servercommonname}${nc}, ${red}no parece un nombre válido${nc}, ¿continuar? [s/n]: "
      read option
    fi
  fi

  while [ "$option" != "" ] && [ "$option" != 'S' ] && [ "$option" != 'Y' ] && [ "$option" != 's' ] && [ "$option" != 'y' ] && [ "$option" != 'N' ] && [ "$option" != 'n' ]; do
    printf "Opción no válida. ¿Continuar con esta opción? [s/n]: "
    read option
  done

  if [ "$option" == 's' ] || [ "$option" == 'S' ] || [ "$option" == 'y' ] || [ "$option" == 'Y' ]; then
    cn_server_error=0
  fi

  if [ "$option" == 'n' ] || [ "$option" == 'N' ]; then
    cn_server_error=1
  fi

  if [ "$cn_server_error" != 1 ]; then

    protocol="$(echo "$servercommonname" | grep :// | wc -l )"
    if [ $protocol -eq 0 ]; then
      url=$servercommonname
    else
      protocol="$(echo $servercommonname | grep :// | sed -e's,^\(.*://\).*,\1,g')"
      url=$(echo $servercommonname | sed -e s,$protocol,,g)
    fi

    path="$(echo $url | grep / | cut -d/ -f1 | wc -l)"
    if [ $path -eq 0 ]; then
      url=$url;
    else
      url="$(echo $url | grep / | cut -d/ -f1)"
    fi

    domain=$url
    echo ""
    print 0 "$servercommonname"

  fi

}

############################################################################################################
# askForOrganization function: asks for the organizacion name                                              #
############################################################################################################
function askForOrganization()
{
  printf "Indique el nombre de su organización (p. ej. ${green}RedIRIS${nc}): "
  read organizationname
  echo ""
  while [ "$organizationname" = "" ]; do
    printf "${red}[Aviso]${nc} El nombre de su organización es obligatorio.\n\n";
    printf "Nombre de su organización (p. ej. ${green}RedIRIS${nc}): "
    read organizationname
    echo ""
  done

  echo ""
  print 0 $organizationname

}

############################################################################################################
# askForCharacterSet function: asks the user for the charset                                               #
############################################################################################################
function askForCharacterSet()
{
  printf "Juego de caracteres para el DN del certificado, (p. ej. ${green}default${nc}, ${green}pkix${nc}, ${green}utf8only${nc}, ${green}nombstr${nc}) [utf8only]: "
  read string_mask
  if [ "$string_mask" = "" ]; then
    string_mask="utf8only"
  fi
  while [ $string_mask != "default" ] && [ $string_mask != "pkix" ] && [ $string_mask != "utf8only" ] && [ $string_mask != "nombstr" ];
  do
    printf "\n${red}[Aviso]${nc} Máscara de tipo de cadena ${red}$string_mask${nc} no válida. \n\n"
    askForCharacterSet
  done

  # warning in case of not selecting utf8
  if [ "$string_mask" != "utf8only" ]; then
    echo ""
    print 1 $string_mask

    printf "${yellow}\n"
    printf "##################################################################\n"
    printf "AVISO: No has escogido utf8only.\n"
    printf "Si vas a usar caracteres internacionales, es recomendable hacerlo.\n"
    printf "(Ver https://www.openssl.org/docs/apps/req.html y\n"
    printf " http://www.ietf.org/rfc/rfc2459.txt)\n"
    printf "##################################################################\n"
    printf "${nc}\n"
    echo ""

    printf "¿Continuar con esta opción? [S/n]: "
    read charset_option
    
    while [ "$charset_option" != 'S' ] && [ "$charset_option" != 'Y' ] && [ "$charset_option" != 's' ] && [ "$charset_option" != 'y' ] && [ "$charset_option" != 'N' ] && [ "$charset_option" != 'n' ]; do
      printf "Opción no válida. ¿Continuar con esta opción? [s/n]: "
      read charset_option
    done
    
    if [ "$charset_option" == 'n' ] || [ "$charset_option" == 'N' ]; then
      askForCharacterSet
    fi
    if [ "$charset_option" == 'S' ] || [ "$charset_option" == 'Y' ] || [ "$charset_option" == 's' ] || [ "$charset_option" == 'y' ]; then
      echo ""
      print 1 $charset_option
    fi
    echo ""
  else
    echo ""
    print 0 $string_mask
  fi

}

############################################################################################################
# askForEmailAddress function: email address                                                               #
############################################################################################################
function askForEmailAddress()
{
  
  printf "Dirección de correo electrónico (p. ej. ${green}eduroam@$rev_string${nc}) [${green}eduroam@$rev_string${nc}]: "
  read email

  if [ "$email" == "" ]; then
    email="eduroam@$rev_string"
  fi
  while [ true ]; do
    if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$ ]]; then
      break
    else
      printf "\n${red}[Aviso]${nc} Dirección de correo electrónico inválida, por favor, introduce un valor correcto (p. ej. ${green}eduroam@${rev_string}${nc}): ";
      read email
    fi
  done

  printf "\n"
  print 0 $email

}

############################################################################################################
# askForCountry function, permite obtener el valor de país en formato ISO                                  #
############################################################################################################
function askForCountry()
{

  printf "CountryName (ISO 3166, https://www.iso.org/obp/ui/#search/code/, p. ej. ${green}ES${nc} for España): "
  read countryname
  while [ "${#countryname}" != 2  ]; do
    printf "\n${red}[Aviso]${nc} El campo CountryName debe contener 2 caracteres: ";
    read countryname
  done

  countryname=$(echo $countryname|awk '{print toupper($0)}')
  printf "\n"
  print 0 $countryname

}

############################################################################################################
# askForState function, asks the user for the region value                                                 #
############################################################################################################
function askForState()
{

  printf "Indica una CCAA o provincia (p. ej. ${green}Madrid${nc}): "
  read state
  while [ "$state" == "" ]; do
    printf "\n${red}[Aviso]${nc} El campo no puede estar vacío, por favor, indica una CCAA o provincia (p. ej. ${green}Madrid${nc}): "
    read state
  done

  echo ""
  print 0 $state

}

############################################################################################################
# askForLocality function, asks the user for the locality value                                            #
############################################################################################################
function askForLocality()
{
  
  printf "Indica una localidad (p. ej. ${green}Madrid${nc}): "
  read locality
  while [ "$locality" == "" ]; do
    printf "\n${red}[Aviso] ${nc}El campo no puede estar vacío, por favor, indica una localidad (p. ej. ${green}Madrid${nc}): "
    read locality
  done

  echo ""
  print 0 $locality

}

############################################################################################################
# askForCRLProtocol function, allows the user to set a protocol for the CRL url                            #
############################################################################################################
function askForCRLProtocol()
{

  protocol_like="https"
  printf "\nIndica el protocolo hacia la ruta donde se encontrará el fichero de la CRL (http, https) [${protocol_like}]: "
  read crl_protocol
  if [ "$crl_protocol" == "" ]; then
    crl_protocol=$protocol_like
  fi

  printf "\nSe ha leído: ${yellow}$crl_protocol${nc} , ¿es correcto? [s/n]: "
  read option
  while [ "$option" != "" ] && [ "$option" != "" ] && [ "$option" != 'S' ] && [ "$option" != 'Y' ] && [ "$option" != 's' ] && [ "$option" != 'y' ] && [ "$option" != 'N' ] && [ "$option" != 'n' ]; do
    printf "\nOpción no válida. Indica [s/n]: "
    read option
  done
  
  if [ "$option" == 'n' ] || [ "$option" == 'N' ]; then
    askForCRLProtocol
  fi
  if [ "$option" == 'S' ] || [ "$option" == 'Y' ] || [ "$option" == 's' ] || [ "$option" == 'y' ]; then
    echo ""
    print 1 $option
  fi

}

############################################################################################################
# Función askForCRL, allows the user to set the CRL url                                                    #
############################################################################################################
function askForCRL()
{
  
  crl_like="$crl_protocol://$rev_string/${green}eduroam_ca.crl${nc}"
  aux="$crl_protocol://$rev_string/eduroam_ca.crl"
  printf "\nRuta hacia el fichero crl, introduce solo el valor correspondiente"
  printf "\na la ubicación del fichero sin teclear la url completa.\n"
  printf "(p. ej.: $crl_like )\n${yellow}Esta es una opción requerida para ciertas versiones anteriores a Windows 10.${nc}\n[$crl_like]: "
  read crl
  if [ "$crl" == "" ]; then
    crl=$aux
  else
    crl="$crl_protocol://$rev_string/$crl"
  fi

  printf "\nEl valor de la URL completa hacia el fichero crl es el siguiente: ${yellow}${crl}${nc} ¿Es correcto? [s/n]: "

  read crl_option
  while [ "$crl_option" != "" ] && [ "$crl_option" != 'S' ] && [ "$crl_option" != 'Y' ] && [ "$crl_option" != 's' ] && [ "$crl_option" != 'y' ] && [ "$crl_option" != 'N' ] && [ "$crl_option" != 'n' ]; do
    printf "Opción no válida. ¿Continuar? [s/n]: "
    read crl_option
  done

  if [ "$crl_option" == 'n' ] || [ "$crl_option" == 'N' ]; then
    askForCRL
  fi

  if [ "$crl_option" == 's' ] || [ "$crl_option" == 'S' ]; then
    echo ""
    print 0 "$crl"
  fi

}

############################################################################################################
# askForOCSPProtocol function, allows the user to set a protocol for the OCSP url                          #
############################################################################################################
function askForOCSPProtocol()
{

  protocol_like="https"
  printf "\nIndica el protocolo hacia la ruta donde se encontrará el fichero de la CRL (http, https) [${protocol_like}]: "
  read ocsp_protocol
  if [ "$ocsp_protocol" == "" ]; then
    ocsp_protocol=$protocol_like
  fi

  printf "\nSe ha leído: ${yellow}$ocsp_protocol${nc} , ¿es correcto? [s/n]: "
  read option
  while [ "$option" != "" ] && [ "$option" != 'S' ] && [ "$option" != 'Y' ] && [ "$option" != 's' ] && [ "$option" != 'y' ] && [ "$option" != 'N' ] && [ "$option" != 'n' ]; do
    printf "\nOpción no válida. Indica [s/n]: "
    read option
  done
  
  if [ "$option" == 'n' ] || [ "$option" == 'N' ]; then
    askForOCSPProtocol
  fi
  if [ "$option" == 'S' ] || [ "$option" == 'Y' ] || [ "$option" == 's' ] || [ "$option" == 'y' ]; then
    echo ""
    print 1 $option
  fi

}

############################################################################################################
# askForOCSP function, asks the user for the ocsp url                                                      #
############################################################################################################
function askForOCSP()
{
  ocsp_like="$ocsp_protocol://$rev_string/${green}ocsp${nc}"
  aux="$ocsp_protocol://$rev_string/ocsp"
  printf "\nRuta hacia el servicio OCSP, introduce solo el valor correspondiente"
  printf "\na la ruta sin teclear la url completa.\n"
  printf "${yellow}Este servicio es opcional, pero se ha de indicar una URL por defecto.${nc}\n"
  printf "(p. ej.: $ocsp_like ), [$ocsp_like]: "
  read ocsp
  if [ "$ocsp" == "" ]; then
    ocsp=$aux
  else
    ocsp="$ocsp_protocol://$rev_string/$ocsp"
  fi

  printf "\nEl valor de la URL completa hacia el servicio OCSP es la siguiente: ${yellow}${ocsp}${nc} ¿Es correcta? [s/n]: "

  read ocsp_option
  while [ "$ocsp_option" != "" ] && [ "$ocsp_option" != 'S' ] && [ "$ocsp_option" != 'Y' ] && [ "$ocsp_option" != 's' ] && [ "$ocsp_option" != 'y' ] && [ "$ocsp_option" != 'N' ] && [ "$ocsp_option" != 'n' ]; do
    printf "Opción no válida. ¿Continuar? [S/n]: "
    read ocsp_option
  done

  if [ "$ocsp_option" == 'n' ] || [ "$ocsp_option" == 'N' ]; then
    askForCRL
  fi

  if [ "$ocsp_option" == 's' ] || [ "$ocsp_option" == 'S' ]; then
    echo ""
    print 0 "$ocsp"
  fi
  
}

############################################################################################################
# askForPassword function, asks the user for a password                                                    #
############################################################################################################
function askForPassword()
{
  password_1=""
  password_2=""
  printf "Introduce la password para proteger los ficheros generados (la contraseña no se verá en pantalla): "
  read -s password_1
  while [ "$password_1" == "" ]; do
    printf "${yellow}La contraseña no puede quedar vacía, por favor, introduce una: ${nc}"
    read -s password_1
  done

  printf "\nRepite la password (la contraseña no se verá en pantalla): "
  read -s password_2
  while [ "$password_2" == "" ]; do
    printf "${yellow}La contraseña no puede quedar vacía, por favor, introduce la misma: ${nc}"
    read -s password_2
  done

  if [ "$password_1" != "$password_2" ]
  then
    echo ""
    print 2 "Las contraseñas no son iguales. Por favor, repítelas."
    echo ""
    askForPassword
  fi

  password=$password_1

  printf "\n"
  print 0 "Passwords correctas"

}

############################################################################################################
# askForServerData function, asks the user for new server data and calls makeServer function               #
############################################################################################################
function askForServerData()
{
  askForCN
  askForEmailAddress
  makeServer
}

############################################################################################################
# fillData function, sets user data to config files                                                        #
############################################################################################################
function fillData()
{

  if [ $no_previous_ca == 1 ]
  then
    # read files
    for i in "${files[@]}"
    do
      
      cnf_file_path="$parent_path/../$i"
      
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
      # # DEFAULT ocsp
      sed -i "s|DEFAULT_OCSP|$ocsp|" "$cnf_file_path"
      # DEFAULT password
      sed -i "s|DEFAULT_PASSWORD|$password|" "$cnf_file_path"
      # DEFAULT COMMON NAME
      sed -i "s|DEFAULT_COMMON_NAME|$commonname|" "$cnf_file_path"
      # DEFAULT email
      sed -i "s|DEFAULT_EMAIL|$email|" "$cnf_file_path"
      # DEFAULT COMMON SERVER NAME
      sed -i "s|DEFAULT_SERVER_COMMON_NAME|$commonname|" "$cnf_file_path"

      current_default_file="$parent_path/../$file_defaults_folder/$i"

      if [ -f "$current_default_file" ]; then
        echo "DEFAULT_CHARSET="$string_mask > "$current_default_file"
        echo "DEFAULT_COUNTRY_NAME="$countryname >> "$current_default_file"
        echo "DEFAULT_STATE="$state >> "$current_default_file"
        echo "DEFAULT_LOCALITY="$locality >> "$current_default_file"
        echo "DEFAULT_ORGANIZATION_NAME="$organizationname >> "$current_default_file"
        echo "DEFAULT_CRL="$crl >> "$current_default_file"
        echo "DEFAULT_OCSP="$ocsp >> "$current_default_file"
        echo "DEFAULT_PASSWORD="$password >> "$current_default_file"
        echo "DEFAULT_COMMON_NAME="$commonname >> "$current_default_file"
        echo "DEFAULT_EMAIL="$email >> "$current_default_file"
        echo "DEFAULT_SERVER_COMMON_NAME="$servercommonname >> "$current_default_file"
      fi
    done
  fi
  
  # if there are new data for server file...
  if [ $only_server == 1 ]; then
    sed -i "/DEFAULT_EMAIL/d" "$parent_path/../$file_defaults_folder/server.cnf"
    sed -i "/DEFAULT_COMMON_NAME/d" "$parent_path/../$file_defaults_folder/server.cnf"
    echo "DEFAULT_EMAIL="$email >> "$parent_path/../$file_defaults_folder/$i"
    echo "DEFAULT_COMMON_NAME="$commonname >> "$parent_path/../$file_defaults_folder/$i"
  fi

}

############################################################################################################
# showInfo function: displays info when the process ends                                                   #
############################################################################################################
function showInfo()
{
  
  printf "\n\nSe han generado los certificados en base a los valores que ha\n"
  printf "indicado durante el proces.\n"
  printf "\nPodrá encontrar las siguientes carpetas y ficheros:\n\n"

  printf "    1.- CARPETA ${green}rsa${nc} (Sistema criptográfico de clave pública)\n"
  printf "      1.1.- Ficheros disponibles (entre otros): \n"
  printf "        1.1.3.- ca.pem, server.key, server.pem\n"
  printf "\n"
  printf "    2.- CARPETA ${green}ecc${nc} (Criptografía de curva elíptica)\n"
  printf "      2.1.- Ficheros disponibles (entre otros): \n"
  printf "        2.1.1.- ca.pem, server.key, server.pem\n"
  printf "\n"
  printf "    3.- Fichero ${yellow}${date}.log${nc}: fichero con log obtenido durante la generación de los certificados."
  printf "\n"

  printf " Puede encontrar más información en el siguiente enlace: https://wiki.rediris.es/display/ED/Certificados\n\n\n"

}

############################################################################################################
# makeAll function, allows to create all CA files                                                          #
############################################################################################################
function makeAll()
{

  fillData

  printf "\n"
  print 3 "Todos los datos solicitados."
  print 3 "Generando CAs."

  cd "$parent_path/../"
  make all > "$date.log"

  errors=$(cat "$date.log" | grep 'error' | wc -l)
  if [ $errors != 0 ]; then
    printf "\n"
    print 2 "Se han producido errores. Comprueba el fichero $date.log"
    print 2 "Proceso finalizado con errores."
  else
    print 0 "Proceso finalizado correctamente."
    showInfo
  fi

}

############################################################################################################
# makeServer function, allows to create the server CAs                                                     #
############################################################################################################
function makeServer()
{

  fillData

  echo ""
  print 3 "Todos los datos solicitados."
  print 3 "Generando CA de servidor."

  cd "$parent_path/../"
  make server > "$date.log"

  errors=$(cat "$date.log" | grep 'error' | wc -l)

  if [ $errors != 0 ]; then
    printf "\n"
    print 2 "Se han producido errores. Comprueba el fichero $date.log"
    print 2 "Proceso finalizado con errores"
  else
    print 0 "Proceso finalizado correctamente."
    showInfo
  fi

}

############################################################################################################
# cleanAll function, removes all files not necessary to start from scratch                                 #
############################################################################################################
function cleanAll()
{

  echo " $parent_path/../*.log"

  printf "${red}Atención, se borrarán todos los ficheros NO necesarios para empezar de cero. Incluirá\n"
  printf "  *  Carpetas backup con los valores actuales.\n"
  printf "  *  Carpetas 'rsa' y 'ecc'.\n"
  printf "Una vez que estos datos sean borrados, se deberá generar una nueva CA a partir de cero.\n${nc}"
  printf "\n"
  printf "${yellow}¿Continuar? [s/n]${nc}: "
  read option
  printf "\n"

  if [ "$option" == 's' ] || [ $option == "S" ] || [ "$option" == 'y' ] || [ $option == "Y" ]; then
    print 1 "Iniciando borrado..."
    print 1 "Borrado de configuraciones anteriores... "
    rm -rf "$parent_path$backup_previous_ca"
    rm -rf "$parent_path/../$file_defaults_folder"
    print 1 "Borrado de logs..."
    cd "$parent_path/../"
    rm -rf "*.log"
    print 1 "Ejecutando 'make clean'"
    make clean

    print 1 "Copiando ficheros nuevos"

    for i in "${files[@]}"
    do
      cnf_file_path="$parent_path$bck_folder/$i.tmpl"
      cp -f "$cnf_file_path" "$i"
    done

    print 0 "Borrado finalizado."

  else
    print 2 "Opción no válida. Abortando"
  fi

}

############################################################################################################
# End of functions block
#
# Bind of interruption signals (SIGINT y SIGKILL)
trap finish SIGINT
trap finish SIGKILL

if [ -z "$1" ]; then
  echo ""
  echo "*-----------------------------------------------------------------------*"
  echo "|           Script de generación de certificados para eduroam           |"
  echo "|                                                                       |"
  echo "| Este scrpt le solicitará, paso a paso, una serie de datos para        |"
  echo "| cumplimentar los distintos valores necesarios u opcionales para la    |"
  echo "| generación de los distintos certificados.                             |"
  echo "|                                                                       |"
  echo "*-----------------------------------------------------------------------*"
  echo ""
  # Check existing CA
  checkExistingCA
  # New defaults if necessary
  checkDefaults

  # Si no exite una CA previa, se solicitan todos los datos y se generan las CA
  if [ "$no_previous_ca" == 1 ]; then
    askForCN
    while [ $cn_error == 1 ]; do
      askForCN
    done
    askServerCN
    while [ $cn_server_error == 1 ]; do
      askServerCN
    done
    askForOrganization
    askForCharacterSet
    askForEmailAddress
    askForCountry
    askForState
    askForLocality
    askForCRLProtocol
    askForCRL
    askForOCSPProtocol
    askForOCSP
    askForPassword
    # Make all certs
    makeAll
  fi

  # Ask for new data just in case there are a previous CA
  if [ "$only_server" == 1 ]; then
    askForEmailAddress
    askServerCN
     while [ $cn_server_error == 1 ]; do
      askServerCN
    done
    # Make server cert
    makeServer
  fi

  # If only wants to remake the server certificate
  if [ "$only_server" == 2 ]; then
    makeServer
  fi

else
  if [ $1 == '-h' ] || [ $1 == "--h" ]; then
    help
  fi

  if [ $1 == "-c" ] || [ $1 == "--c" ]; then
    cleanAll
  fi
fi