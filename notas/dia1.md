
# ElasticSearch

## ¿Qué es ElasticSearch?

√ Es un motor de indexación y búsqueda de información!!!! = Me permite montar algo así como GOOGLE (on prem)
√ No es una BBDD (Ni SQL ni NoSQL, ni de ningún otro tipo).
√ No es un repositorio documental (documentum, alfresco... eso si son repositorios documentales).

## Indexadores (como por ejemplo Google)

Google no es una BBDD, ni un repositorio documental, es un indexador. 
Google indexa páginas web... y permite buscar en ellas.
Las páginas web se almacenan en Google? NO... estarán en sus respectivos servidores WEB/Aplicaciones.
Google solo consulta esas páginas, las indexa y permite hacer búsqueda muy eficientes en ellas.
Una vez encontrado un dato, me redirige a la página original, alojada en el servidor original.

Con ElasticSearch podemos hacer algo similar, pero con nuestros propios datos.

Google, cuando indexa una página web, guarda una fotografía de la página en el momento de la indexación.
Antiguamente podíamos acceder a ella mediante la opción "Ver en caché" de Google.
Cuidado... en esa cache lo que hay es una foto de cuando Google indexó la página.
El problema es que esa foto puede estar desactualizada, con respecto a la página original.

    ----x-----------x-------------------x-------O-------> Tiempo
    Página v1                       Página v2
                Google indexa                   Búsqueda (*)
                 Cache: Página v1

Esa búsqueda (*) se hace sobre los datos indexados por Google, no sobre la página original. Es decir.. en mi caso sobre la foto de la página v1.

Y en este sentido un comentario... Hay datos, que por su naturaleza (o estado) sé que ya no van a cambiar.
Imaginad una entrada en un fichero de log... una vez escrita, no va a cambiar.
    > El día 17 de marzo de 2021 a las 12:00:00 se produjo un error en el sistema.
Imaginad una métrica que anoto de uso de cpu de un servidor... una vez anotada, no va a cambiar.
    > El servidor menganito, el día 17 de marzo de 2021 a las 12:00:00 tenía un uso de cpu del 80%.

Hay datos, que por su naturaleza son datos "muertos", que no van a cambiar. Y para esos datos, y solo para ese tipo de datos, la cache de Google/ES nos sirve como repositorio de datos (como una especie de BBDD clave/valor = REDIS).

De hecho, elasticsearch originalmente surge como un motor de indexación de documentos... de cualquier tipo, para ayudarnos a hacer búsquedas eficientes sobre ellos. Con el tiempo se empezó a usar como repositorio de registros (logs) y métricas. Es más... éste es su principal uso hoy en día.

## ¿Para qué leches necesito un indexador?

Las BBDD me permiten guardar datos, actualizarlos, eliminarlos... y también recuperarlos.
Pregunta: Son eficientes las BBDD en la recuperación de datos? Son hipereficientes... De hecho llevamos décadas y décadas usando BBDD. Aunque con sus estrategias...

### BBDD Relacionales

Imaginad que tengo mi BBDD con sus tablas... y voy cargando datos en ellas...
La carga de datos en una BBDD es muy eficiente a priori!
Lo único que tengo que hacer (a bajo nivel) es escribir una secuencia de bytes en el final (culo) del fichero de marras de la BBDD.
    > INSERT INTO tabla VALUES (1, 'pepe', 'perez');
    > INSERT INTO tabla VALUES (2, 'juan', 'garcia');

Vamos a crear la tabla recetas de cocina:

    | id    | receta                                   | tipo_de_plato     | tiempo    | dificultad |
    |-------|------------------------------------------|-------------------|-----------|------------|
    | 1     | Tortilla de patatas                      | Primer plato      | 30        | 1          |
    | 2     | Tortilla de patatas con cebolla          | Primer plato      | 30        | 1          |
    | 3     | Patatas guisadas con bacalao             | Segundo plato     | 60        | 2          |
    | 4     | Bacalao al pil pil                       | Segundo plato     | 45        | 3          |
    | 5     | Bacalao a la vizcaína                    | Segundo plato     | 45        | 3          |
    | 6     | Pulpo a la gallega                       | Segundo plato     | 60        | 2          |
    | 7     | Tarta de queso                           | Postre            | 60        | 1          |

El añadir un dato nuevo, lo único que hace es escribir una determinada secuencia de bytes al final del fichero de la BBDD.

### ¿qué pasa cuando quiero recuperar datos?

> select * form recetas where tipo_de_plato = 'Primer plato';

¿Cómo resuelve la BBDD Esa consulta?
A priori la BBDD hará un "FULL SCAN": Leer del principio al último todos los registros de la tabla recetas, y para cada uno de ellos, comprobar si el campo tipo_de_plato es igual a 'Primer plato'.

¿Eso es eficiente? Si tengo 10 datos puede.. si tengo 1M de datos.. agárrate!

Hay alguna forma (algoritmo de búsqueda) de poder hacer esa búsqueda de forma más eficiente?

#### ALGORITMO DE BÚSQUEDA BINARIA!

Es lo que llevamos haciendo desde que teníamos 8-10 años cada vez que buscamos palabras en un diccionario.

Busca "Elefante"
1. Parto el diccionario por la mitad 
2. Miro la palabra que hay en la mitad: "Membrillo"
3. Como "Elefante" estaría antes que "Membrillo", descarto todas las palabras de la segunda mitad del diccionario: Con una única operación me he cargado la mitad de las palabras.
4. Y sigo así...

Si tuviera 1.000.000 de registros sobre los que buscar:
Primera apertura del diccionario:  500.000 registros
Segunda apertura del diccionario:  250.000 registros
                                   125.000 registros
                                    62.500 registros
                                    31.250 registros
                                    15.625 registros
                                     7.812 registros
                                     3.906 registros
                                     1.953 registros
                                     1.000 registros
                                       500 registros
                                       250 registros
                                       125 registros
                                        62 registros
                                        31 registros
                                        15 registros
                                         7 registros
                                         3 registros
                                         1 registro

En unas 20 operaciones, he encontrado el registro que buscaba. Esto es al menos MUCHISIMO MAS EFICIENTE que un FULL SCAN... que sería leerme el diccionario de principio a fin.

