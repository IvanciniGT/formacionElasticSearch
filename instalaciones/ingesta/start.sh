#!/bin/bash

# Creamos la carpeta donde se guardarán los logs del apache en el host.. y le abrimos permisos
mkdir -p /home/ubuntu/environment/datos/apache/logs
chmod 777 /home/ubuntu/environment/datos/apache/logs

# Filebeat, guarda en un ficherito propio los datos que va leyendo...
# No los datos.. por qué posición de un fichero va!
docker compose down # Nos asegura que el contenedor de filebeat se borra, de forma que cuando arranque, procese el 
                    # el fichero de log desde el principio
docker compose up $1