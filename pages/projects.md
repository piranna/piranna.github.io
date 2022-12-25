---
layout: page
title: Projects
permalink: /projects/
---

Most important projects I've conceived, designed and developed from scratch,
both personal or for third-party organizations in a professional basis. Most of
them are open-source, and I'm always looking for new ideas and collaborations.

## Personal projects

### [projectlint](https://github.com/projectlint)

Linter to check global quality of projects, based on my experience doing code
auditories. Not only checks for code quality or best practices, but also has
rules to validate project structure, file names conventions, complexity,
documentation, tests...

This project also involved the development from scratch a project-level rules
async engine and of a tasks runner with support for parallel execution and
multiple optional alternatives, since none of them was available at that time.

### [NodeOS](https://node-os.com/)

Minimal operating system build on top of [Linux kernel](https://www.kernel.org/)
usingo [Node.js](https://nodejs.org/) as its user space and fully managed with
[npm](https://www.npmjs.com/). It's mostly focused for Cloud and Fog computing,
at the same time for education and embeded systems, and has some unique
features like isolated filesystems for each user (it was planned to isolate each
one on its own [LXC container](https://linuxcontainers.org/)) to allow full
customization of the system by their users, or multiple flavors depending of the
user needs (also as a single-process OS or bootable USB, and was planned support
for networked GUI).

This project won the spanish national
[IX Free Software Universitary Championship](http://concursosoftwarelibre.us.es/1415/node/34.html),
was my [bachelor thesis](https://github.com/piranna/pfc) (graduated with
distinction), and I was also invited to give some keynotes at
*OpenExpoDay 2015* and *JsDayEs 2017* conferences.

<iframe title="vimeo-player" src="https://player.vimeo.com/video/220960658" width="100%" height="360" frameborder="0" allowfullscreen></iframe>

<details>
  <summary>Citations</summary>

- [Novática 236.pdf](<../papers/Novática 236.pdf>), April-June 2016:

  > They were also given honorable mentions for the projects:
  >
  > [...]
  >
  > **NodeOS** of **Jesús Leganés Combarro** (Rey Juan Carlos University).

  <details>
    <summary>Original (spanish)</summary>

    > Se entregaron también menciones especiales para los proyectos:
    >
    > [...]
    >
    > **NodeOS** de **Jesús Leganés Combarro** (Universidad Rey Juan Carlos).

  </details>

- [The Case for Writing Network Drivers in High-Level Programming Languages](<../papers/The Case for Writing Network Drivers in High-Level Programming Languages.pdf>),
  13 September 2019:

  > 4.10.1 Related work. JavaScript is rarely used for low-level code, the most
  > OS-like projects are **NodeOS** and OS.js. **NodeOS** uses the Linux kernel
  > with Node.js as user space. OS.js runs a window manager and applications in
  > the browser and is backed by a server running Node.js on a normal OS.
  > Neither of these implements driver-level code in JavaScript.

</details>

### [ShareIt!](https://github.com/ShareIt-project)

First P2P filesharing webapp based on client-side Javascript and HTML5, build
using [WebRTC](https://webrtc.org/) DataChannels, with an architecture inspired
by [Gnutella](https://www.gnu.org/philosophy/gnutella.html). Since DataChannels
were not available in web browsers, I needed previosly to create
[DataChannels-polyfill](http://github.com/ShareIt-project/DataChannel-polyfill),
the first working implementation of WebRTC DataChannels API, available 4 months
before of experimental versions of Chrome and Firefox browsers, and build using
WebSockets as transport layer.

This project won the "Most Innovative Project" award in the spanish national
[VII Free Software Universitary Championship](http://www.concursosoftwarelibre.org/1213/premiados-vii-cusl.html)
and was invited to give a keynote at first spanish WebRTC summit at Politechnic
University of Madrid, November 2012.

<details>
  <summary>Citations</summary>

- [Introducing ufo.js: A browser-oriented p2p network.pdf](<../papers/Introducing ufo.js - A browser-oriented p2p network.pdf>),
  February 2014:

  > Among real life applications using the datachannel as best as they can, we
  > should definitely mention **shareit** and sharefest. Such applications allow
  > browsers to share files in the absence of any form of upload to external
  > servers, as opposed to well-known services such as Dropbox or Google Drive.
  > Both **shareit** and sharefest use an external server holding and managing a
  > connection to each peer; these connections are used to accomplish all the
  > signaling procedures between peers. Thus the actual p2p communication
  > happens during file transfers.

  **Note**: [ShareIt!](projects.md#shareit) used an external server to bootstrap
  the initial discovery and signaling with other peers, once they were connected
  to at least another peer and being part of the P2P network, the discovery and
  signaling with new peers was done directly between peers over the P2P network
  itself, leaving the connection with the external server as a fallback
  mechanims.

</details>

### [PirannaFS](https://github.com/piranna/PirannaFS)

Modular filesystem build with Python and using [SQLite](https://www.sqlite.org)
to manage metadata, allowing to the user to customize its behaviour by using
plugins, and inspired by other new generation filesystems like
[BeFS](https://en.wikipedia.org/wiki/Be_File_System),
[ZFS](https://en.wikipedia.org/wiki/OpenZFS) or
[Ext4](https://en.wikipedia.org/wiki/Ext4).

This was my first open source project with some public repercussion, and won the
Madrid local edition of the spanish national
[V Free Software Universitary Championship](http://www.concursosoftwarelibre.org)
and was *Honorable Mention* in the national edition, both in 2011.

## Third parties

### [TransFast](https://github.com/Takeafile)

Initially designed as a one-to-one high performance files transfer protocol
based on WebRTC DataChannels, it evolved into a transport-agnostic
streams-oriented communications protocol for general purpose heavily influenced
and based by [Node.js streams](https://nodejs.org/api/stream.html). Taking
ideas from P2P architectures (conceptually, I consider it myself
[ShareIt!](#ShareIt!) 2.0), it implements advanced features like asynchronous
send and reception, flow control with backpressure, use multiple transports in
parallel, or auto-recovering.

This project was sponsored by [Takeafile Labs](https://takeafile.com) with funds
from European Union [Horizon 2020](https://ec.europa.eu/programmes/horizon2020)
program.

### [Context Broker](https://github.com/ContextBroker)

Node.js bindings for [Orion IoT server](https://fiware-orion.readthedocs.io/).

Although it was initially requested to develop just only a one-to-one proxy
server between the `Orion IoT Server` and other APIs like Google Spreadsheets or
Amazon DynamoDB, I took the initiative to a bottom-to-up development focused on
following Node.js best practices and standard protocols, and building an
expansible system based on reusable modules (the initially requested server
ended being just only 70 lines of code) with one-to-many publishing support in
half the initially estimated time. This is one of the projects I'm
professionally more proud of at various levels, but this would have not been
possible without a good in-detail documentation of the `Orion IoT Server`, clear
requirements and objectives, and giving me creative liberty from their side.
Kudos.

This project was sponsored by [Telefónica R&D](http://www.tid.es/) division.

### [![Kurento]({{ site.baseurl }}/images/logos/Kurento.png "Kurento")](https://www.kurento.org/)

Kurento is the lead WebRTC media server, powering [Skype](https://www.skype.com)
web conferences or [Facebook](https://www.facebook.com/) and
[WhatsApp](https://www.whatsapp.com/) multi-user videochats, thanks to its
flexibility and performance. In contrast to other ones, it's focused on provide
a thin low-level layer on top of [GStreamer](https://gstreamer.freedesktop.org/)
with an easy to use API instead of a high-level aproach that does everything
that's needed to create a videoconference aplication. Kurento team was acquired
by [Twilio](https://www.twilio.com/) in 2016.

In Kurento I was responsable of design and develop its Javascript and Node.js
[client APIs](https://github.com/Kurento/kurento-client-js) and its WebRTC
[browser utilities](https://github.com/Kurento/kurento-utils), based on my
previous experience from developing [ShareIt!](#shareit). After that, in 2020 I
was sponsored by [Veedeo.me](https://veedeo.me) to update `kurento-utils`
browser utilities package to make use of current WebRTC APIs and to follow newer
Javascript standards and best practices.