Las BBDD prefieren hacer este tipo de búsquedas... frente a hacer un FULL SCAN.... eso si.. esto tiene truco.
Para poder usar este algoritmo de búsqueda hay una restricción que debe cumplirse: Los datos deben estar ordenados... DE ANTEMANO.

Digo de antemano... porque: ¿Qué tal se le da a un "ordenador" ordenar datos? COMO EL PUTO CULO!
De hecho los ordenadores no se llaman ordenadores por su capacidad de ordenar datos.. ni de lejos.
Los ordenadores (nombre heredado del francés "ordinateur") se llaman así por su capacidad de procesar órdenes (instrucciones).

Sería mucho más caro ordenar los datos y aplicar una búsqueda binaria, que hacer un FULL SCAN.
Otra cosa es si tengo los datos PREORDENADOS...ahí si que ni me lo pienso: Búsqueda binaria.

En un diccionario los datos se guardan preordenados... y por eso puedo hacer búsquedas binarias.
Pero en una BBDD los datos no se guardan preordenados... se guardan en el orden en el que los he ido insertando.

Pero el problema es más gordo aún... ya que guardar los datos preordenados... está bien... si solo me interesa buscar por un campo. Y si quiero buscar por varios campos? No es posible almacenar los datos ordenados por varias claves a la vez.

Ese problema lo resolvimos allá por la edad media con los índices.

## ¿Qué es un índice?

Un índice es una COPIA ordenada y unificada de los datos originales, junto con su ubicación real.
                                    ^ El mismo dato puede aparecer varias veces entre los datos originales.
                                      Pero en el índice solo aparecerá una vez... eso sí... aparecerá con varias ubicaciones.

Recuperemos la tabla recetas de cocina:

    | id    | receta                                   | tipo_de_plato     | tiempo    | dificultad |
    |-------|------------------------------------------|-------------------|-----------|------------|
    | 1     | Tortilla de patatas                      | Primer plato      | 30        | 1          |
    | 2     | Tortilla de patatas con cebolla          | Primer plato      | 30        | 1          |
    | 3     | Patatas guisadas con bacalao             | Segundo plato     | 60        | 2          |
    | 4     | Bacalao al pil pil                       | Segundo plato     | 45        | 3          |
    | 5     | Bacalao a la vizcaína                    | Segundo plato     | 45        | 3          |
    | 6     | Pulpo a la gallega                       | Segundo plato     | 60        | 2          |
    | 7     | Tarta de queso                           | Postre            | 60        | 1          |
    | 8     | Tortilla de patatas                      | Primer plato      | 30        | 1          |

Puedo crear un índice por tipo_de_plato:

    | tipo_de_plato     | ubicaciones(ids)       |
    |-------------------|------------------------|
    | Postre            | 7                      |
    | Primer plato      | 1, 2, 8                |
    | Segundo plato     | 3, 4, 5, 6             |

Puedo también crear un índice por dificultad:

    | dificultad        | ubicaciones(ids)       |
    |-------------------|------------------------|
    | 1                 | 1, 2, 7, 8             |
    | HUECO             |                        |
    | 1.5               | 9                      |
    | HUECO             |                        |
    | 2                 | 3, 6                   |
    | HUECO             |                        |
    | 3                 | 4, 5                   |
    | HUECO             |                        |

De cara a hacer una búsqueda: al tener los datos ordenados en el índice, puedo hacer búsquedas binarias.

CUIDADO... que esto tiene sus problemillas:
- Sin índices, cuando daba de alta un dato (una receta) lo único que hacía era escribirlo en el final del fichero de la BBDD.
  Con índices, cuando doy de alta un dato, tengo que:
    - Añadirlo al final del fichero de la BBDD
    - Añadirlo al índice de tipo_de_plato
    - Añadirlo al índice de dificultad
- Ahora... no solo eso... al guardarlo en el índice.. lo tengo que guardar en el sitio adecuado... EN EL INDICE LOS DATOS DEBEN IR ORDENADOS. Esto implica 2 cosas:
  - Identificar el sitio donde le toca ir (BUSCAR en el índice el sitio adecuado)
  - Poner perejil a San Pancracio para que allí haya hueco para escribir.
    - Y por eso:
       1. Cuando creo un índice en una BBDD, le configuro un PADDING FACTOR... el porcentaje de espacio que dejo libre en el índice para poder añadir nuevos datos. -> ESTO IMPLICA Que tengo un desperdicio de espacio en el HDD Enorme!
       2. De vez en cuando el índice se llena... y tengo que REORGANIZARLO... básicamente REESCRIBIRLO... y eso lleva tiempo! Y necesito alguien que se encargue de estas cosillas: DBA.
          Los índices requieren mantenimiento... y eso cuesta dinero. 

No solo las BBDD hacen estas cosas... Igual que los humanos al buscar en un diccionario... las BBDD no son tontas tampoco... por ejemplo:

> Si tengo que buscar en el diccionario ZAPATO, abro el diccionario por la mitad? NO... lo abriré por el final... porque se que ZAPATO estará hacia el final.

Las BBDD hacen lo mismo... Los primeros 1-3 cortes los pueden optimizar... y no hacerlos por la mitad... sino por un punto más adecuado.

Cómo sé yo que zapato está hacia el final?
1. Porque está ordenado
2. Porque conozco la distribución de las palabras en el diccionario: ESTADISTICA
3. Es decir, no solo sé que la A está antes que la Z. 
   También sé que la A tiene 10 veces más palabras que la Z
   Y que palabras que empiezan por W, X son muy pocas... casi entran en una página.

Las BBDD van aprendiendo (calculando) las ESTADISTICAS de los datos que guardan... y con ello pueden optimizar las búsquedas. Y esas estadísticas hay que irlas recalculando... y eso cuesta dinero. Otro trabajo de mantenimiento de la BBDD que hacen los DBA.

En esto las BBDD son una expertas... llevan más de 50 años perfeccionando estas técnicas.
Pocos programas son más eficientes que una BBDD en la recuperación de datos.

# ENTONCES... para qué leches necesito un indexador?

