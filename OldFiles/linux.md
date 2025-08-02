# ¿ Que es Linux ?
Linux es el nombre que reciben una serie de sistemas operativos de tipo Unix bajo la licencia GNU GPL (General Public License o Licencia Pública General de GNU) que son su mayoría gratuitos y con todo lo necesario para hacer funcionar un PC, con la peculiaridad de que podemos instalar un sistema muy ligero e ir añadiendo todo lo necesario posteriormente o según lo vayamos necesitando.

Es multiusuario, multitarea y multiplataforma, además puede funcionar en modo consola para un consumo mínimo de recursos, pero que también podemos hacer funcionar con entorno gráfico instalando uno mediante comandos de terminal o adquiriendo un paquete en el que venga uno incluido.

# ¿ Para que sirve ?

Linux sirve para hacer funcionar todo el hardware de un PC, ya que un ordenador no puede funcionar sin un sistema operativo y Linux es un sistema operativo gratuito. Linux está en muchos de los ordenadores que se venden sin sistema operativo, pero esto no es legal en España ya que un PC sin sistema operativo no es un PC funcional, muchos fabricantes optan por añadir una versión o distro de Linux.

Este sistema operativo también es conocido por controlar superordenadores o servidores que es donde en realidad Linux toma importancia. La mayoría de los supercomputadores más importantes del mundo usan algún sistema GNU/Linux, por lo que también sirve para controlar superordenadores con tareas específicas, gracias a su capacidad de personalización.

# Distribuciones 

Aunque existen más de 450 distribuciones Linux, como bien se demuestra en la Linux timeline la gran mayoría nace desde una «distribución madre», una distribución de propósito general que en un día fue un proyecto original y disponibiliza una amplia variedad de paquetes de Software Libre y de código cerrado:

