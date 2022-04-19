Información importante relativa a la generación de los certificados con el script desatendido (standalone).

1º Deberá descargar todo el contenido de la carpeta "standalone-cert-gen".

1º Deberá asignar permiso de ejecución sobre el fichero "standalone-eduroam-cert-generator.sh".
   Para ello deberá ejecutar en una termnial (en la misma carpeta en la que se encuentra el fichero):
   - [sudo] chmod +x generar-certificado.sh

3º Deberá ejecutar el fichero "standalone-eduroam-cert-generator.sh".
   Para ello deberá ejecutar en una termnial (en la misma carpeta en la que se encuentra el fichero):
   - [sudo] ./standalone-eduroam-cert-generator.sh
    - El ejecutable espera los siguientes parámetros para funcionar correctamente:
      - Charset (uno de los siguientes): default, pkix, utf8only, nombstr
      - País (2 caracteres), para España: ES
      - Provincia
      - Localidad
      - Nombre de la organización
      - Ruta a la CRL
      - Ruta al OCSP
      - Contraseña
      - CommonName
      - Email
      - ServerCommonName
    - Un ejemplo de ejecución podría ser el siguiente:
      - ./standalone-eduroam-cert-generator.sh utf8only ES Madrid Madrid RedIRIS https://rediris.es/crl https://rediris.es/ocsp 1234 eduroam.rediris.es eduroam@redirs.es radius.rediris.es

5º En la carpeta "certs" se habrán generado los ficheros necesarios.