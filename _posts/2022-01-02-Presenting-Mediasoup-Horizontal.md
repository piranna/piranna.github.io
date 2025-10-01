---
lang: en
layout: post
tags: Mafalda SFU, webrtc, mediasoup, sfu, video, streaming, scalability
title: Presenting Mediasoup Horizontal
twitter: '1477742653383008261'
---

Although [Mafalda SFU](https://mafalda.io) is mainly focused on vertical scaling
of [Mediasoup](https://mediasoup.org/) and the WebRTC stack, the main problem
I've found companies are facing is about how to easily implement Medisoup
[horizontal](https://en.wikipedia.org/wiki/Scalability#Horizontal_or_scale_out)
scaling. I've been working on a solution for this problem for a while on, and
since Mafalda is build on top of Mediasoup, it's also needed to help it to
provide transparent vertical and horizontal scaling, so let's see how it works.

`Mediasoup-Horizontal` is a manager that allows to remotely control multiple
instances of Mediasoup, providing a simple and easy to use API based on the one
from the Javascript
[Set](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Set)
object. It allows to add and remove Remote Mediasoup `Client` objects and
manage them, although is not directly tied to them so you can provide your own
objects following that same API, for example to also control a local Mediasoup
instance in addition to the remote ones.

When adding a Remote Mediasoup `Client` object to the `Mediasoup-Horizontal`
instance, it checks that all the Remote Mediasoup instances are compatible
between them, so you don't have to worry about in what instance your Mediasoup
objects are being created. After that, it monitors the creation of new objects,
and also does it with the `Client` current objects in case they are later
destroyed.

`Mediasoup-Horizontal` also provides a Mediasoup compatible API, so by using it
you can *auto-magically* enable your application to scale horizontally without
needing to change your current code. The "magic" happens by using objects that
provides the same API of Mediasoup
[Worker](https://mediasoup.org/documentation/v3/mediasoup/api/#worker) and
[Router](https://mediasoup.org/documentation/v3/mediasoup/api/#router) classes,
but internally proxying the method calls to their internal `Connection`
objects, shared by all the `Client` instances currently connected to the same
server. This is done this way to be transparent to the actual objects
references being done at `Mediasoup-Horizontal` level.

After that, implementation of `pipeToRouter()` method is fairly trivial. Code is
an optimized version of original Mediasoup one, just only with fine-grain errors
management and with some performance optimizations to reduce delay of events
propagation, so general behaviour is the same, although there's space for
improvements. In fact, I proposed to
[move it out officially](https://github.com/versatica/mediasoup/issues/705) to a
separate library so it can be reused by other projects like this one, but the
proposal was rejected.

And that's it, that's how `Mediasoup-Horizontal` works. Next steps I'm planning
about are to improve performance and resilience, allowing it to better recover
from network re-connections, and also works towards implementing a tool for
monitoring in real time the status of all the Remote Mediasoup instances.
