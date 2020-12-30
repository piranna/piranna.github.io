---
lang: en
layout: post
title: Types of WebRTC networks
twitter: '1344349398789214212'
---

[Spanish version]({% post_url 2020-12-30-Tipos-de-redes-WebRTC %})

When it comes to WebRTC architectures, there is no silver bullet. Depending on
each use case, the optimal architecture may vary from project to another. For
this reason, I am going to explain the main network architectures that are
usually applied in projects based on WebRTC (and mainly applied to the streaming
video), and what are the pros and cons of each one of them.

## Decentralized architectures

### P2P

This is the most basic of them all, and the only use case to whom WebRTC was
designed for. In this architecture a connection is established between the two
clients, generally called *peers*, and it'ss the most optimal regarding
bandwidth consumption, quality and latency, since both peers are connected
directly, so the only limits are the connection and CPU of both peers. This is
the simplest architecture to implement and there are multitude of sample and
demo applications... problem is, this architecture is limited to one-to-one
connections.

### Mesh

Trivial and obvious solution to the problem of P2P architecture when there are
more than two participants, is simply to create connections with the new
participants. It is the architecture used by applications such as
[appear.in](https://appear.in/)... but the problem is that due to its
simplicity, it is also the least optimal solution of all: the number of
connections grows with respect to the number of participants in the mesh
network, growing the number of connections exponentially in cases of mesh
networks completely connected (everyone with everyone). Furthermore, this
implies that videos have to be encoded multiple times, so the CPU and memory
consumption of the peers is also high. This is why this architecture is only
practical in simple projects with a number of very peers low (usually 3-4 peers,
depending on the quality of the videos and the type of network up to 10,
although in practice it is not usually used for more than 6), or in very
sparse networks where the number of connections of each peer with the others is
equally low.

## Server-based architectures

To solve the network scalability problems of customers in the mesh architecture,
the solution is to centralize the connections in a server, so that it is in
charge of optimizing the bandwidth. This is achieved using Media Servers and
libraries that implement compatibility with WebRTC (actually the WebRTC APIs are
a wrapper that internally works with RTP), the server acting as if it were
another peer. This also has the advantage that these Media Servers may have
extra functionality, like record and save sessions to a file.

Although by design all WebRTC-based communications are encrypted, the fact that
the server has to decrypt them to process and redirect them can represent a
security problem in case they are compromised, so for that reason they cannot be
used in some sectors such as banking applications, although a specification to
[add end-to-end encryption support](https://www.callstats.io/blog/2018/06/01/examining-srtp-double-encryption-procedures-for-selective-forwarding-perc)
is being worked on to solve this problem.

### MCU

*Multipoint Conferencing Unit* based architectures were the first in trying to
solve the problem of bandwidth in video conferencing multiple. From the peers
point of view, it is as if they are connected against another single peer (an
upstream and a downstream stream)... just that in this case the other peer is
really a server, which is in charge of combine the streams it receives from all
peers and create a new one with all them, which is the one that will send all
the streams back to the peers (and where the emitters would also see themselves
along with the videos of others). This is the architecture that uses
[Blue Jeans](http://bluejeans.com/) or servers like
[Medooze](http://www.medooze.com/) or [Kurento](https://www.kurento.org/), this
last used internally by Skype and in group calls from WhatsApp and Facebook.

Obviously, the main advantages of using an MCU are the simplicity of use and
bandwidth consumption from the peers' point of view (at the end of the day, it
is a one-to-one connection as in the case of the P2P architecture), but the
price to pay is a high consumption of memory and CPU in the server, since you
have to decode, shuffle and re-encode all the videos from all the peers, in
addition to having the videos a fixed layout. This prevents this architecture
can scale beyond a few
[dozens of peers](https://www.kurento.org/blog/kurento-media-server-690-libnicer-and-performant)
connected to a single machine, apart from providing less flexibility, but can be
useful in situations where the number of receivers is very high or want to show
all the participants simultaneously, such as in a videowall or if the meeting is
being recorded to be broadcasted afterwards, or if the peers width band or CPU
is low.

### Selective MCU

The solution to the flexibility problem is obvious: generate a stream customized
for each one of the peers, that they can control how they want it to be shown to
them. The main problem with this architecture is also obvious: the more streams
combined and generated, the higher CPU consumption, since it is as if each peer
were in his own meeting with everyone else. This is why it's an architecture
that's not too much used, since the number of connections that a single server
can support is drastically reduced and it's more theoretical than practical,
although maybe it can make sense to use it when the number of peers is very low
(at least the number of emitters, when the number of receivers is very high
perhaps those that have defined the same layout can be grouped) or where the
bandwidth of the receiving peers is very limited.

### SFU

Since WebRTC began to be developed as a standard in 2011, bandwidth available in
homes and offices, and the power and memory of personal computers have increased
considerably. Furthermore, it has been seen that most of use cases have been
videoconferencing applications, without need of processing streams on the server
side beyond recording the sessions. All this together, with the search to reduce
server costs, has made that the *Selective Forwarding Unit*, which receive a
single stream from the peers but send multiple streams back, corresponding to
the other peers. This obviously implies a higher consumption of bandwidth and
CPU of the clients, but has the advantage that they can display them however
they want, or even tell the server to only send some of them disconnecting the
others or sending them to less resolution, for example if one of them is being
shown in full screen. This is the architecture of applications like Google Meet
or [talky](https://talky.io) or servers like [MediaSoup](https://mediasoup.org).

## Hybrid architectures

For more complex use cases or to optimize them, generally the previous
architectures are combine according to each case to exploit the advantages of
each one. For example, it would be feasible to use an SFU to interconnect the
participants of a session, and at the same time the SFU sends the streams also
to an MCU to combine them into one, or forward them to others servers to
propagate the signal and distribute the processing, as it was offered by
[Kurento tree](https://github.com/Kurento/kurento-tree). Another very usual
practice is to combine P2P connections with a centralized server, so they can
alternate between one and another dynamically according to the number of peers
in a session, using a P2P connection when there are only two peers and migrating
to an MCU or SFU when there are 3 or more.