Recuperemos la tabla recetas de cocina:

    | id    | receta                                   | tipo_de_plato     | tiempo    | dificultad |
    |-------|------------------------------------------|-------------------|-----------|------------|
    | 1     | Tortilla de patatas                      | Primer plato      | 30        | 1          |
    | 2     | Tortilla de patatas con cebolla          | Primer plato      | 30        | 1          |
    | 3     | Patatas guisadas con bacalao             | Segundo plato     | 60        | 2          |
    | 4     | Bacalao al pil pil                       | Segundo plato     | 45        | 3          |
    | 5     | Bacalao a la vizcaína                    | Segundo plato     | 45        | 3          |
    | 6     | Pulpo a la gallega                       | Segundo plato     | 60        | 2          |
    | 7     | Tarta de queso                           | Postre            | 60        | 1          |
    | 8     | Tortilla de patatas                      | Primer plato      | 30        | 1          |


# ¿Qué pasa si quiero buscar todas las recetas de patata? = REGADA !

El hecho de tener uno de esos índices creado sobre la columna receta me aportaría algo de valor? ¿Mejoraría la eficiencia de la búsqueda? (Frente a hacer un FULL SCAN)

    | receta                             | ubicaciones(ids)       |
    |------------------------------------|------------------------|
    | Bacalao al pil pil                 | 4                      |
    | Bacalao a la vizcaína              | 5                      |
    | Patatas guisadas con bacalao       | 3                      |
    | Pulpo a la gallega                 | 6                      |
    | Tarta de queso                     | 7                      |
    | Tortilla de patatas                | 1, 8                   |
    | Tortilla de patatas con cebolla    | 2                      |

> QUIERO BUSCAR: "patata"

Me aporta algo el índice? Un poquito.
Necesito hacer un FULLSCAN en cualquier caso... e ir mirando registro a registro si la palabra "patata" aparece en la receta o no.
Eso si, podría hacer el fullscan sobre el índice... y no sobre la tabla original... y como ahí los datos están consolidados... la búsqueda sería más eficiente (en nuestro caso, 1 operación menos).
Justificará el gasto de Almacenamiento y tiempo de mis DBAs el tener ese índice? Probablemente no.
Mejorará mucho la eficiencia de la búsqueda? Probablemente en casi nada.
RUINA GORDA !!!!

Esa búsqueda es la que hacen muchas veces los desarrolladores con el MALDITO operador LIKE "%_lo_que_sea"
Ese índice me aporta si quiero hacer una búsqueda del tipo: LIKE "Tortilla%"? SI, MUCHO!

De hecho esto muchas veces se ve aún más sangrante: UPPER(receta) LIKE UPPER("%tortilla%"), y el índice de receta no sirve para nada.

Las BBDD son expertas en búsquedas sobre datos muy estructurados... pero en datos no estructurados... como texto... son una castaña!

Hay algunas BBDD (prepara billete... o sacrifica funcionalidad) que permiten hacer búsquedas de texto... 
- Oracle: Oracle Text               \
- SQL Server: Full Text Search      / Prepara billete
- PostgreSQL: Full Text Search      - No ofrece HA real (no se puede montar un cluster real activo-activo con PostgreSQL)

Y aún así están bastante limitadas en cuanto a funcionalidad específica de búsquedas de texto que ofrecen.

En estos casos, es cuando necesitamos un indexador.... y cada vez lidiamos con más y más datos no estructurados. Por eso cada vez se usan más indexadores.

¿Qué tal va a indexar ese tipo de cosas el ES? Realmente ES no indexa un pimiento.

ES, para la indexación usa una herramienta Opensource y gratuita llamada Lucene, que es un proyecto de Apache.

Una buena definición de lo que es ElasticSearch sería: Es un orquestador de Lucenes = SHARDs.

Un shard de ES es un Lucene... y ElasticSearch es solo un orquestador de Lucenes.

SOLR: Otro orquestador de Lucenes opensource y gratuito de Apache... un equivalente a ElasticSearch... eso si, con menos funcionalidades... y sin poder llamar a nadie cuando tienes un problema.

## Índices invertidos / inversos

Todas estas búsquedas más complejas, como las que hablábamos ahí arriba se resuelven bien mediante lo que se llama un índice invertido.... que son una extensión de los índices tradicionales que usan las BBDD, que se suelen llamar índices directos.

    | id    | receta                                   | tipo_de_plato     | tiempo    | dificultad |
    |-------|------------------------------------------|-------------------|-----------|------------|
    | 1     | Tortilla de patatas                      | Primer plato      | 30        | 1          |
    | 2     | Tortilla de patatas con cebolla          | Primer plato      | 30        | 1          |
    | 3     | Patatas guisadas con bacalao             | Segundo plato     | 60        | 2          |
    | 4     | Bacalao al pil pil                       | Segundo plato     | 45        | 3          |
    | 5     | Bacalao a la vizcaína                    | Segundo plato     | 45        | 3          |
    | 6     | Pulpo a la gallega                       | Segundo plato     | 60        | 2          |
    | 7     | Tarta de queso                           | Postre            | 60        | 1          |
    | 8     | Tortilla de patatas                      | Primer plato      | 30        | 1          |

Los índices invertidos en última instancia guardan lo mismo que un índice directo: Datos + ubicaciones.
La diferencia está en el DATO que guardan... que no es el dato original... sino un dato derivado del original.
De hecho crear estos índices implica un gran trabajo de preprocesado de los datos.

Nos llegan los datos:
- Tortilla de patatas
- Tortilla de patatas con cebolla
- Patatas guisadas con bacalao
- Bacalao al pil pil
- Bacalao a la vizcaína
- Pulpo a la gallega
- Torta de queso
- Tortilla de patatas

Al indexarse en un índice invertido haríamos lo siguiente:
1. Tokenización: Separar por tokens los textos (pueden ser palabras u otras cosas)
   - Tortilla de patatas                -> Tortilla-de-patatas
   - Tortilla de patatas con cebolla    -> Tortilla-de-patatas-con-cebolla
   - Patatas guisadas con bacalao       -> Patatas-guisadas-con-bacalao
   - Bacalao al pil pil                 -> Bacalao-al-pil-pil
   - Bacalao a la vizcaína              -> Bacalao-a-la-vizcaína
   - Pulpo a la gallega                 -> Pulpo-a-la-gallega
   - Torta de queso                     -> Torta-de-queso
   - Tortilla de patatas                -> Tortilla-de-patatas
