---
lang: en
layout: post
tags:
  - docker
  - linux
  - appliance
  - immutable
  - bootable
  - edge
  - iot
  - satellite
  - media
  - gateway
title: Turning a Docker Image into a Bootable Immutable Linux Appliance
---

> Containers gave us reproducible application filesystems. Kubernetes allowed us
> to deploy them at scale on the cloud. But for edge appliances, IoT devices,
> satellites, media gateways, and even unattended devices, the next step is
> making that filesystem bootable, immutable, verifiable, and explicitly
> persistent only where intended.

## **0. Introduction**

Containers changed how we build and ship software.

They gave us reproducible environments, portable application bundles, and a
clean separation between what we build and where we run it. Tools like Docker
and Kubernetes made it trivial to deploy the same application across laptops,
servers, and cloud infrastructure with a level of consistency that was
unthinkable a decade ago.

But containers solved only part of the problem.

They gave us reproducible _filesystems_, not reproducible _systems_.

In the cloud, this distinction rarely matters. Containers run on top of a host
operating system that handles boot, hardware, drivers, updates, and persistence.
If something goes wrong, the platform recovers, restarts, or replaces the
container.

At the edge, things are very different.

Devices such as media gateways, IoT appliances, satellite communication units,
or unattended systems deployed in remote or hostile environments cannot rely on
an external orchestrator to fix problems.

There is no Kubernetes cluster to reschedule workloads. No SSH access for
debugging. Often, no human intervention at all to config, debug or update them,
not even remotely. These systems must work on their own reliably, securely, and
correctly, from the very first boot.