-  **[Debian](https://www.debian.org/index.es.html)**
-  **[Gentoo](https://www.gentoo.org/)**
-  **[Slackware](http://www.slackware.com/)**
-  **[Arch](https://archlinux.org/)**
-  **[Red Hat](https://www.redhat.com)**

# Paquetes en linux

Salvando distancias, un paquete en Linux consiste en una colección de archivos que permiten la instalación de un programa y sus tareas relacionadas, como la búsqueda de dependencias, instalaciones previas, etc.

La razón de distribuir software en base a paquetes es simple. Cuando hablamos de GNU/Linux nos referimos a un ecosistema muy amplio de distribuciones que cuentan con notables diferencias entre sí. Esto hace que no sea posible “garantizar” que un software funcione correctamente en una computadora determinada. El uso de paquetes resuelve este problema de interoperabilidad gracias al pequeño archivo que antes mencionamos con metadatos que actúa como un manifiesto de dependencias que deben cumplirse para que el software empaquetado se ejecute correctamente en un ordenador determinado.

# Qué es un gestor de paquetes en Linux
El uso de paquetes nos ahorra muchos dolores de cabeza a la hora de instalar o mantener nuevo software, pero en ocasiones el número de pasos que debemos dar puede consumirnos demasiado tiempo, sobre todo cuando tenemos que instalar varios programas. Para esto tenemos los gestores de paquetes. Se tratan de utilidades presentes en cada distribución que se encarga de automatizar el proceso, también listan otros paquetes disponibles en el repositorio y muestran información sobre sus dependencias. Existen muchos, pero en general realizan la misma función básica de instalar y administrar nuevos programas, pero cada uno usa una arquitectura interna ligeramente diferente y diferentes interfaces de usuario para realizar las tareas centrales del administrador de paquetes.

Los sistemas comunes de administración de paquetes incluyen:


- __Apt-get__: _una interfaz que hace más amigable y añade funciones para el sistema DPKG, que se encuentra en las distribuciones basadas en Debian._
- __DPKG__: _el administrador de paquetes base para distribuciones basadas en Debian._
- __Aptitude__: _Aptitude es una interfaz para APT para distribuciones basadas en Debian. Muestra una lista de paquetes de software y permite al usuario elegir de modo interactivo cuáles desea instalar o eliminar._
- __Synaptic__: _Synaptic es instalado por defecto en Debian en la versión de escritorio, es una herramienta gráfica para la gestión de paquetes basada en GTK+ y APT._
- __RPM__: _el administrador de paquetes base que se encuentra en las distribuciones basadas en Red Hat, como Red Hat Enterprise Linux, CentOS y Fedora._
-  __Yum__: _un front-end para el sistema RPM, que se encuentra en las distribuciones basadas en Red Hat._
-  __Dnf__: _una interfaz más rica en funciones para el sistema RPM._
-  __ZYpp__: _se encuentra en SUSE y OpenSUSE._
-  __Pacman__: _el administrador de paquetes para distribuciones basadas en Arch Linux._

# Alternativa a un paquete
Aunque los paquetes siguen sirviendo como un método muy eficiente para distribuir software, en los últimos años están apareciendo tecnologías alternativas que buscan acercar Linux y simplificar su gestión de software. Por citar un ejemplo, quizá el más destacado es el formato Snap que trata a los programas como objetos autónomos y aislados que evitan en cierto modo ser “dependientes de dependencias”.

En el sentido contrario tenemos la compilación desde la fuente. Este proceso era muy común en el pasado y todavía encontramos distribuciones que potencian su uso como Slackware. La principal ventaja es que una instalación de compilación desde el código fuente requiere que obtenga el código real de un programa, esto nos permite observar y entender qué ocurre en su interior y poder hacer los cambios necesarios para optimizar el software a nuestro hardware.

# La Terminal 
La terminal de Linux se basa en un lenguaje de scripting conocido como Bash, heredada de sh, la consola de Unix. Podemos ejecutar scripts desde la consola, ejecutar binarios y realizar todo tipo de tareas. A diferencia de Windows, Linux cuenta en su terminal una gran cantidad de herramientas muy avanzadas para administrar y controlar el sistema operativo, todo lo que hacemos desde una interfaz, podríamos hacerlo perfectamente desde la terminal. Aunque de forma más complicada, larga y menos intuitiva.

## Sudo y Su. Ejecutar Comandos Como Otro Usuario

Muchos comandos invocan acciones que solo pueden ser realizadas por el usuario root o superusuario. Esto significa que, si intentas instalar un paquete en tu sistema, y por ello haces un apt install <paquete>, desde la sesión de tu usuario normal no se te permitirá.

Para ello, deberías primero hacer un log-in con el usuario root (en la consola) y posteriormente realizar esta acción desde este nivel de privilegios. Para agilizar esta tarea, dispones de herramientas como sudo o su, ambas similares a la práctica pero diferentes en su concepción.

## Sudo

De sudo se podrían escribir líneas y líneas, pero para lo que es el propósito de este post, quédate con la idea de que, lo que hace, es ejecutar el comando que lo sigue utilizando, temporalmente, los privilegios de otro usuario. Este usuario, en la mayoría de usuarios suele ser el superusuario, pero se puede configurar para que sea cualquier otro.

# Comandos para navegar por la terminal
### Pwd

El comando pwd te indica la ruta completa del directorio de trabajo en el que se encuentra tu usuario. Su función es meramente informativa, peor muy útil en ciertas ocasiones, como por ejemplo, conocer el nombre del directorio de trabajo actual.

``` 
pwd
```
### Cd
El comando cd te permite cambiar de directorio de trabajo. Sería el equivalente a ingresar o entrar en la carpeta pero desde la consola. Básicamente requiere indicar el nombre del directorio en el que deseas moverte. Acepta rutas absolutas y relativas. A continuación tienes algunos de los múltiples ejemplos de su uso:
```
cd /home/usuario/Documentos
```
Cd  la puedes utilizar para saltar un directorio hacía atrás respecto del que te encuentres. De este modo, si te encuentras dentro del directorio /home/usuario1/Documentos, saltarás un nivel hacía arriba hasta situarte en /home/usuario1.

```
cd..
```

### LS
Con el comando ls podrás listar los diferentes archivos y directorios de la carpeta de trabajo en la que te encuentres. El comando acepta multitud de opciones.
Con esta opción, el comando te mostrará, en forma de lista, todos el contenido que se encuentre dentro del directorio de trabajo, incluyendo, además, archivos y carpetas ocultos.


```
ls -a
```
Esta opción es similar al primer caso, pero muestra el contenido en forma de lista e incluye información referente a cada elemento. Se usa muchísimo y es especialmente útil a la hora de conocer el propietario y los permisos de cada fichero.
```
ls -l
```
### Find
El comando find es muy similar en su función básica a ls, ya que de entrada sirve para listar todo el contenido de un directorio. La diferencia es que, aplicando filtros, te puede servir para buscar archivos de forma más precisa.
Con esta opción, find te listará todos el contenido del directorio Documentos (dentro del directorio de trabajo actual) también de forma recursiva, recorriendo todos los niveles hacía abajo.

```
find ./Documentos
```

Si quieres empezar a establecer filtros por nombre, puedes añadir el parámetro -name. En este ejemplo, estamos intentando localizar un archivo concreto dentro de Documentos que su nombre corresponda a archivo.txt.

```
find ./Documentos -name *.pdf
```

### Crear, Borrar, Copiar y Mover Archivos y Directorios

El comando mkdir te permitirá crear un directorio con el nombre y la ruta que especifiques. Si no le indicas ninguna ruta, por defecto, te creará la carpeta dentro del directorio de trabajo en el que te encuentres. A continuación tienes algunos ejemplos sencillos.
```
mkdir /home/usuario1/directorio1
```
En el caso de arria, mkdir te creará el directorio de nombre directorio1, en la ruta que le hayas especificado, en este caso dentro de la carpeta principal de usuario.
```
mkdir directorio2
```
Con esta sintaxis, el comando te creará una carpeta de nombre directorio2 dentro del directorio de trabajo en la que te encuentres (recuerda utilizar pwd para saber donde estás).

### Rmdir
El comando rmdir te permite eliminar el directorio que le especifiques. Para poder utilizar este comando, el directorio a borrar debe estar vacío. A continuación tienes un par de ejemplos.
```
rmdir /home/usuario1/directorio1
```
En este caso, rmdir borrará el directorio de nombre directorio1, que se encuentra en la ruta especificada, en este caso dentro de la carpeta de usuario.
```
rmdir directorio2
```
En este otro ejemplo, el rmdir eliminará el directorio de nombre directorio2, el cual debe encontrarse dentro de la carpeta en el que te encuentres. De lo contrario, indicará que el directorio no existe.

### Cp 
Usando el comando cp, seras capaz de copiar archivos y directorios, así como ubicarlos en otras rutas. A continuación, tienes un par de ejemplos de como se puede utilizar.

```
cp archivo1.txt archivo2.txt

```
Este es posiblemente el uso más simple de cp. Con esta forma, crearás una copia del archivo archivo1.txt la cual se guardará con el nombre archivo2.txt. En este caso, el archivo de partida debe encontrarse dentro del directorio de trabajo en el que estés.

```
cp /home/usuario1/archivo1.txt /tmp/archivo2.txt

```
Alternativamente, puedes especificar la ruta en la que se encuentra el archivo de partida, de nombre archivo1.txt, y la ruta del directorio dentro del cual quieres que se guarde la copia, en este caso dentro del directorio tmp.

### Mv
El comando mv te servirá para mover archivos desde la consola. Sería lo equivalente a arrastrar un archivo desde una ubicación a otra. La sintaxis es muy sencilla, solamente debes especificar la ubicación de inicio, incluyendo el nombre del archivo, y la ubicación de destino. También puedes modificar el nombre del archivo en su ubicación de destino.

```
mv /home/usuario1/Descargas/archivo1.txt /home/usuario1/Documentos/archivo1.txt

```
En este ejemplo de arriba estamos moviendo el archivo de nombre archivo1.txt desde la carpeta Descargas hacía la carpeta Documentos. Para ello hemos utilizado rutas absolutas.

```
mv Descargas/archivo1.txt Documentos/archivo1.txt

```

### Touch
El comando touch te va a permitir, entre otras cosas, crear un archivo de texto vacío (en formato .txt) al que, posteriormente, podrás agregarle el contenido que desees de forma manual, o mediante el uso de otros comandos que veremos.

```
touch nombrearchivo

```
Esta opción te generará un archivo de texto vacío de nombre nombrearchivo, en el directorio en el que te encuentres (por defecto el directorio del usuario con el que estás logueado en la terminal)

```
touch nombrearchivo1 nombrearchivo2 nombrearchivo3

```
En este caso, el comando te generará tres archivos de texto vacíos, con los nombres nombrearchivo1, nombrearchivo2, y nombrearchivo3, y en el directorio de trabajo en el que te encuentres.

### Cat
El comando cat es uno de los comandos más utilizados cuando se trata de manejar archivos de texto (en formato .txt) desde la terminal. Entre sus múltiples opciones, está la posibilidad de crear un archivo, imprimir por pantalla su contenido, etc. Veamos algunos ejemplos:

Este comando te creará un archivo de texto vacío, de nombre nombrearchivo, y te permitirá teclear el contenido que desees introducirle. Una vez tecleado el contenido, puedes finalizar mediante la combinación CTRL+D.
```
cat > nombrearchivo
contenido línea 1
contenido línea 2
CTRL+D

```
Esta orden te permitirá imprimir por pantalla todas las lineas de texto del archivo de texto de nombre nombrearchivo. El archivo indicado debe encontrarse en el directorio de trabajo actual.
```
cat nombrearchivo

```
Esto te imprimirá por pantalla, de forma conjunta, el contenido de los archivos indicados, en este caso nombrearchivo1 y nombrearchivo2.
```
cat nombrearchivo1 nombrearchivo2

```
Este comando te imprimirá por pantalla el contenido del archivo de texto de nombre nombrearchivo, mostrándote, además, el número de línea al principio de cada línea de texto.
```
cat -n nombrearchivo

```
Muy similar al anterior, con la diferencia de que a la hora de numerar las líneas de nombrearchivo, solo se numeran aquellas que contienen texto, y se descartan las lineas en blanco.

```
cat -b nombrearchivo
```

