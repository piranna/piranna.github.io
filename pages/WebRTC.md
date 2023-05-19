---
layout: page
title: WebRTC
permalink: /webrtc/
---

I've been working with [WebRTC](https://webrtc.org/) since 2012, less than one
year after they were started the discussions about design and develop its
specifications, being one of the pioneers of this technology in Spain.

I got involved on it while developing [ShareIt!](projects.md#shareit), the first
serverless P2P filesharing application written fully in client side JavaScript,
and with whom I won the "Most Innovative Project" award at the spanish national
[VII Free Software Universitary Championship](http://www.concursosoftwarelibre.org/1213/premiados-vii-cusl.html).
To develop it, I also needed to create
[DataChannel-polyfill](https://github.com/ShareIt-project/DataChannel-polyfill),
the first working implementation of WebRTC
[RTCDataChannel](https://w3c.github.io/webrtc-pc/#rtcdatachannel) API, four
months before it was available in experimental versions of both Chrome and
Firefox browsers, using for it
[WebSocket](https://html.spec.whatwg.org/multipage/web-sockets.html#the-websocket-interface)
connections instead of a
[SCTP](https://en.wikipedia.org/wiki/Stream_Control_Transmission_Protocol)
connection as transport layer.

Thanks to both projects, I was invited to do a keynote in the first Spain WebRTC
summit, hosted at
[Madrid Polytechnic University](http://www.upm.es/internacional) in November
2012, and got a paragraph talking about my work at
[HTML5 for Masterminds](http://www.formasterminds.com/html5_for_masterminds_3rd_edition/) book, written by
[John D. Gauchat](http://www.jdgauchat.com/). After that, I was invited to work
at [eFace2Face](https://github.com/eface2face), and later I joined the
[Kurento](projects.md#kurento) team for two years, where I was responsible for
design and develop the Node.js, Javascript and HTML5 APIs for Kurento media
server.

In the next years, I've been working as WebRTC Expert for multiple projects,
including the two start-ups where I've also been working as CTO,
[UnifyMe](https://twitter.com/unify_me) and [lingbe](https://www.lingbe.com/).
But since short before it started the Covid-19 pandemic, I got contracted each
time by more companies to work as freelance WebRTC Expert, so in December 2020,
I decided to work full-time offering my services as WebRTC Architect and
consultor, and as [Mediasoup](https://mediasoup.org/) Expert, in addition to
develop my own WebRTC and streaming projects.

## Chronology

### 2012

- [ShareIt!](projects.md#shareit) (July 2012 - 2014)
  - Personal project
  - first serverless P2P filesharing application fully written in broser
    client-side JavaScript, based on
    [Gnutella](https://en.wikipedia.org/wiki/Gnutella) protocol and architecture
- [DataChannel-polyfill](https://github.com/ShareIt-project/DataChannel-polyfill)
  (August - September 2012)
  - Personal project
  - First working implementation of WebRTC
    [RTCDataChannel](https://w3c.github.io/webrtc-pc/#rtcdatachannel) API using
    [WebSocket](https://html.spec.whatwg.org/multipage/web-sockets.html#the-websocket-interface)s
    as transport layer
- [RealTimeWeb summit](http://realtimeweb.dit.upm.es/) (23th November 2012)
  - Invited as speaker in the first Spain WebRTC summit
- [eFace2Face](https://github.com/eface2face) (November 2012 - December 2013)
  - Design and development of web Operating System for WebRTC-based notary app

### 2013

- [VII Free Software Universitary Championship](http://www.concursosoftwarelibre.org/1213/premiados-vii-cusl.html)
  (23-24th May 2013)
  - Winner of "Most Innovative Project" award with
    [ShareIt!](projects.md#shareit) project

### 2013 to 2015

- [Kurento](projects.md#kurento) (July 2013 - June 2015)
  - Design and development of HTML5, Node.js and Javascript APIs for Kurento
    media server, based on [GStreamer](https://gstreamer.freedesktop.org/)
  - Company adquired by [Twilio](https://www.twilio.com/) in September 2016

### 2015

- Telepado (September 2015 - December 2015)
  - [Telegram](https://telegram.org/) protocol based chat application

### 2016 to 2018

- [UnifyMe](https://twitter.com/unify_me) (September 2016 - November 2018)
  - CTO & co-founder
  - UCaaS - Unified Communications as a Service

### 2018

- [TransFast](projects.md#transfast) (July 2018 - December 2018)
  - Personal project sponsored by [Takeafile](https://github.com/Takeafile)
  - High-performance transport-agnostic streams-oriented communications protocol
- [lingbe](https://www.lingbe.com/) (December 2018 - August 2019)
  - CTO & WebRTC Expert
  - Videocalls-based language exchange mobile app

### 2019

- [IE Bussiness School](https://www.ie.edu/) (November 2019 - March 2020)
  - Consultory of
    [WOW Room](https://www.ie.edu/es/universidad/noticias-eventos/noticias/ie-presenta-wow-room-un-nuevo-impulso-en-la-apuesta-de-inmersion-tecnologica-de-la-institucion/)
    project

### 2020

- Veedeo.me / [Callab.me](https://callab.me/) (April 2020 - December 2020)
- [Toucan Events](https://www.toucan.events/) (July 2020 - January 2021)
- [Copper Dating](https://copperdating.com/) (August 2020 - December 2020)
- [HelloOtter](https://www.hellootter.com/) (November 2020 - April 2021)
- [Atos Research & Innovation](https://atos.net/en/about-us/innovation-and-research)
  (September 2020 - May 2021)
  - WebRTC Expert and R&D of HLS P2P video streaming from VR headsets
  - Improvement of Google `libwebrtc` library
    [Java bindings](https://webrtc-review.googlesource.com/c/src/+/218847)
- [Zerintia](https://zerintia.com/) (October 2020 - January 2021)
  - R&D of video streaming and recording platform based on
    Mediasoup and [ffmpeg](https://www.ffmpeg.org/)

### 2021

Started working as full-time WebRTC Architect, in addition to my own projects.

- [Councilbox](https://www.councilbox.com/) (January 2021 - June 2021)
  - Mediasoup consultory and performance improvements of massive videocalls,
    receiving up to 30 videos at the same time in a browser in a regular laptop
- [Mafalda SFU](https://github.com/Mafalda-SFU) (March 2021 - Present)
  - Personal project
  - Massively parallel vertical and horizontal scalable SFU build on top of
    Mediasoup
- [Dyte](https://www.dyte.io/) (June 2021 - March 2023)
  - Design and development of Mediasoup horizontal scaling, project quality
    consultory, and performance improvements for modular WebRTC platform
- [Tegus medical](https://www.tegusmedical.com/) (July 2021 - January 2022)
  - WebRTC consultory and design of new WebRTC architecture for recording and
    streaming of hospitals operating rooms
- [Virbela](https://www.virbela.com/) (August 2021 - February 2022)
  - Mediasoup and performance improvements of [FrameVR](https://framevr.io/)
    platform
- [Fermax](https://www.fermax.com/) (October 2021 - September 2022)
  - Mediasoup and WebRTC architecture consultory, and design of new WebRTC
    architecture for remote control of video intercoms

### 2022

- [Pulse](https://pulse.ooo/) (February 2022 - March 2022)
  - WebRTC auditor for social streaming browser extension
- [GUD](https://gud.social/) (June 2022 - September 2022)
  - WebRTC architect and consultor for mental health startup
- [Comera](https://mycomera.com/) (September 2022 - March 2023)
  - WebRTC architect and consultor for UAE based startup, building a local
    marked oriented competitor app to Whatsapp and Telegram
- [Soundstage](https://www.soundstage.fm/) (December 2022 - January 2023)
  - WebRTC scalability auditor
