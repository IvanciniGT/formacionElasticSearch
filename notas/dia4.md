
# Volumenes para los contenedores

Un contenedor tiene su propio sistema de archivos.




---

/
    etc/
    opt/
    bin/
    home/
        datos/
    root/
    var/
        lib/
            docker/
                ...
                    images/
                        elasticsearch/ < --- CHROOT
                            etc/
                            opt/
                            bin/
                            home/
                            root/
                            var/
                                elasticsearch/logs/
                    containers/
                        maestro1/
                            var/
                                elasticsearch/logs/
                                    log1.txt

Adicionalmente a esto, cuando creamos un contenedor podemos añadirle volumenes.
Los volumenes son solo puntos de montaje en el fs del contenedor, como si monto una carpeta nfs.

Trabajando con docker, lo normal es usar esta funcionalidad para compartir una carpeta del host con el contenedor
    /home/datos/ del host quiero tenerla disponible en el fs del contenedor.. en /var/elasticsearch/data
    Cuando algo se guarde en esa carpeta dentro del contenedor (por algún proceso que se ejecute en el contenedor)
    realmente se guarda en la carpeta /home/datos/.
    
    Esto permite que al eliminar un contenedor, sus datos permanezcan vivos.
    Con las mismas, podría en el futuro crear un contenedor nuevo,
    al que le inyecte la misma carpeta (y por ende los mismos datos)

En un entorno de producción (y docker no es una herramienta para entornos de producción) 
los volumenes con los datos no los quiero en el host, los quiero en un almacenamiento externo al host:
- Volumen en un cloud
- Cabina de almacenamiento por fibra
- Servidor NFS
- Para casos muy puntuales, podría incluso usar un volumen local
    
CHROOT: Engañar a un proceso para hacerle creer que el root del fs es otro diferente (subcarpeta)

# Para qué sirven los volumenes en los contenedores?

- Persistencia: En entornos de producción necesito volumenes fuera del host
                Si se cae el host puedo crear un contenedor nuevo en otro host, pero con los mismo datos 
                (que podrá acceder a ellos por estar en un almacenamiento externo).
- Inyectar datos en un contenedor (configuraciones, certificados...)
- Compartir información entre contenedores


    Servidor web (Apache, nginx) - CONTENEDOR 1
        v
        escribe el log /var/apache/log/
        v
        access.log
        ^
        leyendo el log /datos-a-indexar
        ^
    Filebeat    - http ->          Logstash    - http ->   ES
        |
        CONTENEDOR 2
    
    Esos programas (Servidor web y filebeat) si los instalo como contenedores,
    los pondré en el mismo contenedor o en contenedores separados?
        Podría hacer las 2 cosas.. pero el ponerlo junto solo me complicaría la vida:
            - Los fabricantes ya me dan imágenes de contenedor del servidor web y de filebeat.. por separado
            - Si yo quiero desplegarlos juntos necesitaría crear mi propia imagen de contenedor (FOLLONCITO)
            - No aporta nada el tenerlo junto.. de hecho lo contrario... desaporta.
            Si el filebeat se vuelve loco.. y hay que reiniciarlo, no tengo porque detener el servidor web (servicio real)
    Siempre instalamos estas cosas por separado.
    
    En el mundo kubernetes ambos contenedores los desplegaría en lo que llamamos un POD.
    
    Qué es un pod? Es un grupo de contenedores (1 puede ser un grupo) que:
    - Escalan juntos
    - Tengo garantizado que se despliegan en el mismo host
        -> Pueden compartir volumenes locales de almacenamiento
    - Comparten configuración de red
    
    En nuestro caso, servidor web y filebeat deben compartir el volumen donde se guarda el access.log.
    Y ese volumen no me interesa que sea un volumen externo al host... si lo fuera:
    - Tengo que ir por la red a guardarlo en elgún sitio \
    - Y acto seguido tengo que ir por la red a leerlo... / En el mismo host
    
    Es más... incluso me podría interesar que ese volumen estuviera en RAM.
    Eso es algo que puedo hacer en Kubernetes... (de hecho es algo que podía hacer ya con MSDOS)
    Puedo reservar un trozo de RAM y montarlo en el FS, para usarlo como una carpeta.
    El rendimiento de eso es inmejorable (olvidate de NVME.. y de cual otra cosa)
    
    De hecho esto es una configuración muy frecuente en casos como este (del filebeat).
    En el apache configuro 2 ficheros de log rotados de 50Kbs... Y acabo de limitar el uso de RAM a 100Kbs.
    
