#!/bin/bash

# Creamos la carpeta donde se guardarán los logs del apache en el host.. y le abrimos permisos
mkdir -p /home/ubuntu/environment/datos/apache/logs
chmod 777 /home/ubuntu/environment/datos/apache/logs

docker compose up $1