2. Normalización: Trabajar con mayúsculas, minúsculas, acentos, etc.
   - Tortilla-de-patatas                -> tortilla-de-patatas
   - Tortilla-de-patatas-con-cebolla    -> tortilla-de-patatas-con-cebolla
   - Patatas-guisadas-con-bacalao       -> patatas-guisadas-con-bacalao
   - Bacalao-al-pil-pil                 -> bacalao-al-pil-pil
   - Bacalao-a-la-vizcaína              -> bacalao-a-la-vizcaina
   - Pulpo-a-la-gallega                 -> pulpo-a-la-gallega
   - Torta-de-queso                     -> torta-de-queso
   - Tortilla-de-patatas                -> tortilla-de-patatas
3. Eliminar stop-words: Palabras carentes de significado en el contexto de una búsqueda
   - tortilla-de-patatas                -> tortilla-*-patatas
   - tortilla-de-patatas-con-cebolla    -> tortilla-*-patatas-*-cebolla
   - patatas-guisadas-con-bacalao       -> patatas-guisadas-*-bacalao
   - bacalao-al-pil-pil                 -> bacalao-*-pil-pil
   - bacalao-a-la-vizcaína              -> bacalao-*-*-vizcaina
   - pulpo-a-la-gallega                 -> pulpo-*-*-gallega
   - torta-de-queso                     -> torta-*-queso
   - tortilla-de-patatas                -> tortilla-*-patatas
4. Steaming: Trabajar con la raíz de la palabra, quitar plurales, género, diminutivos, etc.
   - (1) tortilla-*-patatas                 -> tort-*-patat
   - (2) tortilla-*-patatas-*-cebolla       -> tort-*-patat-*-ceboll   
   - (3) patatas-guisadas-*-bacalao         -> patat-guisad-*-bacal
   - (4) bacalao-*-pil-pil                  -> bacal-*-pil-pil
   - (5) bacalao-*-*-vizcaina               -> bacal-*-*-vizcain
   - (6) pulpo-*-*-gallega                  -> pulp-*-*-galleg
   - (7) torta-*-queso                      -> tort-*-ques
   - (8) tortilla-*-patatas                 -> tort-*-patat
5. Indexación: Guardar los datos en el índice invertido

    | token         | ubicaciones(ids)       |
    |---------------|------------------------|
    | bacal         | 3(4), 4(1), 5(1)       |
    | galleg        | 6(4)                   |
    | guisad        | 3(2)                   |
    | ques          | 7(3)                   |
    | patat         | 1(3), 2(3), 3(1), 8(3) |
    | pil           | 4(3), 4(4)             |
    | pulp          | 6(1)                   |
    | tort          | 1(1), 2(1), 7(1), 8(1) |
    | vizcain       | 5(4)                   |

    ^^^ ESTE ES EL INDICE FINAL QUE ALMACENAMOS

A la hora de hacer una búsqueda: "patata"

Al término de búsqueda le aplicamos los mismos procedimientos que a los datos originales:
    "patata" ----> "patat"
Y esos elementos que queden después de ese procesamiento son los que buscaremos en el índice, entrando ahora si mediante una búsqueda binaria.

Este trabajo lo realiza LUCENE. Es una forma HIPEREFICIENTE de hacer búsquedas de texto.
Búsquedas que además nos darán muchos resultados: torta: -> torta de queso + tortillas de patatas.
En estas búsquedas tiene mucha importancia el poder ordenar los datos por RELEVANCIA.

REPITO: LA CANTIDAD DE TRABAJO QUE LLEVA EL PROCESAR LOS DATOS PREVIA INSERCIÓN EN EL INDICE INVERTIDO ES ENORME.

Esos índices invertidos al final hay que guardarlos en ficheros, igual que los índices directos.
Aquí es donde la cosa empieza a cambiar mucho con respecto a las BBDD tradicionales y a su gestión de índices.

En ES (en Lucene en realidad) no vamos a tener un fichero para el índice... con un montón de huecos libres... y que de vez en cuando haya que reescribir para tener espacio libre de nuevo cuando se llena.

En lugar de eso, Lucene va acumulando el resultado de el procesamiento de datos en memoria... y cada poco tiempo lo baja a disco.. y esos datos los añade al final de un fichero: FICHEROS QUE SE DENOMINAN FICHEROS DE SEGMENTO.

Un índice en un LUCENE (cuidado que ésto no es lo mismo que un índice en ES... y más adelante lo explicamos.)
es una colección de ficheros de segmento.

Esos ficheros, cuando llegan a un tamaño determinado, se cierran... y comienza a escribirse un nuevo fichero de segmento.
En un Lucene, para un índice, podemos acabar con 4000 ficheros de segmento... a la mínima.

En un fichero de segmento, podría encontrar cosas como:

```fichero_de_segmento
    --- Escritura 1, que incluye datos procesados durante un periodo de tiempo
    bacal: 3(4), 4(1)|
    guisad: 3(2) |
    patat: 1(3), 2(3), 3(1) |
    pil: 4(3), 4(4) |
    tort: 1(1), 2(1)
    --- Escritura 2, que incluye datos procesados durante el siguiente periodo de tiempo
    galleg: 6(4) |
    ques: 7(3) |
    patat: 8(3) |
    pulp: 6(1) |
    tort: 7(1), 8(1) |
    vizcain: 5(4)
```

Cuestiones con esos ficheros de segmento:
1. Al guardarse de esa forma, podemos hacer escrituras muy eficientes... 
   Añadir datos al índice sólo es añadir datos al final de un fichero.
2. Esos ficheros sirven para buscar directamente en ellos?    NO
   - Cada bloque escrito en el fichero de segmento está ordenado internamente.. pero no hay orden entre bloques.
   - Además, el token "patat" puede aparecer en varios bloques...
   - Es más... como iré teniendo muchos ficheros de segmento (recordad que al llegar a un tamaño máximo, se cierra fichero...y a por otro...), el token podría aparecer varias veces en varios ficheros de segmento.
3. Está optimizado el espacio de almacenamiento en esos ficheros? NO
   - No hay huecos libres... 
   - Pero... cuántas veces aparece cada token? montonón 

Entonces, cómo hace Elastic / Lucene las búsquedas?
- Siempre en RAM
- Los ficheros se usan SOLO y EXCLUSIVAMENTE para persistencia de datos.
- Se intenta tener el índice siempre en RAM... Si no se puede, será necesario leer los ficheros de segmento (TODOS y cada uno de ellos) y consolidarlos en RAM.
  Al final, en RAM, si que tengo una estructura UNIFICADA y ORDENADA de los datos.... pero eso es un procesamiento que se ejecuta (realiza) cada vez que tengo que leer los ficheros de segmento desde disco.
