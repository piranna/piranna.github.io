---
layout: post
tags: os, lifecycle, npm, automation, github-actions
title: OS lifecycle
twitter: '1240749381231484928'
---

[projectlint](https://github.com/projectlint) is a projects-wide linter and
style checker I've been working on during the last weeks. As part of its set of
rules, [one of them](https://github.com/projectlint/plugin-Operating-System)
ensures that the current version of the operating system where the code is
running is maintained and updated. But, is there a npm package with info about
the operating systems lifecycles? Nope... enter `OS lifecycle`.

[OS lifecycle](https://github.com/projectlint/OS-lifecycle) offer a functions
whom to query for the info of diferent operating systems on a specific date,
inspired on [@pkgjs/nv](https://github.com/pkgjs/nv) package to query info about
maintence of Node.js versions. In addition to that, info is provided in a raw
form in a json file. So far this is a simple package... What's interesting is
how the json file is generated.

`OS lifecycle` code has two differenciated parts, the builder and the querier
(in fact, the builder would make sense to move it to another module...). Builder
is a [script](https://github.com/projectlint/OS-lifecycle/blob/master/server.js)
that fetch and agregate the info from several operative systems sites, currently
[Carnegie Mellon University](https://computing.cs.cmu.edu/desktop/os-lifecycle.html)
SCS Computing Facilities as base info for several operating systems, and the
[Ubuntu releases](https://wiki.ubuntu.com/Releases) for more up-to-date info for
Ubuntu operating sytem, with the intention of adding other sources in the
future. This sites provides the info as HTML tables, so is being used the
[tabletojson](https://github.com/maugenst/tabletojson) package to extract it
(with some tune-ups to add support for rowspan cells).

So far, this is a regular web scrapper that needs to be executed by hand. I've
used [Github Actions](https://github.com/features/actions) to automate it,
checking at midnight if there was updates in the data sources that day. This are
versioned stored in the git repo by creating new commits using the
[git-auto-commit](https://github.com/stefanzweifel/git-auto-commit-action)
action. Thing is, Github Actions v1 was more powerful (and resources consuming)
than v2 and was trying to publish all nightly versions (crashing the workflow
with an error due to trying to overwrite the previous versions in the `npm`
registry also when there was no updates in the data), so `git-auto-commit`
[needed to notify it](https://github.com/stefanzweifel/git-auto-commit-action/issues/46)
so next steps could be skipped. I would have prefer to fully stop the workflow
instead of doing that hack, but Github Actions v2 removed neutral output
[on purposse](https://twitter.com/ethomson/status/1163899559279497217):

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">We did, we&#39;ll have a different neutral exit strategy. `exit 78` seems unique, but isn&#39;t. (eg, `git merge` exits with the number of conflicts encountered.)</p>&mdash; Edward Thomson (@ethomson) <a href="https://twitter.com/ethomson/status/1163899559279497217?ref_src=twsrc%5Etfw">August 20, 2019</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

Good thing, this hack showed me
[how to define environment variables](https://help.github.com/en/actions/building-actions/metadata-syntax-for-github-actions#outputs)
in the workflow, and it was almost equal to
[how Azure pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch#set-a-job-scoped-variable-from-a-script)
does it (as I learned just some weeks ago [at work](https://www.botxo.ai/)), so
in the same style I added a `--print` argument to show the new version and use
it not only to have nicer commit messages and tags... but also to detect if
there was updates in the data sources and short-circuit the call to the
`git-auto-commit` action itself :-)

And that's it! With all these steps, finally I've been able to fully automate
the data scraping and normalization, and to publish the newly generated packages
both on [npm](https://www.npmjs.com/package/@projectlint/os-lifecycle) and
[Github Packages](https://github.com/projectlint/OS-lifecycle/packages/94821)
registry... a bit of duplicated effort now that
[Github has bought npm](https://github.blog/2020-03-16-npm-is-joining-github/)
:-P
