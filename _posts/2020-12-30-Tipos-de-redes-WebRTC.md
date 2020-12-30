---
lang: es
layout: post
title: Tipos de redes WebRTC
twitter: '1344349398004858880'
---

[English version]({% post_url 2020-12-30-Types-of-WebRTC-networks %})

Respecto a arquitecturas WebRTC, no hay una bala de plata. Dependendiendo de
cual sea el caso de uso, la arquitectura óptima puede variar de un proyecto a
otro. Por este motivo, voy a explicar las principales arquitecturas de red que
suelen aplicarse en proyectos basados en WebRTC (y principalmente aplicadas al
streaming de video), y cuales son los pros y contras de cada uno de ellos.

## Arquitecturas descentralizadas

### P2P

Este es el más básico de todos ellos, y el único caso de uso para el que
realmente se diseño WebRTC. En esta arquitectura se establece una conexión
entre los dos clientes, generalmente llamados *peers*, y es la mas optima en
cuanto a consumo de ancho de banda, calidad y de latencia, ya que ambos peers se
conectan directamente, así que los únicos límites son los de la conexión y la
CPU de ambos peers. Esta es la arquitectura más sencilla de implementar y hay
multitud de aplicaciones de ejemplo y de demos... el problema está, en que ésta
arquitectura está limitada a conexiones uno-a-uno.

### Mesh