- Cualquier búsqueda SIEMPRE necesita que los datos estén consolidados en RAM.

Intentaremos que los índices que se usen frecuentemente estén en RAM... y que los que no se usen... pues no.

NOTA: Hay un tema que será importante en ES/Lucene.
Si tengo datos que sé que no van a cambiar... y tengo un índice donde sé que no se van a añadir datos nuevos...
podría optimizar esos ficheros de segmento. PERO SOLO EN ESE CASO.

Por ejemplo: Tengo un índice donde he guardado: MEDICIONES DE CPU DE MIS SERVIDORES DEL MES DE OCTUBRE...
Cuando llego a Noviembre... Voy a meter más datos en el índice anterior? NO
Y se podrán modificar esos datos de octubre? NO... los datos, por su naturaleza (EVENTOS PASADOS) son inmutables.
En un escenario como ese, me puede interesar (y me interesará!!!!) consolidar esos ficheros de segmento en uno o varios ... de forma que cada fichero contenga cada token una única vez... y solo tenga un bloque interno, con los datos totalmente ordenados.
De esa forma, si es necesario en algún momento releer esos datos desde disco... la lectura será mucho más eficiente.

Pero esto es algo que podré hacer a toro pasao!

Veremos que en ES, el concepto de INDICE es el equivalente en las BBDD relaciones al concepto de TABLA.
Pero... en cambio, en ES no tendré una única tabla de FACTURAS (como tendría en una BBDD relacional), sino que tendré una tabla de FACTURAS por cada mes (o semana, o día, u hora)... y según se cierre la unidad de tiempo con la que trabaje, solicitaré que se reconsoliden los ficheros de segmento de ese índice.

Un ES lleva un huevo de mantenimiento! Mucho más que una BBDD relacional.
Una ventaja es que podemos PROGRAMAR (automatizar) esos mantenimientos.

## Índices en ES

Lucene es una herramienta muy potente para hacer indexación y búsqueda de texto.
Pero... no es una herramienta apta para entornos de producción, al menos ella sola.

Cada dato que llega a ElasticSearch no se guarda solo en un Lucene... sino que se guarda en varios Lucenes...
De forma que si un Lucene deja de responder (se ha caído el proceso de Lucene, se ha roto un HDD, se ha roto un servidor) exista otro Lucene que pueda responder a las peticiones y que tenga los mismos datos que el Lucene caído.

    DatoA -> ElasticSearch ---> Máquina 1 ---> Lucene 1 ---> Indexa el DatoA
                           ---> Máquina 2 ---> Lucene 2 ---> Indexa el DatoA
                           ---> Máquina 3 ---> Lucene 3 ---> Indexa el DatoA

    De todos esos Lucenes, sólo 1 se usará para hacer las búsquedas (el PRIMARY)... los otros estarán en standby (REPLICAS)... esperando a que el Lucene principal falle para que en ese caso, uno de ellos cambie de modo (de réplica a principal) y pueda responder a las peticiones.

Cada Lucene en ElasticSearch recibe el nombre de SHARD... y tenemos SHARDs primarios y SHARDs de replicación.

Una cosa que podremos configurar en ES es el número de SHARDs de replicación que queremos tener de nuestros datos.
También podremos configurar de cúantos de esos shards de replicación necesito obtener el OK para dar por buena una escritura en el índice (una indexación).
    > Cuando llegue el DatoA, puedo pedirle a ES que tan pronto lo haya guardado en el PRIMARY, me de el OK.
    > O puedo pedirle que me de el OK cuando lo haya guardado en el PRIMARY y en otro de los SHARDs de replicación.
    > O puedo pedirle que me de el OK cuando lo haya guardado en el PRIMARY y todos los SHARDs de replicación.

Evidentemente, si espero a que el dato esté en todos los SHARDs de replicación:
- Tendré más garantías de que el dato no se pierda
- Pero la escritura en el índice será más lenta.

Esta forma de trabajo (el tener Shards Primarios y Shards de replicación) nos ofrece HA (High Availability).
Pero necesitamos un sistema que garantice ESCALABILIDAD cuando sea necesario!
Y aquí entra otro concepto.

Un INDICE en ElasticSearch es no un SHARD(Lucene) con sus réplicas... sino una colección de SHARDS (Lucenes), cada uno de ellos con sus réplicas.

    INDICE FACTURAS DE ENERO . ESTO A NIVEL DE ElasticSearch
        Y ElasticSearch, para ese índice, creará 10 shards primarios y quizás 20 shards de replicación.
            ESTO SERÁ ALGO que yo configure en ElasticSearch ( a nivel de cada índice )
        Cuando llegue un dato nuevo a ElasticSearch para su indexación en ese INDICE de ElasticSearch,
        lo primero que ocurrirá es que ElastiocSearch (el nodo maestro de ES) debe decidir en cuál de los 10 shards que se han configurado para ese índice se va a guardar el dato... 
        Una vez elegido uno de esos 10 shards para que se encargue del dato (un Lucene al final), Elastic solicita a ese Lucene y a sus réplicas la indexación del dato.

    > INDICE FACTURAS DE ENERO ( 5 shards y 2 réplicas por shard):
        S0 + S0R0 + S0R1
        S1 + S1R0 + S1R1        Cuando un dato llega para su indexación en un determinado INDICE:
        S2 + S2R0 + S2R1            Yo como desarrollador le digo a ElasticSearch: 
        S3 + S3R0 + S3R1            "Guárdame este dato en el INDICE FACTURAS DE ENERO"
        S4 + S4R0 + S4R1        Un nodo (maestro) decidirá en que Shard del INDICE FACTURAS DE ENERO 
                                    se guardará el dato: S4.. Y entonces ESearch le pedirá a S4 y a sus réplicas que guarden el dato.
                                Más adelante os ensañeré que puedo (y en según que casos quiero)
                                    influir en la decisión de en qué shard se guarda el dato:
                                        ALGORITMOS DE ROUTING de ElasticSearch
                                    Por adelantar un poco...
                                        - Hay veces que quiero maximizar el reparto de trabajo entre los shards: Reparto aleatorio
                                        - Hay veces que me puede interesar que todas las facturas de un mismo cliente se guarden en el mismo shard: Reparto por cliente
                                          Ya que cuando luego haga una búsqueda por cliente (y a lo mejor he identificado que el 90% de las búsquedas serán por cliente), solo tendré que buscar en un shard. 

        En total 15 Lucenes (Shards) para ese índice.

        Eso me garantiza 5 veces más capacidad de indexación que si tuviera un único SHARD PRIMARIO.

        El número de shards primarios me ofrece ESCALABILIDAD.
        El número de shards de replicación me ofrece HA.

        Y el número de shards de replicación es algo que puedo cambiar en caliente... y que puedo cambiar para cada índice.

        En cambio, el número de shards primarios es algo que no puedo cambiar (ni en caliente ni en frío) una vez establecido... CUIDADO CON ESTO!
            Si podré dividir los shards primarios:  Tengo 5... y cada uno lo quiero ahora dividir en 2 -> 10 shards primarios.
            También podré unir shards primarios: Tengo 10... y quiero pasar a 5 shards primarios.
            Pero esos números deben ser múltiplos de los shards primarios actuales.
                5x3 = 15 shards primarios
                15/3 = 5 shards primarios
                Pero no puedo decir cosas como: Tengo 5 y ahora quiero 7 shards primarios.
                    NO CUELA !!!

    Estas operaciones de arriba ^^^^^ van más orientadas al mantenimiento del INDICE en su ciclo de vida.
    Antes os ponía un ejemplo de un índice que transcurrido un periodo de tiempo no iba a recibir más datos... y que por tanto podía ser optimizado.
    Pero... si no va a recibir más datos... necesito tenerlo dividido en muchos shards?
    - Puede que si ...
    - Puede que no...
    Depende de la cantidad de búsquedas que se hagan sobre ese índice.
    Antes, el número de shards dependía de la capacidad de indexación... ahora dependerá de la capacidad de búsqueda.