Sometimes it's possible to use a Docker-alike or Docker-optimized operating
system like [BalenaOS](https://www.balena.io/os),
[Rancher](https://www.rancher.com/) or [Ubuntu Core](https://ubuntu.com/core),
but even then, the container runtime is another extra layer in a complex stack
that can fail in unexpected ways.

In these scenarios, the system itself should be:

- **immutable**, to prevent unintended changes or persistence after compromise
- **minimal**, to reduce attack surface and failure modes
- **reproducible**, so it can be rebuilt and verified deterministically
- **explicitly persistent only where intended**, instead of allowing writes
  anywhere in the filesystem

These are not just optimizations: they became invariants. This is where the
container model starts to show its limits, compared to native installs.

Even when hardened, containers still depend on runtime configuration to enforce
critical properties:

- a container is only read-only if someone remembers to pass `--read-only` at
  runtime, or configure it in the orchestrator
- writable layers still exist conceptually, even if restricted
- the filesystem is not truly immutable at the kernel level
- the system is not bootable on its own

In other words: a container _looks_ like a system, but it's _not_ one (yet).

This raises an interesting question:

> **What if a container image could become the operating system itself?**

This is not a new idea, but it is rarely explored end-to-end. Not
metaphorically, but literally:

- the container root filesystem becomes the system root
- it is packaged as a real read-only filesystem
- it is booted directly by a Linux kernel
- it runs without a shell, without a package manager, and without mutable state
- persistence is explicit and isolated, like a Docker volume

This article explores that idea end-to-end.

Starting from a standard container build process, we will:

- construct a minimal Ubuntu-based root filesystem using Canonical Chisel
- separate application artifacts from licensing and compliance data (to reduce
  final image size, while retaining legal compliance and auditability)
- analyze the limitations of Docker’s read-only model
- enforce immutability at runtime without relying on a shell
- convert the container filesystem into a real read-only filesystem using EROFS
- make it bootable using a Unified Kernel Image
- design a minimal init system with explicit persistence

The goal is not to replace containers, but to extend their model:

> **from “application packaging” to “system definition”.**

By the end, we will have something that behaves less like a traditional Linux
distribution and more like a firmware-like appliance:

- deterministic
- minimal
- verifiable
- and intentionally constrained

A system where nothing changes unless we explicitly allow it.

If containers were the first step in making infrastructure reproducible, with
Kubernetes being its extension to the cloud and its scalability, then this is
the next step in making infrastructure reproducible at the edge:

> **turning that reproducibility into something you can actually boot, and
> trust.**

## **1. From Containers to System Images**

LXC Containers are often described as “lightweight virtual machines”. That’s
convenient, but misleading.

A container image is not an operating system, nor an installer of it. It is, at
best, a **packaged root filesystem**: a collection of files arranged in a
Unix-like hierarchy, layered and distributed through the
[Open Container Initiative](https://opencontainers.org/) (OCI) format. It
contains binaries, libraries, configuration, and metadata; but it does not
include a kernel, it does not boot by itself, and it does not define how it
should be executed at the system level.

And yet, conceptually, it is already _very close_ to a full operating system.

### **1.1 What a Docker Image Really Is**

An OCI image is essentially:

- a set of filesystem layers (tar archives)
- a JSON configuration (entrypoint, environment, working directory)
- metadata describing how to assemble those layers

When executed through a runtime like [Docker](https://www.docker.com/),
[Vagga](https://vagga.readthedocs.io/), [Podman](https://podman.io/), or
[containerd](https://containerd.io/), this filesystem is:

- unpacked or mounted (often via
  [OverlayFS](https://www.kernel.org/doc/html/latest/filesystems/overlayfs.html))
- combined with a host kernel
- executed as a process (or set of processes)

From the perspective of the application, it _looks like an operating system_. It
has:

- `/usr`, `/lib`, `/etc` directories
- a process tree
- a filesystem root

But this is an illusion, a deception set up by the container runtime just for
the application.

The container does not own:

- the kernel
- the boot process
- the filesystem semantics
- the persistence model

All of those are external.

### **1.2 Why a Container Is Not an Operating System**

There are four fundamental gaps between a container image and a real system:

#### **No Kernel Ownership**

Containers share the host kernel. This is a feature in cloud environments (and a
good one: it save RAM, storage and CPU resources compared to VMs, while
retaining almost the same isolation capabilities), but a limitation in edge or
appliance scenarios where kernel configuration (drivers, scheduler, features...)
is part of the system design.

#### **No Boot Process**

A container does not define how a system starts. There is no firmware, no
bootloader, no kernel handoff, no init sequence. Execution begins at an
[entrypoint](https://docs.docker.com/reference/dockerfile/#entrypoint), injected
externally by the runtime.

#### **Mutable Runtime Assumptions**

Even if an image is designed and built as “immutable”, its runtime is not by
default:

- writable layers may exist
- `/tmp` and other paths can be modified
- `--read-only` is optional and externally enforced

The image itself cannot guarantee immutability.

#### **Externalized Persistence**

Persistence is not intrinsic. It is delegated to volumes, bind mounts, or
orchestrators. The system has no native concept of “this data must survive a
reboot”, you can write on the container filesystem, but depending how it's run,
it could dissapear once the container stops, or the next time the container
image is updated (ironically, like formatting a hard disk partition and
reinstalling the operating system from scratch).

### **1.3 What We Actually Want**

If we step back from the container abstraction and look at real-world systems
(especially outside the cloud) the requirements change.

In environments such as:

- edge devices
- embedded systems
- media gateways
- offline-first applications
- unattended infrastructure

we typically want:

- **Reproducibility**: the system can be rebuilt exactly
- **Immutability**: the base system cannot be modified at runtime
- **Minimalism**: only the required components are present
- **Explicit persistence**: writable state is clearly defined and isolated
- **Verifiability**: the system can be validated (or even cryptographically
  verified)

Containers solve the first problem very well, but they only partially address
the rest.

### **1.4 The Missing Step: Treating the Container as a RootFS**

The key insight is simple:

> A container image is already almost a root filesystem. We just don’t treat it
> like one.

Instead of thinking:

```text
container → runtime → process
```

we can shift to:

```text
container → root filesystem → system image → bootable appliance
```

This reframing changes everything.

Once we treat the container as a **rootfs artifact**, we can:

- extract it
- transform it
- mount it using real filesystem drivers
- boot a kernel against it
- define persistence explicitly

At that point, the container is no longer just only a deployment unit. It
becomes instead a packaging tool, and the foundation of a full-fledged operating
system.

### **1.5 From Cloud Abstraction to Bare-Metal Reality**

In cloud environments, containers are intentionally incomplete. They provide a
minimal, naïve abstraction of an operating system since they are focused only on
isolating some applications from others, and rely on the underlying platform
layers to provide the rest:

- scheduling
- networking
- storage
- lifecycle management

But in edge or appliance scenarios, those layers often do not exist, or cannot
be trusted.

The system must be:

- self-contained
- deterministic
- resilient to failure
- secure by construction

This is where the container model begins to show its limits... and at the same
time, where it becomes interesting again, because instead of abandoning
containers, by filling the missing gaps we can **extend their model downward**:

- from application packaging
- to system construction
- to bootable, immutable infrastructure

### **1.6 A Change in Perspective**

This is not about replacing containers, It is about completing them.

Containers gave us a way to define _what a system should look like_. What they
lack is a way to define _how that system comes to life_.

The rest of this article explores how to close that gap:

- building a minimal root filesystem
- enforcing immutability beyond the container runtime
- converting that filesystem into a real, read-only image
- and finally, booting it as a complete system

---

If Section 1 te encaja así, el siguiente paso natural es:

👉 **Section 2 — Building a Minimal RootFS (Chisel approach)**

Ahí empezamos ya con lo tangible y donde empieza a brillar tu implementación.

> Note: Parts of this work were developed with the assistance of AI tools. All
> opinions, ideas, experiments, validations and conclusions are my own.