La solución trivial y obvia al problema de la arquitectura P2P cuando quieres
que haya más de dos participantes, es simplemente crear conexiones con los
nuevos participantes. Es la arquitectura que usan aplicaciones como
[appear.in](https://appear.in/)... pero el problema es que debido a su
simplicidad, es también la solución menos óptima de todas: el número de
conexiones crece respecto al número de participantes en la red mesh, llegando a
crecer el número de conexiones exponencialmente en casos de redes mesh
completamente conectadas (todos con todos). Además, esto implica que puede que
se tenga que hacer la codificación de los vídeos múltiples veces, por lo que el
consumo de CPU y de memoria de los peers es también alto. Es por esto que esta
arquitectura solo es práctica en proyectos simples y con un número de peers muy
bajo (generalmente 3-4 peers, según la calidad de los videos y el tipo de red
hasta 10, aunque en la práctica no se suele usar para más de 6), o en redes muy
dispersas donde el número de conexiones de cada peer con los demás es igualmente
bajo.

## Arquitecturas basadas en servidor

Para solventar los problemas de escalabilidad de red de los clientes en la
arquitectura mesh, la solución pasa por centralizar las conexiones en un
servidor, de forma que este se encargue de optimizar el ancho de banda. Para
ello se utilizan Media Servers y librerías que implementan compatibilidad con
WebRTC (realmente las APIs de WebRTC son un wrapper que internamente trabajan
con RTP), actuando el servidor como si fuera otro peer. Esto tiene además la
ventaja de que dichos Media Servers pueden tener funcionalidad extra, como por
ejemplo grabar las sesiones en un archivo.

A pesar de que por diseño todas las comunicaciones basadas en WebRTC están
cifradas, el hecho que el servidor tenga que descifrarlas para procesarlas y redirigirlas puede representar un problema de seguridad en caso de que quede
comprometido, por ese motivo no se pueden usar en algunos sectores como son las
aplicaciones bancarias, aunque se esta trabajando en una especificacion para
[añadir soporte de encriptacion end-to-end](https://www.callstats.io/blog/2018/06/01/examining-srtp-double-encryption-procedures-for-selective-forwarding-perc)
para solucionar este problema.

### MCU

Las arquitecturas basadas en *Multipoint Conferencing Unit* fueron las primeras
en tratar de solucionar el problema del ancho de banda en las videoconferencias
múltiples. Desde el punto de vista de los peers, es como si estuvieran
conectados contra otro único peer (un stream de subida y uno de bajada)... solo
que en este caso el otro peer realmente es un servidor, el cual se encarga de
combinar los streams que recibe de todos los peers y crear uno nuevo con todos
ellos, que es el que enviará a todos los peers de vuelta (y donde los emisores
también se verían a si mismos junto con los videos de los demás). Esta es la
arquitectura que usa [Blue Jeans](http://bluejeans.com/) o servidores como
[Medooze](http://www.medooze.com/) o [Kurento](https://www.kurento.org/), este
último usado internamente por Skype y en las llamadas grupales de Whatsapp y
Facebook.

Obviamente, las principales ventajas de usar un MCU son la simplicidad de uso y
el consumo de ancho de banda desde el punto de vista de los peers (al fin y al
cabo, es una conexión uno-a-uno como en el caso de la arquitectura P2P), pero el
precio a pagar es un consumo elevado de memoria y de CPU en el servidor, puesto
que tiene que decodificar, mezclar y volver a codificar todos los videos de
todos los peers, además de tener los videos un layout fijo. Esto impide que esta
arquitectura pueda escalar mas alla de unas
[decenas de peers](https://www.kurento.org/blog/kurento-media-server-690-libnicer-and-performant)
conectados a una sola máquina, aparte de proporcionar menos flexibilidad, pero
puede ser útil en situaciones donde el número de receptores es muy alto o se
quiera mostrar a todos los participantes simultáneamente, como por ejemplo en un
videowall o si se va a grabar y luego retransmitir la reunión, o si el ancho de
banda o CPU de los peers es reducida.

### Selective MCU

La solución al problema de la flexibilidad es obvia: generar un stream
personalizado para cada uno de ellos, y que estos controlen cómo quieren que se
les muestre. El principal problema que acarrea esta arquitectura también es
obvio: a más streams combinados y generados, mayor consumo de CPU, ya que es
como si cada peer estuviera en su propia reunión con todos los demás. Es por
este motivo por el que es una arquitectura que no se usa mucho, ya que el número
de conexiones que puede soportar un único servidor se reduce drásticamente y por
tanto es más teórica que práctica, aunque quizas pueda tener sentido usarlo
cuando el número peers es muy bajo (al menos emisores, si el número de
receptores es muy alto quizas podrían agruparse entre si los que hayan definido
el mismo layout) o donde el ancho de banda de los peers receptores sea muy
limitado.

### SFU

Desde que empezó a desarrollarse WebRTC como estándar en 2011, el ancho de banda
disponible en las casas y oficinas, y la potencia y memoria de los ordenadores
domésticos han aumentado considerablemente. Además, se ha visto que la mayoría
de casos de uso han sido aplicaciones de videoconferencia, sin necesidad de un
procesamiento de los streams en el lado del servidor más allá de grabar las
sesiones. Todo esto junto con la búsqueda de reducir costes de servidor ha hecho
que hayan ido adquirido popularidad los *Selective Forwarding Unit*, los cuales
reciben un único stream desde los peers pero envían varios streams de vuelta,
correspondientes a los demás peers. Esto obviamente implica un mayor consumo de
ancho de banda y de CPU de los clientes, pero tiene la ventaja de que estos
pueden mostrarlos como quieran, o incluso indicarle al servidor que solo les
manden algunos de ellos desconectando los demás o enviandolos a menor
resolución, por ejemplo si se está mostrando uno de ellos a pantalla completa.
Esta es la arquitectura de aplicaciones como Google Meet o
[talky](https://talky.io), o servidores como [MediaSoup](https://mediasoup.org).

## Arquitecturas híbridas

Para casos de uso más complejos o para optimizar los mismos, generalmente se
combinan las arquitecturas anteriores según cada caso para explotar las ventajas
de cada. Por ejemplo, sería factible usar un SFU para interconectar a los
participantes de una sesión, y al mismo tiempo que el SFU envíe los streams
también a un MCU para que los combine en uno solo, o que los reenvíe a otros
servidores para propagar la señal y distribuir el procesamiento, como ofrecía
[Kurento tree](https://github.com/Kurento/kurento-tree). Otro ejemplo muy
habitual consiste en combinar conexiones P2P con un servidor centralizado, de
forma que se alternen entre unas y otro dinámicamente según el número de peers
que haya en sesión, usando una conexión P2P cuando solo haya dos peers y
migrando a un MCU o SFU cuando haya 3 o más.
