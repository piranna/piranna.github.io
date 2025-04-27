---
lang: en
layout: post
tags: python, ubuntu, howto, mediasoup
title: How to install Python 2.7 on Ubuntu 24.04 (24.10)
---

Recently I needed to work on the upgrade and migration of a project that was
using [Mediasoup](https://mediasoup.org/)... version 1.2.8, published
[8 years ago](https://github.com/versatica/mediasoup/commit/b09ff006416058719061ea002129e7f0666c9b99)
and totally outdated up to the point that the documentation for that version was
[removed from the Mediasoup website](https://mediasoup.org/documentation/v1/):

> mediasoup v1 is no longer documented. Sorry. Anyway it's no longer maintained
> so please move to the latest version.

So being so much obsolete, to install the project and run it I needed to install
a couple of things first:

1. [Node.js 10.24.1](https://nodejs.org/es/blog/release/v10.24.1), the last
   Node.js version published of the 10.x family, because there was other
   dependencies that were not compatible with newer versions and crashed the
   `npm install` process,
2. and [Python 2.7.18](https://www.python.org/downloads/release/python-2718/),
   the last Python version published of the 2.x family, because Mediasoup needs
   it to compile the C++ code that is used for its Worker processes.

Installing Node.js 10 was easy, just by using
[nvm](https://github.com/nvm-sh/nvm) and executing the following commands:

```sh
nvm install 10.24.1
nvm use 10.24.1
```

we already had Node.js 10.24.1 installed and ready to use with npm 6.14.12. But
for installing Python 2.7, it was a bit more complicated, since it was
deprecated and removed from the Ubuntu 24.04 repositories, leaving just only
Python 3.x versions available. One option is to compile it from source, but I
prefer to avoid that and use a package manager to install it, if possible. The
best solution would be to use the
[deadsnakes PPA](https://launchpad.net/~deadsnakes/+archive/ubuntu/ppa), but for
Ubuntu 24.04 and newer it only provides Python 3.x versions. The solution was to
do the things _by hand_, downloading and installing the deb packages for Ubuntu
22.04 instead:

```sh
BASE_URL=https://launchpad.net/ubuntu/+archive/primary/+files

wget \
  $BASE_URL/libpython2.7-minimal_2.7.18-13ubuntu1.5_amd64.deb \
  $BASE_URL/libpython2.7-stdlib_2.7.18-13ubuntu1.5_amd64.deb \
  $BASE_URL/python2.7_2.7.18-13ubuntu1.5_amd64.deb \
  $BASE_URL/python2.7-minimal_2.7.18-13ubuntu1.5_amd64.deb

sudo dpkg --install \
  libpython2.7-minimal_2.7.18-13ubuntu1.5_amd64.deb \
  libpython2.7-stdlib_2.7.18-13ubuntu1.5_amd64.deb \
  python2.7_2.7.18-13ubuntu1.5_amd64.deb \
  python2.7-minimal_2.7.18-13ubuntu1.5_amd64.deb
```

With this, we had Python 2.7 installed and ready to use, but the problem is that
Mediasoup built scripts use the `python2` command, that's not available. On a
regular installation from Ubuntu repositories, the `python2` symlink would be
provided by the `python2` package, but we don't have it accessible (we could, if
we used the packages from the Ubuntu repositories instead of directly the ones
from Launchpad), so instead we do the linking manually with the
`update-alternatives` system:

```sh
sudo update-alternatives --install \
   /usr/bin/python2 python2 /usr/bin/python2.7 18
```

And with this, we already have Python 2.7 installed and ready to use with the
`python2` command, and without interfering with the system default Python 3.x:

```console
> python2
Python 2.7.18 (default, Dec  9 2024, 18:47:23)
[GCC 11.4.0] on linux2
Type "help", "copyright", "credits" or "license" for more information.
>>>
```
