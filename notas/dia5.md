
    Cluster de ES
        maestro     x 2
        data        x 3   (a 1 le pusimos maestro para votar y a los otros 2 les pusimos ml)
        coordinador x 2

    Kibana -> coordinador1:9200
        
    Apache :80
        ---> access_log
                 ^
    Filebeat  ---+----> Logstash :5044 --(***)---> ES
                            (procesamiento de los datos)
                                Eliminar campos
                                Transformado campos
                                Descuartizado campos
                                Creado campos (posicionamiento)
                                
        85 bytes    -> Filebeat    -> Logstash -> ES (ocupa la vida)
                        Engorda mogollón
                         850 B        Engorda más
                                        1KB
                                                 Con indexación -> 2KB -> x2 (x3) = 12 Kbs
                                                 
(***) Esto es lo que falta: Mandar los documentos desde Logstash hasta ElasticSearch para su indexación.

Tareas / Cosas a tener en cuenta:
√ Cómo conectamos al ES
√ En qué indices cargamos (Mappings para la indexación, Settings)
√ Definir una politica de rotado de los índices
√ Si no tenemos solo un índice, sino muchos índices... tendré que asociar los mappings y settings a todos ellos:
    √ Plantilla de Índices (habrá que definirla)
√ Ciclo de vida de esos índices. Los viejos... no los querré en discos caros.
    √ Los querré ir cerrando ->
        √ Podemos hacer un merge (juntar segmentos)     \
        √ Shrink (juntar shards)                         > Mejorar performance en búsquedas y ahorrar pasta en almacenamiento
        √ Reorganizar la estructura del índice interna  /

Hay 2 formas de enfrentarnos a todo esto:
1. Forma tradicional pre Elastic 8              INDICES TRADICIONALES
   La seguimos usando en muchos escenarios.
   Además es más explicita / manual en las configuraciones (nos permite aprender más sobre el comportamiento interno de ES)
2. Forma nueva post Elastic 8                   DATASTREAMS
   Solo sirve para ciertos tipos de datos
   Y para ellos "simplifica" (o eso dicen) algunas tareas de mnto... haciendo magia por debajo (no evidente)

---

# Cómo conectamos al ES

Esa conexión la queremos hacer desde Logstash -> ES
A quién debería conectar? A qué nodo(s)? Coordinadores
Lo ideal sería tener un balanceador de carga delante de ellos. Si estuvieramos en Kubernetes, nos lo regalan: SERVICE
En el curso vamos a conectar solamente con uno de ellos: coordinador1

Pregunta! El contenedor Coordinador1 y el contenedor Logstash, están en la misma red? En nuestro caso? NO
Si estuvieran en Kubernetes, más que posible estarían en la misma red.
Pero... docker, para cada archivo docker-compose crea una red independiente.

     +------------------------ red de amazon
     |
    172.31.41.172  NAT: 8080 -> coordinador1 = 172.18.0.12:9200
     |
    HOST
     |
     +---------127.0.0.1--------- localback
     |
     +---------172.17.0.1/16-------- docker (por defecto)
     |
     +---------172.18.0.1/16----+--- docker compose instalación
     |                          |
     |                      172.18.0.12 ---- coordinador1 : 9200
     |
     +---------172.19.0.1/16-------- docker compose ingesta
                                |                   
                                |                   Está registrado ese nombre en el DNS de docker
                                |                      v
                                +-- 172.19.0.5 ---- logstash : 5044
                                |                      ^  (esa conexión la configuramos cómo: logstash:5044)
                                +-- 172.19.0.7 ---- filebeat

    En logstash para conectar con el coordinador1, podriamos usar como url: https://172.31.41.172:8080   
                                                                                ^
    Pero... eso funcionaría? Podría llegar a hacerlo.. pero hay un problemilla: S

    Qué ocurre con esas S? Logstash va a Validar el certificado que presente el coordinador1:
    - La identidad de del logstash (Autenticar al coordinador1) 
        Por su lado el logstash se autenticará mediante usuario / contraseña al elasticsearch: elastic/password
    - Para autenticar una identidad, lo primero que hace falta es conocer la identidad.
        En el certificaqdo viene :
            - LA IDENTIDAD DEL SERVIDOR: Yo soy este servidor
            - FORMA DE AUTENTICAR ESA IDENTIDAD: Firma generada por una CA
            - ID DE LA CA.
     
    El logstash lo primero que mirará será: La IDENTIDAD:
        En tu certificado que presentas viene el nombre: 172.31.41.172? SI
        En la firma de la CA viene también ese nombre? SI
        Confío en la CA que firma su identidad? A priori no... es autofirmado: La CA la hemos creado nosotros.
        Necesitamos configurar en Logstash la CA que firma el certificado de coordinador1 como CA de confianza.
     
Identificación          Yo dije : SOY IVAN
Autenticación           Validar que eres quien dices ser
Autorización

---

Nuestro fichero no llega a 2Kbs... y en el indice de elastic tenemos: 100.63kb
Hemos multiplicado por 50 (algo más)... pero cuidao...
Elasticsearch no sabe el nivel de redundancia física que tiene nuestro almacenamiento.
Si por debajo uso una cabina con RAID... multiplica eso por x2.5 x3: 300Kbs

    2 Kbs --> 300kbs ES UNA AUTENTICA LOCURA !
    
Y ojo! hemos tratado bastante el fichero... Le hemos quitado campos por un tubo!

---

URL: /api/v1/miEndPoint?param4=unValor&param2=OtroValor

miEndPoint
param2
PARAM2

Tokenizador, debería usar algo que parta por : / ? & =


# Plantilla de Índices (habrá que definirla)

Al definir una plantilla de indices, en esa plantilla incluiremos un campo index_patterns.
Ahí pondremos los patrones de los índices a los que se debe aplicar esta plantilla.

Plantilla: APACHE
    Y en ella digo que se aplique a todos los indices que se creen cuyo nombre comience por "apache-*"

Aquí puede ocurrir una cosa:
Podría tener varias plantillas que apliquen al mismo índice

Plantilla: Apache-Negocio
    index_patterns: apache-negocio-*
Plantilla: Apache-Sistemas
    index_patterns: apache-sistemas-*

Y al crear un índice cuyo nombre sea: "apache-sistemas-2024", qué plantilla o plantillas le aplciarían?
    Plantilla: Apache-Sistemas
    Plantilla: APACHE

Si tienen definiciones complementarias: SE APLICAN TODAS
Pero si tienen definiciones contradictorias, cuál se aplica? Ahí entra el concepto "priority"

Podría crear una plantilla directamente enb ElasticSearch haciendo un :
POST /_index_templates/NOMBRE_PLANTILLA
{JSON con la especificación de mappings y settings}