Imaginad un caso donde tengo un índice con 1 único shard primario... y 2 réplicas.
En un momento un shard (primario o répica) muere (he perdido conexión de red).
Si el que se ha muerto es el primario, elasticsarch activará uno de los réplicas. Si se ha perdido una réplica, el primario sigue siendo el mismo... Pero en cualquier caso... acabo de entrar en ZONA DE PELIGRO.
Solo me queda 1 shard de réplica... como ese caiga... estoy jugando con FUEGO.

En esa situación (he perdido conexión con un shard de los 3 totales), Quiero que ES comience a hacer una copia de los datos a otro servidor, para así tener de nuevo en total 3 shards (1 primario y 2 réplicas) o no?
- Si no lo hago, estoy en riesgo
- Como lo haga, se me cae el cluster entero! EIN!????!!
  - Imagina que la máquina que tenía ese shard no se ha roto ni nada.. solo que he tenido un pico de red(mucho trabajo...). El lucene cuando intento contactar con él no responde.. no es que no responda... es que quizás AUN no le ha llegado la solicitud de estado (PING)...
    Y yo valiente de mi... lo único que se me ocurre es ponerme a copiar por RED los 3 Gbs de datos que tenía en ese Lucene a otra máquina... QUE ACABO DE HACER? AGRAVAR EL PROBLEMA un huevo!

Con estas cosas hay que tener MUCHO CUIDADO. De hecho, ElasticSearch lo primero que me pide es que introduzca el tiempo que quiero que pase antes de que esto ocurra... y normalmente será una FUNCIONALIDAD QUE TENDRÉ DESACTIVADA. No quiero que haga eso en NINGUN CASO !

    Motivación:
    - Si tengo un cluster de 100 nodos, y se me cae un nodo... no quiero que se me caiga el cluster entero por un pico de red. Para qué quiero shards de replicación? HA
      El problema puede venir de:
        - HDD roto (He perdido datos en una máquina y necesito llevarlos a otra)
          En este caso quiero que se copien datos de un sitio a otro? Tampoco... ESTO NO OCURRE EN LA PRACTICA EN LA VIDA!
            Elastic es Elastic... pero elastic corre sobre mi infraestructura.
            Los datos los tendré almacenados en un CABINA DE ALMACENAMIENTO... volumen en un cloud (que tendrá su redundancia)... o en un NAS (que tendrá su redundancia = RAID).
            Los datos (a no se que trabaje con una infra hiperconvergente.. y eso es poco habitual, en ES: donde las instalaciones principalmente se hacen en Kubernetes) los tendré en un almacenamiento EXTERNO, que tendrá su redundancia.
            Los datos no se van a perder.
        - Máquina ROTA (sin hdd roto) o red congestionada (no puedo acceder a los datos)
          En el mundo Kubernetes, esto implica que un POD se ha caído... y querré que Kubernetes levante otro pod en otro servidor... al que le enchufaré el MISMO 
          En este caso quiero que se copien datos de un sitio a otro? Posiblemente NO 

---

# Operativa con ES

ElasticSearch es una herramienta que solo ofrece un API HTTP Rest para interactuar con ella.

    Petición http -> ElasticSearch -> contestar por HTTP... con un JSON
        cargar documento
        crear índice
        buscar documentos

Todos los documentos que puede indexar ElasticSearch deben ser documentos JSON.

Yo le mando un JSON para que indexe.. y luego le pido que busque documentos... y me devuelve otro JSON con los resultados.

Lo que pasa es que no es una herramienta que trabaje de forma aislada, la usaremos en combinación con otras herramientas.

    Carga de datos ----->                 <------- Explotación de datos
                            Cluster de ES 
                             (4-N nodos)

     App ad-hoc                                     App ah-doc (ES le invocamos por http)
                                                                Ofrece librerías para distintos lenguajes de programación
     Logstash                                       Kibana
     Agentes beats                                              Ofrece una interfaz gráfica genérica para 
                                                                interactuar con ES:
                                                                    - Gestionar índices y su ciclo de vida
                                                                    - Utilidades para el desarrollo
                                                                    - Monitorización del cluster de ES
                                                                    - Formularios de búsqueda de daocumentos
                                                                    - Cuadros de mando (personalizables)
                                                                      para ver agregados de datos en tiempo real
                                                                    - Generar informes impresos de agregados de datos
                                                                    - Crear alertas (email, slack, etc) cuando se produzcan eventos 
                                                                    - Monitorizar infraestructura (no solo ES)
                                                                    - Hacer seguimiento de logs de aplicaciones

