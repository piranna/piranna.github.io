---
lang: en
layout: post
title: Presenting Mafalda SFU
---

[Mafalda SFU](https://github.com/Mafalda-SFU) is a massively vertical and
horizontal scalable SFU built on top of [Mediasoup](https://mediasoup.org/).
This allow to have (theorically) unlimited sized WebRTC-based video room calls.

Mediasoup is one of the most important SFUs: open source, performant, and easy
to use, but it's too much low level and RTP streams oriented, so it's main issue
is its lack of off-the-shelf scalability. Due to that, Mediasoup `Router`
instances are limited to a single CPU core and a reduced number of participants.

During to the Covid pandemic, I've been working extensively in WebRTC projects
in the last year and a half, and one of the topics that most times surfaced was
how to use Mediasoup with big video rooms in both an easy to use and performant
way. So, after finding some issues in the way other projects were aproaching
this problem, I started to think about my own solution.

Mafalda aproach is simple: just create a `MafaldaRouter` instance, and it will
scale itself to use all the server CPU cores and create the connections to other
servers. From both developers and users PoV, it's like using a single Mediasoup
`Router` instance, but running in a server with an humongous big CPU. Not only
that, but since Mafalda schedule algorythm try to minimize the number of used
connections and CPUs, you can run multiple `MafaldaRouter` instances in the same
server, and Mafalda will balance the resources between them. And when they are
not needed anymore, connections get closed and the CPU cores are freed, so you
can stop the servers to reduce costs, all this without needing to administer
them and almost without configuration.

The main features of Mafalda are:

- Fully automated: you only need to create a `MafaldaRouter` instance, and it
  will take care of everything else

- Optimiced resources consumption on half-used machines compared to libraries
  using other architectures, allowing to host multiple rooms on the same machine
  without needing to pre-assign resources, that could lead to a suboptimal usage

- Designed to support adding a new server to the cluster, without needing to
  restart the whole cluster. It also can make use automatically of new added CPU
  cores in a server (if it has support) without needing to restart the process

- API heavily influenced by [Mediasoup](https://mediasoup.org/), so it's easy
  to understand, use and migrate from your existing code

- 100% acceptance tests code coverage for both lines, branches statements and
  functions. This has shown to be very useful to find bugs until the
  [very last moment](https://twitter.com/el_piranna/status/1400401650993532929)

I've been working on Mafalda since March 2021, and so far I've fully implemented
[vertical](https://en.wikipedia.org/wiki/Scalability#Vertical_or_scale_up)
scaling, and got to a point where both API and code are stable and ready to
start testing in real enviroments.

At the same time, I'm currently working on
[horizontal](https://en.wikipedia.org/wiki/Scalability#Horizontal_or_scale_out)
scaling too. So far I've implemented a client library with
[the same API](https://twitter.com/mafalda_sfu/status/1417030937674665984) of
local Mafalda instances, and designed an events-based RPC protocol that
replicate the state of the remote Mediasoup objects and the Mafalda instances,
allowing to work with them as if they were local ones. That would help not only
to easily migrate deployments from local to cluster environments, but also to
simplify automated management of horizontal scaling and inter-server
connections. More on that in a future article ;-)
