# Generador de certificados para servidores EAP

Este proyecto permite la generación de certificados de servidor siguiendo las [recomendaciones realizadas en eduroam](https://wiki.geant.org/display/H2eduroam/EAP+Server+Certificate+considerations), de cara a optimizar la compatibilidad con clientes.

El código utiliza como base el [script boostrap y plantillas](https://github.com/FreeRADIUS/freeradius-server/tree/master/raddb/certs) desarrolladas dentro del proyecto FreeRADIUS.

# Uso del software

Clonar el repositorio, y ejecutar el script autoexplicativo `cert-gen/eduroam-cert-generator.sh`:

```
git clone https://github.com/rediris-es/eap_cert_generator.git

cd eap_cert_generator/

sh cert-gen/eduroam-cert-generator.sh

```


