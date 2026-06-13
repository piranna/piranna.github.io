---
layout: page
title: WebRTC
permalink: /webrtc/
---

I've been working with [WebRTC](https://webrtc.org/) since 2012, less than a
year after discussions started around designing and developing its
specifications, which made me one of the pioneers of this technology in Spain.

I got involved with it while developing [ShareIt!](projects.md#shareit), the
first serverless P2P file-sharing application written entirely in client-side
JavaScript, which won the "Most Innovative Project" award at the Spanish
national
[VII Free Software Universitary Championship](http://www.concursosoftwarelibre.org/1213/premiados-vii-cusl.html).
To develop it, I also needed to create
[DataChannel-polyfill](https://github.com/ShareIt-project/DataChannel-polyfill),
the first working implementation of WebRTC
[RTCDataChannel](https://w3c.github.io/webrtc-pc/#rtcdatachannel) API, four
months before it was available in experimental versions of both Chrome and
Firefox, using
[WebSocket](https://html.spec.whatwg.org/multipage/web-sockets.html#the-websocket-interface)
connections instead of a
[SCTP](https://en.wikipedia.org/wiki/Stream_Control_Transmission_Protocol)
connection as the transport layer.

Thanks to both projects, I was invited to do a keynote in the first Spain WebRTC
summit, hosted at
[Madrid Polytechnic University](http://www.upm.es/internacional) in November
2012, and my work was mentioned in the
[HTML5 for Masterminds](http://www.formasterminds.com/html5_for_masterminds_3rd_edition/)
book, written by [John D. Gauchat](http://www.jdgauchat.com/). After that, I was
invited to work at [eFace2Face](https://github.com/eface2face), and later I
joined the [Kurento](projects.md#kurento) team for two years, where I was
responsible for designing and developing the Node.js, JavaScript, and HTML5 APIs
for the Kurento media server.

In the following years, I worked as a WebRTC expert on multiple projects,
including the two start-ups where I've also been working as CTO,
[UnifyMe](https://twitter.com/unify_me) and [lingbe](https://www.lingbe.com/).
But shortly before the COVID-19 pandemic started, more and more companies began
to hire me as a freelance WebRTC expert, so in December 2020 I decided to work
full-time offering my services as a WebRTC architect and consultant, and as a
[Mediasoup](https://mediasoup.org/) expert, while also developing my own WebRTC
and streaming projects.

## Chronology

### 2012

- [ShareIt!](projects.md#shareit) (July 2012 - 2014)
  - Personal project
  - First serverless P2P file-sharing application fully written in browser
    client-side JavaScript, based on
    [Gnutella](https://en.wikipedia.org/wiki/Gnutella) protocol and architecture
- [DataChannel-polyfill](https://github.com/ShareIt-project/DataChannel-polyfill)
  (August - September 2012)
  - Personal project
  - First working implementation of WebRTC
    [RTCDataChannel](https://w3c.github.io/webrtc-pc/#rtcdatachannel) API using
    [WebSocket](https://html.spec.whatwg.org/multipage/web-sockets.html#the-websocket-interface)s
    as transport layer
- [RealTimeWeb summit](http://realtimeweb.dit.upm.es/) (23rd November 2012)
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
  - Design and development of HTML5, Node.js, and JavaScript APIs for Kurento
    media server, based on [GStreamer](https://gstreamer.freedesktop.org/)
  - Company acquired by [Twilio](https://www.twilio.com/) in September 2016

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

- [IE Business School](https://www.ie.edu/) (November 2019 - March 2020)
  - Consulting for the
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
  - R&D of video streaming and recording platform based on Mediasoup and
    [ffmpeg](https://www.ffmpeg.org/)

### 2021

Started working as full-time WebRTC Architect, in addition to my own projects.

- [Councilbox](https://www.councilbox.com/) (January 2021 - June 2021)
  - Mediasoup consulting and performance improvements for massive video calls,
    receiving up to 30 videos at the same time in a browser in a regular laptop
- [Mafalda SFU](https://github.com/Mafalda-SFU) (March 2021 - Present)
  - Personal project
  - Massively parallel vertically and horizontally scalable SFU built on top of
    Mediasoup
- [Dyte](https://www.dyte.io/) (June 2021 - March 2023)
  - Design and development of Mediasoup horizontal scaling, project quality
    consulting, and performance improvements for a modular WebRTC platform
- [Tegus medical](https://www.tegusmedical.com/) (July 2021 - January 2022)
  - WebRTC consulting and design of a new WebRTC architecture for recording and
    streaming hospital operating rooms
- [Virbela](https://www.virbela.com/) (August 2021 - February 2022)
  - Mediasoup and performance improvements of [FrameVR](https://framevr.io/)
    platform
- [Fermax](https://www.fermax.com/) (October 2021 - Present)
  - Mediasoup and WebRTC architecture consulting, and design of a new WebRTC
    architecture for remote control of video intercoms

### 2022

- [Pulse](https://pulse.ooo/) (February 2022 - March 2022)
  - WebRTC auditor for social streaming browser extension
- [GUD](https://gud.social/) (June 2022 - September 2022)
  - WebRTC architect and consultant for a mental health startup
- [Comera](https://mycomera.com/) (September 2022 - March 2023)
  - WebRTC architect and consultant for a UAE-based startup, building a
    local-market app to compete with WhatsApp and Telegram
- [Soundstage](https://www.soundstage.fm/) (December 2022 - January 2023)
  - WebRTC scalability auditor

### 2023

- [Engageli](https://www.engageli.com/) (March 2023 - May 2023)
  - WebRTC architect for online educational platform
- [TRC](https://trc.es/) (November 2023 - November 2024)
  - Streaming expert and Lead Software Architect for Spain army contractor,
    designing and developing and anti-drone system based on WebRTC and AI for
    real-time video processing and analysis

### 2024

- [Level Ex](https://www.levelex.com/) (July 2024 - September 2024)
  - Audit WebRTC architecture for a medical video games company, focused on
    reducing latency and improving connection quality and performance of their
    streaming platform

### 2025

- [CosmosGroup](https://cosmosgroup.ae/) (January 2025 - August 2025)
  - WebRTC architect and deputy CTO for a UAE-based startup, building AI-based
    3D avatars
- [WebRTC.ventures](https://webrtc.ventures/) (September 2025 - Present)
  - Senior WebRTC architect for multiple projects and companies, including
    [Terrestar](https://www.terrestar.net/) with a custom designed narrow-band
    low-latency protocol for BLE audio streaming and satellite-based VoIP calls,
    and [Teladoc Health](https://www.teladochealth.com/) for a patients remote
    monitoring system based on [Mediasoup](https://mediasoup.org/)

### 2026

- [Viamo](https://viamo.guide/) (January 2026 - Present)
  - WebRTC architect and consultant for a startup building a WebRTC-based system
    for city guides
- [Mozilla](https://www.mozilla.org/) (May 2026 - Present)
  - Senior WebRTC architect designing automated tools to upgrade `libwebrtc`
    library to the latest versions in corporate and legacy versions of Firefox