### Logstash

Es una herramienta especialmente diseñada para la carga de datos en ElasticSearch.
Tiene 2 usos principales... 
    - Recepción, procesamiento y envío de datos a ElasticSearch
    - Enrutamiento de datos a distintos destinos (normalmente a otro Logstash)

### Agentes Beats

Antiguamente teníamos muchos agentes beats:
- Filebeat: Para leer datos de ficheros y mandarlos a un LOGSTASH o un elasticsearch (esto no se hace)
            Un sustituto viable es FluentD
- Metricbeat: Para leer datos de métricas de un sistema y mandarlos a un LOGSTASH o un elasticsearch (esto no se hace)
- Auditbeat: Para leer datos de auditoría de un sistemas LINUX y mandarlos a un LOGSTASH o un elasticsearch (esto no se hace)
- Winlogbeat: Para leer datos de logs de Windows y mandarlos a un LOGSTASH o un elasticsearch (esto no se hace)
- Packetbeat: Para leer datos de tráfico de red y mandarlos a un LOGSTASH o un elasticsearch (esto no se hace)

Hoy en día hay una herramienta llamada AgentBeat que engloba a todos estos agentes... puedo seguir instalando los agentes por separado... pero lo normal es instalar el AgentBeat y luego instalar los módulos que necesite.

### Arquitectura normal al trabajr con un ES


            Aquí voy dejando datos
                para su procesamiento e 
                indexación en ES
                   v
 Agentes Beats > Kafka <  Logstash   >      Logstash 1     >    CLUSTER ES 1   <    Kibana
                          de enrutamiento   Logstash 2     >      (monitorización-sistemas)
 App custom    >              
                                                                De una app, en este otro cluster quizás lo 
                                                                que quiero son las operaciones que no se han efectuado (ERROR)

                                     >      Logstash 3     >    CLUSTER ES 2   <    Kibana
                                                                                 (negocio)
                                                                De una app, en este cluster quiero las operaciones de negocio que se hayan efectuado
                                                                               <    App custom de negocio

                 --------------------------------------------------------------------------------------------
                                                                       KUBERNETES               
   -------------
      Depende


La gente de Elastic me ofrece archivos de despliegue de todas sus apps para kubernetes.
Antes se tiraba más por el lado de Charts de Helm
Hoy en día, lo que ofrecen es un operador de kubernetes que se encarga de desplegar y mantener los recursos de kubernetes necesarios para que funcione ElasticSearch.

En elastic (empresa) se suele hablar del stack ELK (ElasticSearch, Logstash, Kibana)
---

# Roles de los nodos de ES

ElasticSearch es un sistema DISTRIBUIDO, es decir, que además de permitirme tener un cluster, cada elemento del cluster puede ejecutar un tipo de tarea diferente al del resto de los nodos del cluster.

Un tipo de nodo (ROLE) es el de MAESTRO.
El nodo de tipo maestro es el que se encarga de:
- Establecer en que nodo se guardará cada SHARD
- Establecer en que Shard se guardará cada dato
- Mover shards de un nodo a otro
- ... y otras tareas de coordinación del cluster.

En ES luego hablaremos que al menos necesitamos 3 nodos de tipo maestro para funcionar.

Otro tipo de nodo que tendremos en u ncluster será el tipo DATA.
Los nodos de tipo DATA se encargan de ejecutar LUCENES.
Y en un nodo de tipo data, puedo tener 500 Lucenes en ejecución!
Cada uno de esos Lucenes será un Shard primario o de replica.

## Tipos de nodos en ElasticSearch

En clusters pequeños... es habitual que un nodo asuma varios roles.
En un cluster más grande lo que me interesa es que cada nodo asuma un único rol (más o menos).

De hecho lo complejo es en el mundo de ES encontrar clusters pequeños.

### Nodos tipo maestro

Solo hay un nodo con el rol maestro activo en un cluster. 
Se encarga de :
- Monitorizar el cluster (si un nodo cae, si hay unodo nuevo...)
- Coordinar la asignación de shards (ejecutar los algoritmos de routing)
- Coordinar la asignación de réplicas
- Mover/copiar shards de un nodo a otro

En un cluster al menos necesito tener configurados 3 nodos de tipo maestro.... de los cuales SOLO 1 tendrá el rol de maestro activo. ES No me deja montar un cluster con 2 nodos maestros.
                       Con 1 si... para jugar.
Claro.. esto es un desperdicio de infraestructura... de los 3 solo usaré 1 a la vez. Eso si.. la HA es cara.
No obstante en ES hay un truco para intentar abaratar la infra... 
    El truco es configurar solamente 2 nodos maestros efectivos... Y a un nodo de otro tipo, ponerle el rol de "maestro de mentirijilla". Normalmente esto se hace con un nodo de tipo DATA (que es obligatorio en un cluster ES).

De entrada, la limitación de al menos 3 nodos maestros es necesaria para evitar un fenómeno llamado BRAIN SPLITING.


    +- *Nodo 1 maestro de ES* ----|
    |                             |
    +-- Nodo 2 maestro de ES -----|
                                  | 
    +-  Nodo 3 maestro de ES  ----|
    |                             | red pública (IP:9200) < CLIENTES
    |
    red interna del cluster (IP:9300)

    Podría pasar que en un momento dado, el Nodo 3 pierda conexión de red con el resto de nodos del cluster.
    Imaginemos que antes de ese momento, el nodo que estaba seleccionado como maestro activo era el Nodo 1.

    A efectos del nodo 1 y del nodo2, el nodo 3 ya no está disponible... No pasa nada... dejamos de mandarle cosas. El nodo 1 sigue siendo el maestro activo.

    El problema es que a efectos del nodo 3, el nodo 1 y el nodo 2 ya no están disponibles... y el nodo 3 se autoproclama maestro activo. El nodo 3 podría seguir recibiendo peticiones de clientes externos.. y empieza a guardar sus propios datos.. con sus identificadores... mientars nodo1/nodo2 van haciendo lo propio en paralelo: YA NO TENGO 1 cluster... tengo 2 clusters (Nodo1/Nodo2 y Nodo3).
    Y esos clusters son IRRECONCILIABLES... no puedo hacer que vuelvan a ser 1.
    Este problema se llama BRAIN SPLITING.

    Para evitarlo, muchas herramienats de almacenamiento de datos optan por requerir un número impar de nodos maestros, de forma que para determinar quién es el nodo maestro, un nodo deba recibir aprobación al menos de la mitad +1 de los nodos maestros.

    Con esa forma establecida, aunque el nodo 3 quede aislado, nunca podría proclaimarse maestro activo... ya que no tiene el apoyo de la mitad +1 de los nodos maestros, evitando el problema del BRAIN SPLITING.

