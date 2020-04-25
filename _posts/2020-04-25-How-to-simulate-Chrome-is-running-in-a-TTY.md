---
image: 2020-04-25-How-to-simulate-Chrome-is-running-in-a-TTY.png
image_alt: >-
  Screenshot of the blog with `tty` media rule and a custom terminal inspired
  CSS stylesheet enabled
layout: post
title: How to simulate Chrome is running in a TTY
twitter: '1254121252001910791'
---

I've always loved terminals and retro-computing. I find they were a technology
that didn't got fully their full potential due to graphical interfaces (it's
strange I say this since my first computer was a
[Macintosh LC II](https://en.wikipedia.org/wiki/Macintosh_LC_II) at a time where
everybody else had at most a PC with
[Windows 3.11](https://en.wikipedia.org/wiki/Windows_3.1x)...). That's the main
reason I added support for
[Unicode BPM plain in Linux kernel](https://github.com/NodeOS/cjktty-patch) for
[NodeOS](https://node-os.com/), specially to have available the Braille patters
used by [blessed-contrib](https://github.com/yaronn/blessed-contrib) to draw
graphical diagrams in the terminal. That's the reason why when I discovered
[BOOTSTRA.386](https://github.com/kristopolous/BOOTSTRA.386) project, a
[Bootstrap](https://getbootstrap.com/) theme that mimics a text-mode interface
in a website similar to old
[BBSs](https://en.wikipedia.org/wiki/Bulletin_board_system) (fathers of web
forums, and grandfathers of current online walls), I got enthusiastic about the
idea of making it
[compatible with real terminal web browsers](https://github.com/kristopolous/BOOTSTRA.386/issues/59)
like [Links](http://links.twibright.com/), [w3m](http://w3m.sourceforge.net/) or
[Lynx](https://lynx.invisible-island.net/).

Web pages are independent of the platform they are rendered, being a screen or
printed in paper or using a screen reader for visually imparied persons, so
doing the adaptation for a terminal output using CSS stylesheets made totally
sense (and it's the correct way to do it, and yes, text-mode web browsers
support CSS too). The key here to make the text-mode detection work was the
[`tty` media type](https://drafts.csswg.org/mediaqueries/#media-types),
but it got deprecated in benefict of using
[media features](https://drafts.csswg.org/mediaqueries/#mq-features), that offer
a more fine-grained control of the representation features of web browsers, in
our case the [grid](https://drafts.csswg.org/mediaqueries/#grid) media feature.

The problem is that the
[Chrome DevTools](https://developers.google.com/web/tools/chrome-devtools) just
only allow by default to simulate `print` media type, and usage of real
text-mode web browsers like `links`, `lynx` or `w3m` are not so much developer
friendly, so how can be able to simulate other media devices? Using directly the
[Chrome DevTools protocol](https://chromedevtools.github.io/devtools-protocol/)
by hand to force Chrome browser to show the media features that we want, that's
how Chrome DevTools inpect and modify the web pages, but first we need to get
access to it. We can use a custom client, or hack the Chrome DevTools. Since
it's already a web page itself, we need to
[open the devtools-on-devtools](https://stackoverflow.com/a/12291163/586382)
page. This way we will have two instances of Chrome DevTools, one of the page we
are testing as usual, and another one of it DevTools page, from where we have
access to the DevTools Protocol client in the console to be able to send low
level commands to the web browser (yes, some of the web browser automation tools
are using the DevTools Protocol under the hood, but now they are moving to the
browser agnostic [WebDriver](https://www.w3.org/TR/webdriver/) standard).

Once we have access to the DevTools Protocol, the first thing is to be sure we
can send emulation commands to the web browser. To do so, we use the
[Emulation.canEmulate](https://chromedevtools.github.io/devtools-protocol/tot/Emulation/#method-canEmulate)
command, so in the devtools-on-devtools console we write:

```js
let Main = await import('./main/main.js');
await Main.MainImpl.sendOverProtocol('Emulation.canEmulate');
```

This will get us a reference to the DevTools Protocol client in `Main.MainImpl`
and return us an array with result objects (seems the protocol allow to send
several commands in batch) like this:

```javascript
[{result: true}]
```

If it returns `true`, then we can send emulation commands. The one we are
interested about is
[Emulation.setEmulatedMedia](https://chromedevtools.github.io/devtools-protocol/tot/Emulation/#method-setEmulatedMedia),
that allow us to emulate the media type or features that we want, in this case
the `grid` media feature. We open the MDN example page for the
[`grid` media feature](https://mdn.mozillademos.org/en-US/docs/Web/CSS/@media/grid$samples/Example?revision=1506717)
and call the `Emulation.setEmulatedMedia` in the console to enable it...

```javascript
await Main.MainImpl.sendOverProtocol('Emulation.setEmulatedMedia', {
  features: [{name: 'grid', value: '1'}],
});
```

...and if it went well, we would get an array with an empty object as response.
Note that `value` needs to be a string independently of the value the media
feature accept (in the case of `grid` media feature, it's
[mq-boolean](https://www.w3.org/TR/mediaqueries-4/#typedef-mq-boolean)), or if
not, we would get an error instead:

```javascript
{code: -32602, message: "Invalid parameters", data: "features.0.value: string value expected"}
```

(Descriptive and context aware error messages, kudos.)

Now the tricky part, how to check that it worked? One could think about using
the (maybe undocumented?) `Emulation.getEmulatedMedia` command...

```javascript
await Main.MainImpl.sendOverProtocol('Emulation.getEmulatedMedia');
```

but it didn't exist at all:

```javascript
{code: -32601, message: "'Emulation.getEmulatedMedia' wasn't found"}
```

On the other hand, `CSS.getMediaQueries` allow to get the actual state of all
the web page CSS queries...

```javascript
await Main.MainImpl.sendOverProtocol('CSS.getMediaQueries');
```

...but it shows us that the query for the `grid` media feature is still disabled
:-/

```javascript
[
  {
    medias: [
      {text: "print", source: "mediaRule", styleSheetId: "30394.6"},
      {
        mediaList: [
          {expressions: [{value: 0, unit: "", feature: "grid"}], active: true}
        ],
        range: {startLine: 5, startColumn: 7, endLine: 5, endColumn: 16},
        source: "mediaRule",
        sourceURL: "https://mdn.mozillademos.org/en-US/docs/Web/CSS/@media/grid$samples/Example?revision=1506717",
        styleSheetId: "30394.5",
        text: "(grid: 0)"
      },
      {
        mediaList: [
          {expressions: [{value: 1, unit: "", feature: "grid"}], active: false}
        ],
        range: {startLine: 16, startColumn: 7, endLine: 16, endColumn: 16},
        source: "mediaRule",
        sourceURL: "https://mdn.mozillademos.org/en-US/docs/Web/CSS/@media/grid$samples/Example?revision=1506717",
        styleSheetId: "30394.5",
        text: "(grid: 1)"
        }
    ]
  }
]
```

Reloading the page didn't work (being a device feature that usually doesn't
change in runtime, it made sense that would be evaluated only at page load...),
so I checked for the
[`monochrome` media feature](https://www.w3.org/TR/mediaqueries-4/#monochrome),
since it use an integer value in case the problem was with the `mq-boolean`
type, but it didn't work too. Just to be sure, I decided to check with a
feature that's currently possible to emulate on Chrome DevTools,
[prefers-color-scheme](https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-color-scheme):

```javascript
await Main.MainImpl.sendOverProtocol('Emulation.setEmulatedMedia', {
  features: [{name: 'prefers-color-scheme', value: 'light'}],
});
```

And this worked, so seems to me that Chrome only detect the other ones as valid
ones, but their values are hardcoded and can't be modified at runtime. In any
case, Chrome is focused for modern desktop computers with full-color graphical
interfaces... :-/

I was going to desist and get to the conclusion that it was not possible, when I
got an idea: `grid` media feature is the new way to detect that a browser is
working on a device with fixed width characters, so maybe it could be still
unimplemented, but maybe the deprecated `tty` media is still available? It's
possible to change it with the Chrome DevTools anyway, so it's a matter of send
the command with a different string, so I changed the media queries in the web
page...

```css
@media tty {
  body {
    font-family: monospace;
  }
}
```

...and tried it...

```javascript
await Main.MainImpl.sendOverProtocol('Emulation.setEmulatedMedia', {
  media: 'tty'
});
```

And it worked!!! :-D Now when changing the CSS media between `tty`, `screen` or
`print` it correctly detected and stylesheets change, yeah! :-D Mostly a useless
thing because there's almost no grid web devices out there, but being capable of
properly support them in a standard way has removed me an ich in the back of my
head. At least, now this blog is one of the few sites that support them... :-D

![Screenshot of the blog with `tty` media rule and a custom terminal inspired CSS stylesheet enabled](/images/2020-04-25-How-to-simulate-Chrome-is-running-in-a-TTY.png "Screenshot of the blog with `tty` media rule and a custom terminal inspired CSS stylesheet enabled")

Next step, create a terminal inspired CSS stylesheet to use as base one when
designing terminal compatible websites... and find a way to override some of the
values (more specifically, the font sizes) over the ones defined by the web site
(AKA user stylesheets).

**BONUS**: adding a CSS stylesheet in Chrome DevTools by editing the elements
panel as HTML doesn't works (or at least it didn't worked to me) because by
doing so it seems you are modifying the `text` attribute, while it's needed to
modify the `textContent` one instead. It's possible to do it in Javascript by
[creating an `script` element](https://stackoverflow.com/a/15506705/586382) and
appending it to the document `HEAD` :-)