## Volumenes en Docker

En docker cuando creamos volumenes locales, hay 2 formas:
- Tradicional / Asignación estática
- Named Volumes

En nuestro caso (el fichero descargado de la web de ES) están configurados named volumes.
Esto no nos gusta mucho, por qué? Básicamente porque no tengo idea de donde se están realmente
guardando los datos, ni puedo acceder a ellos (datos) fácilmente:
- Copia de seguridad
- Mandar mis datos a un compañero

Prefiero tener volumenes tradicionales, con asignación estática a una carpeta del host, que pueda:
- Ver 
- Copiar
- Modificar

En muchos docker-compose que descargamos de internet se ven volumenes de tipo NAMED.
El hecho es que si ellos en un sitio web ponen para descarga un docker-compose con volumenes que se 
guarden en carpetas concretas del host...
cada persona que descargue el archivo tendría que modificarlo.. o crear esas carpetas en su host.

Pero si quiero algu un poquito más serio (con más control) en local necesito volumenes con asignación estática...
no es que los necesite.. ME INTERESAN por el control que me dan.

---

Todo nodo es capaz de atender peticiones.
A algunos nodos les asigno tareas concretas: master, data, ml
Si lo hago cuando DENTRO del cluster exista la necesidad de hacer un trabajo de un tipo concreto, 
se mandará a un nodo que pueda hacer ese tipo de trabajo.
    - Si hay que hacer un algoritmo de ml, elastisearch se lo encargará INTERNAMENTE a un nodo que 
      pueda hacer eso (con role ml)
Los nodos que no reciban trabajo desde DENTRO del cluster, y a los que desde fuera SI LES ESTÉ MANDANDO TRABAJO
son los nodos a los que llamo de coordinación.
Evidentemente sería absurdo crear un nodo sin roles, y no exponerlo al público... Estaría parao siempre.


---

Al levantar un cluster, tengo garantías de que o el maestro1 o el maestro2 van a estar arriba.
Si no estuviera ninguno arriba, por definición NO HAY CLUSTER.

    HOST  (IP-HOST:8080 -> IP-Coordinador1:9200)
        Maestro1 > Maestro2
            ^        ^
            +----+---+
                 |
                Datos1
                Datos2
                Datos3
                Coordinador1 (IP-Coordinador1:9200)
                Coordinador2 (IP-Coordinador2:9200)

---

En un entorno real necesitaría un balanceador de carga entre coordinador1 y coordinador2.
Una alternativa (no tan recomendable) sería en los clientes que conecten con el cluster, darle la dirección de los 2.
ELK (Kibana, logstash, beats) permiten hacer esto... pero es pan para hoy y hambre para mañana.

Ese balanceador en KUBERNETES es lo que se llama un SERVICE.

    En un cluster de kubernetes a nivel lógico:
        
        Namespace de ElasticSearch:
            Pod maestro1 \
            Pod maestro2 / Servicio que balancee entre ellos
            Pod datos1
            Pod datos2
            Pod datos3
            Pod coordinador1 \
            Pod coordinador2 / Servicio externo para inserciones y consultas    < Ingress


    Servicios
        Uno para los maestros: es-maestros
            Las configuraciones de discovery.seed_hosts de los nodos que no sean maestros 
                apuntarian a este servicio.
                    discovery.seed_hosts=es-maestros
            Las configuraciones de discovery.seed_hosts de los nodos que si sean maestros 
                tendrían que apuntar a los maestros de forma individual.
                    discovery.seed_hosts=maestro1.es-maestros,maestro2.es-maestros
        Otro para los coordinadores
        No hacen falta más... El resto de comunicaciones son comunicaciones explicitas de un nodo a otro (por IP)
                
    En kubernetes, nosotros no creamos esos pods... definimos:
    - Statefulset** Para ES. Básicamente esto nos garantiza que cada pod va a 
                    tener su pripio volumen de almacenamiento independiente.
                    Cuando montamos uin statefulset, Kubernetes nos regala un servicio 
                    para apuntar a cada pod
    - Deployment.   Los pods comparten volumen. Para ES no interesa
    - Daemonsets
        
    Si quisiera que desde fuera del cluster, un programa pudiera cargar datos o consultar datos del ES?
    - Un ingress
    
