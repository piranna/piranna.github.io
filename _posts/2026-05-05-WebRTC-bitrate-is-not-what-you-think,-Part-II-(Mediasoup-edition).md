---
categories:
  - WebRTC
  - Mediasoup
  - Research
  - Streaming
code: https://github.com/piranna/Content-Mediasoup-bandwidth
DOI: 10.5281/zenodo.19988776
lang: en
layout: post
tags:
  - video
  - codec
  - bitrate
  - benchmark
  - measurement
  - reproducibility
title: WebRTC bitrate is not what you think, Part II (Mediasoup edition)
---

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.19988776.svg)](https://doi.org/10.5281/zenodo.19988776)

> What changes when you add an SFU ([Mediasoup](https://mediasoup.org/)) in the
> middle of the pipeline?

<!--more-->

## Introduction

In the previous article
[WebRTC bitrate is not what you think](2026-04-28-WebRTC-bitrate-is-not-what-you-think.md)
I explored how video codecs behave under tightly controlled conditions using a
loopback `RTCPeerConnection`.

The goal was simple:

> remove as many variables as possible and measure what bitrate actually _is_.

That experiment led to a key conclusion:

> **bitrate is not a parameter, it is an emergent property of the system**

But there was an obvious limitation:

- no network
- no SFU
- no real-world topology

So the natural next question is:

> **what happens when you insert a real media pipeline in the middle?**

This article answers that question using a minimal
[Mediasoup](https://mediasoup.org/)-based testbed.

## From PeerConnection to SFU: adding one layer of reality

The original setup was deliberately extreme:

- sender and receiver in the same page
- no transport variability
- no routing layer

This time, the experiment introduces a **Mediasoup SFU pipeline**, while still
keeping everything local and controlled.

The idea is not to simulate production, it is to answer:

> **how much does the transport topology itself influence bitrate behavior?**

## The experimental setup

This project mirrors the original benchmark almost one-to-one, but replaces the
direct connection with a Mediasoup routing layer.

As described in the repository, the architecture looks like this:

```
Browser (mediasoup-client)
  → produce(video)
  → send to Mediasoup
  → receive echoed stream
  → collect outbound-rtp stats

Node.js server (minimal HTTP)
  → signaling endpoints

Mediasoup Worker + Router
  → transport creation
  → producer → consumer echo
```

The key difference is subtle but important:

> **the browser is no longer talking to itself, it is talking through an SFU**

## Why this matters

Even in a local environment, introducing Mediasoup changes:

- RTP packetization paths
- transport behavior
- buffering patterns
- encoder feedback loops

And most importantly:

> **it introduces a second system making decisions**

In the first experiment, the browser was both the encoder and the receiver.

Now, the system includes an independent routing layer with its own buffering,
timing, and transport behavior.

This turns a closed system into a distributed one.

Now:

- the browser encodes
- Mediasoup routes
- the browser decodes

That separation is where things start to get interesting.

## Implementation highlights

This testbed is intentionally minimal.

### 1) No framework, no abstraction

The server is plain Node.js HTTP written from scratch, with a single `listening`
callback function doing everything from HTTP methods handling, paths routing,
serving static files, media signaling via POST requests and a REST API, and
managing Mediasoup workers/transports/producers/consumers.

- No Express, no layers, no magic
- Just the signaling required to establish transports

I've done it this way on purpose to keep the system as transparent as possible,
and to make it easier to understand the flow without having to learn a
framework, that ultimately would hide some details and made implementation
dirty. Just Node.js, Mediasoup, and nothing else.

You can see the full implementation at Content-Mediasoup-bandwidth
[server.js](https://github.com/piranna/Content-Mediasoup-bandwidth/blob/main/server.js).

### 2) Explicit codec enforcement (again)

Just like in the previous article:

- codecs are explicitly selected
- fallback is disabled
- negotiation is verified

👉 This is non-negotiable for valid measurements, to ensure that the correct
codec is being used at any time.

### 3) Same measurement model

We keep the same metrics:

- bitrate (payload)
- header bitrate
- packets per second

Derived from `producer.getStats()` and exported as:

```csv
codec,width,height,framerate,max_bps,avg_bps,max_packets,avg_packets
```

👉 This makes both experiments directly comparable, since both of them make use
of the same metrics and export format.

### 4) Identical philosophy: measure, don’t configure

Nothing in this system “sets” bitrate, but everything observes it. Same
principle as before:

> **if you don’t measure it, you don’t understand it**

## The dataset

The current dataset was generated under controlled conditions:

- local loopback (no network impairment)
- mostly synthetic or low-entropy content
- 1 fps sampling for consistency
- resolution sweep across codecs

And processed using an offline script (`npm run plot`) included in the
repository, that parses the CSV data, groups by codec, and which generates a
comparative chart.

(You can find its implementation at Content-Mediasoup-bandwidth
[plot_bitrate.js](https://github.com/piranna/Content-Mediasoup-bandwidth/blob/main/scripts/plot_bitrate.js))

## What changes compared to pure WebRTC?

Here’s the important part.

### 1) The trends remain

This is the most important result:

> **the core conclusions from the original experiment still hold and survive the
> introduction of an SFU**

- AV1 remains the most bitrate-efficient codec
- VP9 generally improves over VP8
- bitrate scaling is still non-linear

This is not trivial. It means the original experiment captured some real
behaviour, it was not an artifact of a simplified setup.

### 2) But the system becomes less “pure”

Even in a local setup, adding Mediasoup introduces:

- additional buffering layers (that add the mentioned extra latency)
- transport abstraction
- slightly different packet timing

This shows up in:

- peak bitrate variations
- packet rate differences
- less “clean” curves

👉 Not dramatically different, but noticeably less deterministic. At that point,
a trivial conclusion can be extrapolated:

> The more actors you introduce into a system, the less deterministic it
> becomes.
>
> And eventually, you stop being able to reason about it without actual
> measurement.

### 3) The pipeline matters

You are not measuring a codec, you are measuring interactions between systems.

This experiment reinforces something important:

> **bitrate is not just about the codec, it is about the entire pipeline**

In practice:

- encoder decisions
- transport behavior
- routing logic

all contribute to what you observe as “bitrate”.

## Connecting this to real-world feedback

After publishing the first article,
[an interesting comment](https://www.linkedin.com/feed/update/urn:li:ugcPost:7454817257844649984?commentUrn=urn%3Ali%3Acomment%3A%28ugcPost%3A7454817257844649984%2C7455172253824135168%29&dashCommentUrn=urn%3Ali%3Afsd_comment%3A%287455172253824135168%2Curn%3Ali%3AugcPost%3A7454817257844649984%29)
from [Tim Panton](https://www.linkedin.com/in/timpanton/) pointed out:

- packet loss increases keyframe frequency
- bitrate becomes bursty
- hardware differences matter

This experiment doesn’t include those factors yet, but it shows something
critical:

> even _before_ adding real-world complexity, the system is already non-trivial

Which implies:

> **real-world WebRTC systems are far more unpredictable than most people
> assume**

## What this setup is actually useful for

Despite being minimal, this testbed is surprisingly practical.

It can help answer:

- which codec to prefer under constrained uplinks (_which codec provides an
  acceptable bandwidth usage for a given resolution under our constraints?_)
- expected bitrate ranges per resolution tier
- how bursty each codec is (_how much high are the peaks compared to the
  average?_)
- how sender caps behave in a real pipeline

And most importantly:

> it gives you a reproducible baseline before adding complexity

## Limitations (again, intentionally)

This experiment still avoids:

- packet loss
- jitter
- multi-peer scenarios
- CPU constraints
- heterogeneous hardware

So results should be interpreted as:

> **baseline behavior, not production reality**

## Where this goes next

The obvious next steps are:

- introduce controlled packet loss (I already did some experiments some months
  ago, it's time to recover them...)
- test multi-peer SFU scenarios
- measure CPU impact per codec
- compare sender caps vs actual bitrate

And eventually:

> **move from “measurement lab” to “real benchmark pipeline”**

## Reference implementation

The full Mediasoup-based testbed is available here:

- Code + dataset: <https://doi.org/10.5281/zenodo.19961277>
- Repository:
  [Content-Mediasoup-bandwidth](https://github.com/piranna/Content-Mediasoup-bandwidth)

## Final thought

The first article showed that bitrate is not a parameter to use, but in fact
it's the output result of combining several parameters.

This one shows something slightly deeper:

> **bitrate is not even a property of the encoder itself, it is a property of
> the system as a whole**

And the moment you add even a minimal SFU layer, you stop measuring a codec.

You start measuring a full pipeline.

Once you introduce real-world network conditions, it starts to feel like riding
a rollercoaster blindfolded.

Which is exactly why measurement matters.

## Related work

- Original experiment:
  [WebRTC bitrate is not what you think](2026-04-28-WebRTC-bitrate-is-not-what-you-think.md)
- Mediasoup testbed:
  [Content-Mediasoup-bandwidth](https://github.com/piranna/Content-Mediasoup-bandwidth)

## Citing

If you reference this work, please cite the article:

```text
Leganés-Combarro, Jesús (2026).
"WebRTC bitrate is not what you think, Part II (Mediasoup edition)"
https://piranna.github.io/2026/05/05/WebRTC-bitrate-is-not-what-you-think,-Part-II-(Mediasoup-edition)/
DOI: 10.5281/zenodo.19988776

Reference implementation:
https://github.com/piranna/Content-PeerConnection-bandwidth
```

---

> Note: As in the previous work, parts of this system were developed with AI
> assistance. All measurements, validation and conclusions are my own.
