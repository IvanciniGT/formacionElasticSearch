# Contenedor

Entorno aislado dentro de un kernel Linux donde ir corriendo procesos:
- Tiene su propio sistema de archivos
- Tiene sus propias variables de entorno
- Tiene su propia configuración de red
- Puede tener limitaciones de acceso al los recursos hardware


Es una alternativa a las máquinas virtuales para ejecutar software.

Igual que podemos crear una VM desde una imagen iso.
Podemos crear un contenedor desde una imagen de contenedor.
Las imágenes de contenedor, al no llevar SO, son muchísimo más ligeras que las de las VMs.

Dentro de las imágenes vienen programas YA INSTALADOS DE ANTEMANO POR ALGUIEN (Fabricante).

Gestores de contenedores hay muchos: Docker, Podman, Crio, ContainerD.


# Elastic:

    https://IP:8080
    
# Kibana:

    http://IP:8081

---

# Memoria en JVM

Lo primero a tener en cuenta: ES UNA MAQUINA VIRTUAL donde corre el ES (la de java), a su vez ejecutándose en un contenedor.

La máquina virtual de Java lleva su configuración de memoria:
- Inicial \ 
- Máximo  / Estos 2 valores deben ser iguales (1)

Pero una cosa es lo que reserve para la JVM a nivel de host... y otra lo que esté en uso por el ES.

De entrada la RAM de la JVM se divide en varios tipos:
- Perm              Código del ES
- ThreadStack       Lo que usamos para anotar lo que está en ejecución en un momento dado
- Heap              La que se usa y está disponible para datos (para nuestro ES)... rondará un 90% de la total de la JVM
    - Ese heap es el que puede ir tomando poco a poco... o todo de golpe (1)

```java

String texto = "hola" ; // Asignar el valor "hola" a la variable "texto".
                        // Esta linea hace justo lo contrario.
                        // Asignar la variable "texto" al valor "hola".

    // 1. "hola"        Crear en RAM un objeto de tipo String, con valor "hola"
                        // Podemos imaginar la RAM como un cuaderno de cuadrícula.
    // 2. String texto  Crear una variable con nombre "texto", que puede referencia a objetos de tipo String.
                        // Podemos imagina una variable como un postit. En nuestro caso, uno verde (que son los que pueden apuntar a textos).
                        // En el postit lo que escribo es "texto"... no "hola"
    // 3. =             Apuntar al objeto "hola" que está en RAM (en algún sitio... npi de donde) desde mi variable.

texto = "adios";
    // 1. "adios"       Crear en RAM un objeto de tipo String, con valor "adios"
                        // Dónde se crea? En el mismo sitio donde estaba "hola" o en otro? En JAVA, en otro (en C, sería en el mismo)
                        // En este momento tenemos en RAM 2 objetos de tipo String: "hola" y "adios"
    // 2. texto =       Despegar el postit de donde estaba pegao.. y pegarlo al lado del "adios"
                        // En este momento, el valor "hola" queda "huerfano de postit".. Ninguna variable le apunta.
                        // Y en Java ese dato es IRRECUPERABLE. Ese dato queda marcado por tanto como BASURA: GARBAGE
                        // Eso si.. ocupando espacio en RAM.
                        // En JAVA (dentro de la JVM) de vez en cuendo entra un proceso en segundo plano llamado el 
                        // RECOLECTOR DE BASURA: GC o Garbage Collector. En JS o en Python también hay GC.
```

El mismo programa hecho en JAVA o hecho en C, en Java necesitará el doble de ram para funcionar adecuadamente.
Esto fué un requisito de diseño de JAVA: Vamos a crear un lenguaje que gestione como el culo la RAM.
Java gestiona la RAM.. de aquella forma. A cambio un desarrollo en JAVA es mucho más sencillo que el mismo desarrollo en C o en C++.
El criterio es, qué me sale más barato:
- Meterle 2 pastillas de RAM a un servidor (JAVA)
- O 100 horas más de desarrollo (de un desarrollador más caro) para hacer el mismo programa en C++.


Cuado miramos la RAM dentro de la MAQUINA VIRTUAL DE JAVA (JVM) vamos a ver una especie de hoja de sierra... con picos.
Los picos será cuando tengo basura en RAM.. Según la voy acumulando
Los valles... cuando entra el GC y elimina la basura y libera memoria.

Eso es la forma NORMAL de trabajo en JAVA con la RAM.

Si veo en una gráfica de memoria de JAVA:
- Una linea recta:
    - Si está muy abajo: El sistema no se está usando
    - Si está muy arriba: LA HEMOS LIAO... nos hemos comido toda la RAM (HEAP) y no estamos dejando hueco para la basura (que en java debe existir ese hueco)
- Dientes de sierra:
    - Si los picos se separan entre en más de 2 segundos: GUAY!
    - Si los picos están mucho más próximos: PROBLEMOS... El GC está entrando con demasiada frecuencia, por no haber suficientes espacio para basura.
      Problema gordo de rendimiento.   

En el HEAP de Java, veremos el 
- OLD       Debería de ser Cache (y debería de haber POCO MOVIMIENTO)
- YOUNG     Es lo que se usa para datos de trabajo ( y tendrá mucho movimiento). Esto es lo que continuamente tiro a la basura.



## CUIDADO

En JAVA (JS, PYTHON) una variable no es una cajita donde pongo cosas... y luego las saco.
    Eso sería una definición aceptable para el concepto de VARIABLE en un lenguaje de programación como C, C++, C#, Fortran, ADA...
    
En JAVA una variable tiene más que ver con el concepto en C de PUNTERO.
Una variable en JAVA es una referencia a un dato que tengo en RAM.

---

# CPU

No quiero que pase de un determinado % de uso... 
- Si llega al 100% problemon.. HE SATURADO LA MAQUINA = PROBLEMAS DE RENDIMIENTO
- Si llega al 55%... depende... tengo que mirar H.A. y echar cuentas.

    NODO 1  70%     PROBLEMON . Si uno cae, se cae el cluster entero... las 2 que quedan no tienen CPU suficiente para asumir toda la carga.
    NODO 2  70%
    NODO 3  70%


---
servidores_sqlserver-2024-enero                 servidores_windows_2024-enero
servidores_sqlserver-2024-febrero               servidores_windows_2024-febrero
servidores_active_directory-2024-enero          servidores_windows_2024-enero
servidores_active_directory-2024-febrero        servidores_windows_2024-febrero

servidores_sqlserver-2024-*
servidores_active_directory-2024-*
servidores_windows_2024-febrero
servidores_windows_2024-*

---
                                                                MEMORIA
2 Nodos maestros                                                1 x 2 = 2
    maestro1
    maestro2
3 Nodos de datos                                                2 x 3 = 6
 ( 1 de ellos con votación)
    datos1
 ( 2 de ellos de machine learning)
    En un entorno de pro... me plantearía muy mucho si ese role de ml me lo llevo a otros nodos
    datos2
    datos3
2 Nodos Coordinadores < EXPONEMOS                               1 x 2 = 2
    coordinador1
    coordinador2
    
Kibana --> coordinador1, coordinador2
 

8 nodos


---

Todo nodo por defecto es coordinador... puede hacer ese trabajo...
No es algo que pueda activar o desactivar.
Cuando creo nodos de coordinación, realmente lo que hago es coger nodos y despojarles del resto de actividades
  para que solo les quede coordinar.