---
layout: post
title: `redux-offline` in Node.js
twitter: '1232054402216755201'
---

Experimenting with [redux-offline](https://github.com/redux-offline/redux-offline),
I've done a Proof-of-Concept about how to use
[`redux-offline` in a Node.js environment](https://github.com/piranna/redux-offline-Node.js-PoC),
like a CLI command. This is useful for example when it's needed to do an offline
aware application that needs to queue some operations until it's connected again.

[redux](https://redux.js.org/) is mostly focused for
[React](https://reactjs.org/) and
[React Native](https://facebook.github.io/react-native/) applications, but it's
generic enough to be used standalone, just only calling to its
[dispatch](https://redux.js.org/api/store#dispatch) method by hand, and since
`redux-offline` is just a wrapper on top of it (and
[redux-persist](https://github.com/rt2zz/redux-persist), by the way), to make it
run in pure Node.js is just a matter of properly configure it.

This proof of concept just only keeps updating a counter, "faking" the network
operations just by printing the counter in the console when we are online. Due
to this, there's no real usage of `redux` beyond storing the operations queue of
`redux-offline`, but due to its internal usage of `redux-persist`, it can be
used too to store application configuration or services connection credentials,
for example.

The key point of the proof of concept is about network detection. For that, I'm
using the [internet-available](https://github.com/ourcodeworld/internet-available)
module, that does a DNS request to a domain (`google.com` by default), by doing
requests indefinitely and notifying when the network status has changed from
online to offline or viceversa. You can change that to use your own domain, or
also doing a heartbeat pinging to be sure the server is up and running.

In addition to that, operations queue is being modified on the fly each time a
new operation is being added, so in case we are offline and there are operations
in the queue, instead of adding a new counter operation, the old one is updated
increasing its `counter` value. This is just an example, a more realistic one
could be for example to remove an already queued operation if a new inverse one
(like an addition and a substraction) is added later.

Regarding state persistence, default persistor objects for `redux-persist` are
focused on the browser, so a custom persistor is needed. In this case
[redux-persist-node-storage](https://github.com/pellejacobs/redux-persist-node-storage)
is being used, that store the status in JSON files. That's not the most optimal
solution and I would have preffer to use a [LevelDB](http://leveldb.org/)-backed
one, but for the proof of concept it just does the job. It's important to take
in account that by
[design decissions](https://github.com/redux-offline/redux-offline/issues/119#issuecomment-343656725)
`redux-offline` by default use `redux-persist` in its `4.x.x` version instead of
the current (and ironically `redux-offline` oriented) `5.x.x` version. One of
the changes between both version families is that persistor objects API in
`4.x.x` make use of callbacks while newer `5.x.x` one make use of Promise
objects, so just by using latest `2.0.0` version of `redux-persist-node-storage`
will plainly not work, and it's needed to use the previous one `1.0.2` that
still make use of callbacks (or use `redux-persist` newer `5.x.x` version by
hand, as you want).

Last but not least, rehydrating the state from the filesystem is fast but not
immediate,so to prevent to start dispatching actions before the state is fully
loaded in memory, a callback is provided so `redux-persist` can notify us that
everything went well and we can start using our newly created store.
