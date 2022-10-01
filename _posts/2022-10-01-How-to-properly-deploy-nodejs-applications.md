---
lang: en
layout: post
title: How to (properly) deploy Node.js applications
---

Recently I've been involved in a new Typescript project all of my own where I
would end up deploying it on production on a raw AWS machine, so no help from
dev friendly PaaSs environments, as I usually prefer to work.

I always disagreed with the idea of uploading the code directly to the server or
Docker image both by hand or with `git clone` and transpile it on the server the
same way I do in my development machine, both due to security issues (**NEVER**
have a compiler on a publicly accesible server, you are just only making it
easier to run an exploit and install a backdoor to your machine... or worse),
and because none of them are standard procedures. On the other hand, I've always
found the [npm pack](https://docs.npmjs.com/cli/v8/commands/npm-pack) command
like it's being missused, people relying just only on
[npm publish](https://docs.npmjs.com/cli/v8/commands/npm-publish) (that uses
`npm pack` internally), while it's being in fact designed to prepare and pack
ready to use Node.js packages, and people usually ends up doing any other more
convoluted and insecure aproaches just because they are not willing to publish
their server code in the [npm registry](https://www.npmjs.com/) or
[Github Packages Registry](https://github.com/features/packages) thinking it
will make them be available to anybody (maybe they don't know it's possible to
have private packages in both
[npm registry](https://docs.npmjs.com/about-private-packages) and
[Github Packages Registry](https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility)?),
or they don't want to deal with the hassle of access to private packages, or
they just doesn't know how to do it.

So, since I was fully responsible of this project and had total freedom about
how to develop it, I decided to give `npm pack` a try and see how well it could
fit for deployment of private servers in raw machines... and must to say, it has
gone REALLY well 😎

## Pack the package

First of all, we need to automate transpilation of the Typescript code. Usually
build command is included in a `build` script, so we need to run it when `npm`
run the
[prepare](https://docs.npmjs.com/cli/v8/using-npm/scripts#prepare-and-prepublish)
script. `prepare` script is not only being run internally by `npm pack` to
prepare the package before it's being published, but also is being run when the
package itself is being used as a dependency directly from a git repository, so
by adding the `prepare` script, it will help us on the development stage too:

```json
{
  "scripts": {
    "build": "tsc",
    "prepare": "npm run build"
  }
}
```

Once package can be automatically build, we need to deploy it. For this, I've
added a custom `deploy` script that both pack the package itself, and later
upload it to the AWS server. For the packaging I'm just using the `npm pack`
command to generate a tarfile with the content of the package. This tarfile can
be later uploaded to a static HTTP server and use its URL as dependency, or
install it directly from the filesystem, we can use it however we want. In my
case, it's a server app instead of a library, so for the upload, I'm just only
using `scp` to copy the generated tarfile to the server, no more. Before that, I
needed  to set up my private key on the server, and whitelist my public IP to be
able to access to the server. Due to that, as a nice extra, I've also add a
`ssh` script that opens me a SSH session on the server, just as a convenience
:-) :

```json
{
  "scripts": {
    "deploy": "npm pack && npm run upload",
    "ssh": "ssh ubuntu@ip-10-0-4-9.ap-south-1.compute.internal",
    "upload": "scp *.tgz ubuntu@ip-10-0-4-9.ap-south-1.compute.internal:"
  }
}
```

## Executables

This config would be enough for libraries, but we are publishing an executable,
so we need to define it in the `package.json` file so it gets automated for us.
This is done by setting the
[bin](https://docs.npmjs.com/cli/v8/configuring-npm/package-json#bin) field to
the executable file (Node.js standard is `server.js`, and in fact it's
`package.json` default value for the `start` script; for
[Express](https://expressjs.com/) apps convention is `app.js`):

```json
{
  "bin": "server.js"
}
```

In my case, I was running a [Fastify](https://www.fastify.io/) app by using the
[fastify-cli](https://github.com/fastify/fastify-cli) tool, so I need to use a
customized `start` script. So, to run it, we need to point the `bin` field to a
shell script that will run it in our name:

```bash
#!/usr/bin/env bash

set -Eeuo pipefail

PREFIX=$(dirname `dirname -- "$( readlink -f -- "$0"; )";`)

npm start --prefix $PREFIX -- "$@"
```

This is a bit convoluted because when running `npm start`, it will search by
default for a `package.json` file both in the current folder or upper ones, and
if `npm` doesn't find it, it will give us a
`npm ERR! enoent ENOENT: no such file or directory, open '/home/ubuntu/package.json'`
error. So, to prevent it, we need to tell `npm` explicitly where the correct
`package.json` that needs to be run is located by using the
[--prefix](https://docs.npmjs.com/cli/v8/commands/npm-prefix) flag, that (since
I have that script inside a `bin` folder inside my project) it's in the parent
folder of where's the script is located, so we get the resolved path of the
script and later the parent dir of its container dir.

Finally, to install and run the executable in the package, we can just execute
[npx](https://www.npmjs.com/package/npx) giving the tarfile as the package name
to be installed locally and executed...

```sh
npx ll-hls-streamer-0.0.0.tgz
```

...or we can install the package
[globally](https://docs.npmjs.com/downloading-and-installing-packages-globally)
and have the executable available in our path as any other regular system wide
installed application:

```sh
sudo npm install -g ll-hls-streamer-0.0.0.tgz

ll-hls-streamer
```
