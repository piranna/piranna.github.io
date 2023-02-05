---
lang: en
layout: post
title: Profiling `npm install` times
---

When installing Mafalda packets, a problem I've suffered several times are
install times, specially since I'm using git dependencies. I tried to reduce
times by [publishing](https://www.npmjs.com/org/mafalda) some of the most common
packages to npm, so removing need to install and compile development
dependencies like Typescript, but still install times were huge for no reason,
so I needed some way to measure the install time of *each one* of the
dependencies. This lead out options like
[UNIX time command](https://man7.org/linux/man-pages/man1/time.1.html) or tools
like [slow-deps](https://www.npmjs.com/package/slow-deps), so just by change, I
[found on StackOverflow](https://stackoverflow.com/a/39991677/586382) a
reference to [gnomon](https://github.com/paypal/gnomon).

`gnomon` just only prepend timestamp information to the standard output of
another command, so it's a bit crude for my use case, but with some tweaking can
provide the needed info. In this case, by running `npm install` in verbose mode,
we can get detailed info of each one of the steps it follows, so we can measure
its time delay. Just only, `npm install` provides that info in `stderr` (non
sense, what is using `stdout` for?), so we need to redirect it first so `gnomon`
can get it on its `stdin`:

```sh
npm install --verbose 2>&1 | gnomon
```

This will show the output in two columns, being the timestamps in the left one.
On average, it looks like 90% takes less than 1 second and 99% less than 10
seconds... but there's a 1% of outliers that get up to 1 minute or more.
Focusing on that ones, we find two of them (output is truncated for brevity):

```js
...
  12.8811s   npm http fetch GET 200 https://registry.npmjs.org/@jscpd%2fhtml-reporter 2117ms (cache revalidated)
   0.2557s   npm http fetch GET 200 https://registry.npmjs.org/ws 258ms (cache revalidated)
...
  59.4045s   npm http fetch GET 200 https://codeload.github.com/Mafalda-SFU/on-change/tar.gz/718eda3ad6c777f7f8df08908603aab8e9f1082e 1325ms (cache revalidated)
   1.1857s   npm info run bcrypt@5.0.1 install node_modules/bcrypt node-pre-gyp install --fallback-to-build
...
```

`gnomon` show the time each line has been the last one shown in the terminal, so
that time correspond to the generation of *the next line*. This is particularly
useful when showing "starting..." lines, to know in what task this time has been
employed so much, but when showing only the conclusions (like it's the case), we
need to focus on the next line instead.

Total time, 206.7054s, whom 12 are spent on downloading
[ws](https://github.com/websockets/ws) package, and a full minute compiling
[bcrypt](https://www.npmjs.com/package/bcrypt) instead of using a prebuild
image. It's a bit too much, but since the total time is just a bit over 3
minutes, and the problem is probably due to use Node.js v19.4.0 instead of a LTS
version, I would not worry too much.

Another project I have been having more important problems with install time has
been the Remote Mediasoup integration tests, where install of *all* Mafalda
subprojects is involved, and in fact Github Actions cancel the job step after
about 10-12 minutes (does it has a timeout, or it thinks I'm mining
cryptocurrencies?). So checking with `gnomon`, the timings percentages seems
similar, just only we found the outliers got rampage:

```js
...
  34.4881s   npm verb logfile /home/piranna/.npm/_logs/2023-02-05T11_55_57_787Z-debug-0.log
   0.2060s   npm http fetch GET 200 https://registry.npmjs.org/@mafalda%2feslint-config 2345ms (cache revalidated)
...
  13.4045s   npm http fetch GET 200 https://registry.npmjs.org/@piranna%2frpc 1680ms (cache revalidated)
   0.1576s   npm http fetch GET 200 https://registry.npmjs.org/@xmldom%2fxmldom 227ms (cache revalidated)
...
 743.5718s   npm http fetch GET 200 https://codeload.github.com/Mafalda-SFU/multi-map/tar.gz/08f018c637bd1261558fecaf3998e099298dca14 1340ms (cache revalidated)
   0.0409s   npm info run @mafalda/mediasoup@3.11.8 install node_modules/@mafalda/mediasoup node npm-scripts.js install
...
 188.7822s   npm info run @mafalda/rope-client@0.0.0 postinstall { code: 0, signal: null }
   0.1286s   npm info run mediasoup@3.10.5 postinstall { code: 0, signal: null }
```

Total time, 1059.6964s (18 minutes), whom of them 34 seconds are spent on
downloading Mafalda
[eslint-config](https://github.com/Mafalda-SFU/eslint-config) package (hum? Why
so much?), and 15 minutes compiling both Mafalda custom Mediasoup prebuilds and
the regular one
([there are some incompatibilities starting on version 3.10.6](https://github.com/versatica/mediasoup/issues/982)
that prevent using the latest one with Mafalda, working on fixing them at this
moment).

Mediasoup, *what else?*

[Mediasoup](https://mediasoup.org/) by design is compiled on destination
platform at install time, so it can take a lot of time to install with all CPU
cores at 100% and the machine totally unresponsive (and I have a laptop with 20
CPU cores...). That's why I've
[tried in the past](https://github.com/dyte-in/mediasoup/pkgs/npm/mediasoup) and
[now again](https://www.npmjs.com/package/@mafalda/mediasoup) to generate and
publish automated prebuilds of Mediasoup with a
[nightly](https://github.com/Mafalda-SFU/mediasoup/blob/v3/.github/workflows/nightly.yaml)
Github Action. I hope to make them work properly with newer versions of the
prebuild images.

In any case, my internet connection is not very fast or stable, so it's not
surprising that it takes so long to download all the packages or there are so
much differences between them, and results are not conclusive but provides a
good guidance. Probably with a better internet connection, it could show the
bottleneck is somewhere else, probably at the compilation of packages. In
addition to that, a good improvement for `gnomon` or a similar tool would be to
add statistics about CPU load, to see what are the installed packages that put
more pressure on the install process.