En un entorno de producción tradicional:

        es1 y es2               balanceador.elastic        proxy.elastic        proxy.menchu   Menchu

    Servidor 1 (HIERRO)             
        programa1 : 1000    \
    Servidor 2 (HIERRO)         Balanceador de carga   <    Proxy reverso    <   Proxy <    Cliente externo
        programa1 : 1000    /       nginx, apache,           |         |
                                    haproxy, envoy    RED INTERNA      RED_PUBLICA
    
        Menchu -> proxy.elastic
            Pero lo delega en proxy.menchu
            proxy.menchu es quién va a proxy.elastic
            proxy-elastic, le dice a proxy-menchu.. pues quieto ahí, que ya voy yo.
            proxy-elastic --> balanceador.elastic --> programa1
    
        Adicionalmente, el proxy reverso podría estar en 2 redes conectado.
    
    
    En kubernetes, en lugar de servidores físicos, tenemos PODS
    En lugar de programas, tenemos procesos que corren en contenedores
    En lugar de balanceadores de carga, tenemos SERVICES
    En lugar de PROXY REVERSO, tenermos INGRESS-CONTROLLERs
    
    Lo que hacemos luego es CONFIGURAR REGLAS en el proxy reverso:
    - Cuando te hagan una petición bajo el nombre de dominio: elastic, vete al balanceador.elastic
    En kubernetes, a esas reglas es a lo que llamamos un INGRESS.
    Un INGRESS es una regla de proxy reverso, para nuestro proxy reverso (el que tenga instalado), 
    en kubernetes llamado ingress-controller
        - Ante peticiones con este patrón: Habitualmente un nombre de dominio (aunque no necesariamente)
          Las rediriges a un service (balanceador de carga)
    
Proxy reverso?
    Protege la identidad y seguridad de los servidores

Proxy?
    El proxy protege la identidad ( y seguridad ) de los clientes.
    El proxy actua en beneficio (en lugar) del cliente
    Cuando yo (cliente) quiero ir a algún sitio, en lugar de ir yo, le delego el trabajo a un proxy
    El proxy es el que entonoces va a donde yo quería ir, espera él la respuesta.. y me la entrega
---



    Servidor web (Apache, nginx) - CONTENEDOR 1
        v
        escribe el log /var/apache/log/
        v
        access.log
        ^
        leyendo el log /datos-a-indexar
        ^
    Filebeat    - http ->          Logstash    - http ->   ES
        |
        CONTENEDOR 2
    
85 bytes -> 2 Kbs en ES x 6
1M
85 MB.   -> 2 G x 6 = 12Gbs

---


Apache1 ---> Genera access_log  
                   ^
    Filebeat 1 -- Lee y lo manda a  --------------+
                                                  |
Apache2 ---> Genera access_log                    |
                   ^                              |    
    Filebeat 2 -- Lee y lo manda a  --------------+--->     Logstash     -----------> ES
                                                  |  (pre-procesar el fichero)
Apache3 ---> Genera access_log                    |
                   ^                              |
    Filebeat 4 -- Lee y lo manda a  --------------+
    
    
    
---


# REGEX

Se basan en patrones.

Un patron es un conjunto de subpatrones, que lo puedo poner:
- Secuencialmente (uno detras de otro: subpatron1subpatron2)
- O excluyentes  (subpatron1|subpatron2)

Qué es un subpatrón?
    - Una secuencia de caracteres
        HOLA                            Debe aparecer literalmente HOLA
        [HOLA]                          Debe aparecer un caracter de esos: H, O, L, A
        [a-z]                           Un caracter de la a a la z
        [a-zA-Z0-9]
        [a-záéíóúñ]
        .                               Cualquier caracter
        \s                              Cualquier blanco (espacio, tabulador, salto linea)
    - Modificador de cantidad
        Nada                            Debe aparecer 1 vez                                 1
        ?                               Puede aparecer o no                                 0-1
        *                               Puede no aparece o aparecer muchas veces            0-infinito
        +                               Debe aparecer al menos 1 vez                        1- infinito
        {3}                             Debe aparecer 3 veces                               3
        {3,8}                           Debe aparecer entre 3 y 8 veces                     3-8

Especiales:
- ^             Empieza por
- $             Acaba por
- ()            Agrupar


Un número entre 1 y 19
    (1[0-9])|([1-9])

Validar un email (cutre)
    [a-z_.-]+@([a-z]+[.])+[a-z]{2,10}
    
    ivan.osuna@gmail.com
    ivan.osuna@sub.gmail.com