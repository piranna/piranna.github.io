---
layout: page
title: Open Source contributions
permalink: /contributions/
---

Most important contributions to third-parties Open Source projects

## [istanbul-js](https://istanbul.js.org/)

`istanbul-js` is a code coverage tool that's being used internally by
[Jest](https://jestjs.io/) testing framework, developed by Facebook and the
current de-facto standard for Node.js, React and Javascript projects. Its
default text output format was too much limited when showing the number of code
coverage missing lines, so I refactored it to reduce the number of decoration
characters and auto-adjust to the width of the terminal by default, in addition
of [grouping ranges](https://github.com/istanbuljs/istanbuljs/pull/525) of
consecutive missing lines to be able to show more of them.

## [node-canvas](https://github.com/Automattic/node-canvas)

As part of the development of [NodeOS](projects#NodeOS) to provide it some basic
graphic capabilities, I added support for configurable backends on
`node-canvas`, with the intention of being able to draw directly on the Linux
`FbDev` framebuffer device instead of just only in memory. Backends support was
already accepted in upstream code, but FbDev code is still pending of approval.
In the future, plan is to add support for other graphic systems like accelerated
Linux DRM/KMS, X11, Windows GDI, or OSX Metal.

This project was later sponsored by [Ventrata](https://ventrata.com/) to add
support for double-buffering, VSync and 24bits color mode.

## Other contributions

- [redux-offline](https://github.com/redux-offline/redux-offline)
- [re-start](https://github.com/react-everywhere/re-start) (AKA
  *ReactNative Everywhere*)
- [num2words](https://pypi.org/project/num2words/)
