---
lang: en
layout: post
title: WebRTC horizontal scaling
---

When aproaching the horizontal scaling of WebRTC servers, we have two main
aproachs: decentralized P2P, and using a central server. Each one has its own
drawbacks and advantages, and I had difficulties to identify what aproach was
the best, since I usually have a personal preference for pure P2P architectures,
but they are not the most simple nor always the more efficient ones. So when
deciding how to aproach Mafalda horizontal scaling, I needed to consider the
pros and cons of each use case I would need, and here we have my conclusions.

## P2P

The first one needs to maintain its own list of servers where to ask for extra
resources. This list can be provided when starting the server, but if the extra
servers can be added and removed dynamically, this list will need to be updated
later, so we need a way to update the list. In addition to that, when querying
for another server with enought free resources to connect to, since we don't
have a central place to store the info, we need to ask to all the servers to get
their updated state so we can apply the heuristics to decide which one to use,
or the servers would need to send their state info to the other ones at
intervals. In both cases, if the number of servers is large, the bandwidth
needed to send the state info to all the servers will be high. One solution to
this would be to use a DHT or a database, but in both cases we would need anyway
to download the info to do the heuristics, and the second one leads us to a
centralized solution.

## Central server

So instead of having a central database where to store the state of the servers,
and need to query it to get the state of the servers, we can have instead
central server to do the queries for us. This central server would became a
single point of failure in case it gets down, so we can have mutiple instances
and store the state info of the servers in a database. Seems a bit like walking
in circles, but this one can be close to that query servers, so there would not
be so much bandwidth issues if they are located in the same place.

This central server (or servers) would just receive a request from the WebRTC
servers asking to connect to another empty enought server to increase their own
resources, and do all the heuristics to decide which one to use on its own, or
also decide to automatically spin-up a new server if there's no available ones
and it's configured to do it, so all the logic would be centralized in a single
place and being transparent to the other ones. It would do the request for the
state of the WebRTC servers and cache it, or receive the updates from them at
intervals, probably using an unreliable WebSocket connection or any other
similar one since the info is ephimeral and there's no need to keep it in sync
all the time.

In conclussion, between these two approaches, it seems that the central server
is the one that best fit this particular use case, since it's the one that best
balance CPU and bandwidth usage, and also allow to easily change the heuristics
without needing to spin-down the WebRTC servers.