El truco que os decía es configurar un nodo DATA como maestro que no puede ejercer como maestro (maestro de mentirijilla)... lo único que puede hacer es votar para la elección del maestro activo.
Esto nos permite ahorrar un nodo de tipo maestro en el cluster.

Estos nodos no requieren mucha RAM, ni almacenamiento (no van a guardar datos). Si que deben tener un buen procesador... ya que son los que van a hacer el trabajo de coordinación del cluster.

### Nodos tipo DATA

Estos son los que ejecutan los lucenes (los que albergan los shards, tanto primarios como de réplica).
Necesitan un huevo de:
- RAM : Son los que buscaran en los indices que cree el Lucene... y ya hemos dicho que necesito que el SHARD entero entre en RAM... y se matenga... sino vaya follón... todo el rato leyendo / cargando y liberando shards del disco a la RAM.
- CPU : Son los que van a ejecutar los trabajos de indexación y búsqueda.
- ALMACENAMIENTO : Necesitaré un huevo de almacenamiento.
  Hemos dicho que el almacenamiento esa CARO y un ES genera/guarda datos por un tubo... Gbs y Gbs... Tbs y Tbs

  Eso si.. no es lo mismo los datos que he metido en las últimas 24 horas, que los datos que metí hace 3 años.
  Los datos que metí hace 3 años... 
  - Los voy a modificar mucho? NO
  - Los voy a usar mucho en búsquedas? Mucho menos que los datos de hace 24 horas

    Para abaratar costes de almacenamiento, ES define hasta 5 tipos de nodos de tipo DATA:
    - Content: Nodos que almacenan los datos más recientes... los que más se usan en búsquedas
    - Hot: Nodos que almacenan datos  recientes... que se usan mucho en búsquedas
    - Warm: Nodos que almacenan los datos que ya no son tan recientes... los que se usan menos en búsquedas
    - Cold: Nodos que almacenan los datos que ya no son recientes... los que se usan muy poco en búsquedas
    - Frozen: Nodos que almacenan los datos que ya no son recientes... los que no se usan en búsquedas

    La idea es que pueda tener nodos con distintos tipos de volumenes de almacenamiento:
    - En nodos content: NVMe con cache en ram
    - En nodos FRONZEN: Discos de 5400 rpm
  Veremos que en las políticas de ciclo de vida de los índices, podremos definir que un índice se mueva de un tipo de nodo a otro según vaya envejeciendo.   

Al menos necesito 2 nodos data en un cluster ES... para tener un mínimo (mínimo de HA).
ES no me permite montar el mismo número de SHARD 2 veces en la misma máquina (nodo).

    INDICE A (4 primarios x 2 replicas cada uno = 12 shards)
                S0 + S0R0 + S0R1
                S1 + S1R0 + S1R1
                S2 + S2R0 + S2R1
                S3 + S3R0 + S3R1
                Nodo1  
                     Nodo2
                            Nodo3

    Cuántos nodos data necesita mi cluster al menos?  3

    Opcion 1 Potencial    
        Nodo1   S0      S1      S2      S3
        Nodo2   S0R0    S1R0    S2R0    S3R0
        Nodo3   S0R1    S1R1    S2R1    S3R1

    Opcion 2 Potencial
        Nodo1   S0R0    S1R1      S2      S3
        Nodo2   S0      S1R0    S2R0    S3R1
        Nodo3   S0R1    S1      S2R1    S3R0

Con 2 datas solo podría tener 1 replica de cada shard... además de la primaria.... VOY UN POCO PELAO !

El mínimo de un cluster de ES sería:
    2 maestros
    2 data (uno de ellos configurado como maestro de mentirijilla)
    ----------
    4 nodos

Más chapucera podría ser 3 maestros y data a la vez.
El problema de una configuración como esta que si empieza a asumir un poco de carga de trabajo.. y me llegan un pico de documentos y saturan al que hace de maestro, el cluster entero se cae.
NUNCA DEBERIAMOS en un entorno de HA/Producción juntar el role MASTER con el ROL DATA.


---


Pte qué pasa con las eliminaciones y actualizaciones de datos en un índice invertido.

Ya hemos dicho que ES no es una BBDD al uso... no está pensada para hacer CRUD.
---

# Lo del almacenamiento es barato o caro hoy en día?

En un entorno de producción es de lo más caro que hay.
Lo primero, elijo discos de más calidad... mucho más caros.
En un entorno de producción, cuantas copias coy a hacer de cada dato? Al menos 3. -> Alta disponibilidad.
Pero no solo eso.. luego vendrán los backups...                                   -> Disaster Recovery.
con lo que al final para conseguir 1Tb de almacenamiento, necesito 6-10Tb de almacenamiento CARO... no del que compro en casa.

EL DATO ES LO MÁS VALIOSO QUE HAY.
Vosotros sois un gasto para la empresa
Yo, más gasto que vosotros
El Hardware, gasto!
Los programas, gasto!
Los desarrolladores, gasto!

Todo eso solo se justifica en tanto en cuando tengamos un sistema capaz de gestionar DATOS que aporten valor a la empresa.
No puedo perder el dato por nada del mundo!

---

# Entornos de producción:

- Alta disponibilidad (Ser resiliente a fallos)
    Se puede romper un HDD, un servidor, un rack, algún componente de mi infraestructura... y el sistema debe seguir funcionando... o al menos debo intentar que siga funcionando.

    La forma que tenemos de conseguir esa HA (High Availability) es mediante una técnica llamada REDUNDANCIA.

    Querré:
    - Servidores redundantes
    - Discos redundantes
    - Que los datos se guarden en varios sitios

- Escalabilidad
    Tener capacidad para ir cargando más y más datos en el sistema... sin una caída en el rendimiento. 