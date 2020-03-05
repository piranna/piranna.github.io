---
layout: page
title: Projects
permalink: /projects/
---

Most important Open Source projects I've been worked on, both personal or in a
professional basis for third-party organizations.

## Personal projects

### [projectlint](https://github.com/projectlint)

Linter to check global quality of projects, based on my experience doing code
auditories. Not only checks for code quality or best practices, but also has
rules to validate project structure, file names conventions, complexity,
documentation, tests...

This project also involved the development from scratch a project-level rules
async engine and of a tasks runner with support for parallel execution and
multiple optional alternatives, since none of them was available at that time.

### [TransFast](https://github.com/Takeafile)

Initially designed as a one-to-one high performance files transfer protocol
based on WebRTC DataChannels, it evolved into a transport-agnostic
streams-oriented communications protocol for general purpose heavily influenced
by [Node.js streams](https://nodejs.org/api/stream.html). Taking ideas from P2P
architectures, it implements advanced features like asynchronous send and
reception, flow control with backpressure, use multiple transports in parallel,
or auto-recovering.

This project was sponsored by [Takeafile](https://takeafile.com) with funds from
the European Union's [Horizon 2020](https://ec.europa.eu/programmes/horizon2020)
program.

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

<iframe title="vimeo-player" src="https://player.vimeo.com/video/220960658" width="640" height="360" frameborder="0" allowfullscreen></iframe>

### [ShareIt!](https://github.com/ShareIt-project)

First P2P filesharing webapp based on client-side Javascript and HTML5, build
using [WebRTC](https://webrtc.org/) DataChannels, with an architecture inspired
by [Gnutella](https://www.gnu.org/philosophy/gnutella.html). Since DataChannels
were not available in web browsers, I needed previosly to create
[DataChannels-polyfill](http://github.com/ShareIt-project/DataChannel-polyfill),
the first working implementation of WebRTC DataChannels API, available 4 months
before of experimental versions of Chrome and Firefox browsers, and build using
WebSockets as transport layer.

This project won the spanish national
[VII Free Software Universitary Championship](http://www.concursosoftwarelibre.org/1213/premiados-vii-cusl.html)
and was invited to give a keynote at first spanish WebRTC summit at Politechnic
University of Madrid, November 2012.

## Third parties

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

### [![Kurento](https://www.kurento.org/sites/default/files/kurento.png "Kurento")](https://www.kurento.org/)

Kurento is the lead WebRTC media server, powering [Skype](https://www.skype.com)
web conferences or [Facebook](https://www.facebook.com/) and
[WhatsApp](https://www.whatsapp.com/) multi-user videochats, thanks to its
flexibility and performance. In contrast to other ones, it's focused on provide
a thin low-level layer on top of [GStreamer](https://gstreamer.freedesktop.org/)
with an easy to use API instead of a high-level aproach that does everything
that's needed to create a videoconference aplication. In this project I was
responsible to design and develop the Javascript and Node.js APIs, based on my
previous experience from developing [ShareIt!](#shareit).

Kurento team was acquired by [Twilio](https://www.twilio.com/) in 2016.
