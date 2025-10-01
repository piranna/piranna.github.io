---
layout: post
tags: blog, github, jekyll, tutorial
title: How to have a blog on Github
twitter: '1225206478035963905'
---

Since I was a child I never liked to write. I was more a thinker, a tinker and a
doer, and found really tedious to start writing ideas that I could already do,
explain or show. In fact, I hated the idea of receiving a diary as a present for
making my first Communion (somewhat typical here at Spain, and luckily didn't
happen to me) because I found boring to write about things that already have
happened while I would be creating new ones. The same reason why I'm not too
much into blogs (both writing and reading) because I pay too much attention to
what I say and how I do it, and get to be really slow to get fully polished my
final text (I mostly did my bachelor thesis code in 6 months... and later
spended other 14 months more just for writting the project memory. It's ironic
that the times I got to write something, people got surprised that I have a
somewhat good style... and more ironic that having written so much (open)
source code, probably in lines number I could be able to make both Dan Brown
and J.K. Rowling to fall on their knees :-P Unluckily, they have got more
revenues for their jobs than me, good for them :-)

Anyway, the point is that I was told some time ago by
[Adrian Ferreres](https://twitter.com/ardiadrianadri) (and after that by some
more people) that I should try to improve my digital image by writing a blog
where to talk about my crazy projects and ideas, so people can be able to know
what I was working on. I had one in Blogger due to my participation in the
[CUSL](https://concursosoftwarelibre.org) and created a new one just for
[NodeOS](https://node-os.com/) with an own engine that used Github issues as
[blog entries](https://github.com/NodeOS/GitBlog). I started a new one in Medium
because "all people is there now", and although it's nice for writters, it's not
for coders like me. I need a place where to put code samples easily and where I
could be able to just drop some quick one-liner notes with links, random ideas
or little paragraphs small enough for a blog post but bigger enough to don't get
into a tweet. A plus would be to support markdown and easily have a copy of if
both wherever I go and online. [Dev.io](https://dev.to) is really interesting
(and I should be reading it A LOT more...) and should consider to use it as
blog, but as I've just said I'm not into the blogging scene, and also I would
like both to have control and not lost my blog posts, and have some greater
visibility on social networks. So, I needed to find an alternative using what
I get more use to. And what are the pages I'm connected in an almost daily
basis? [Github](https://github.com/piranna) and
[Twitter](https://twitter.com/el_piranna).

Github not only works as my online portafolio by having a single place where all
my open source projects are published, but also has support to publish web sites
using [Github Pages](https://pages.github.com/), so it makes sense to have the
blog near to my projects. It also allows me to have an easily accesible copy of
the blog sources so I can edit and move them wherever I want, and since it's
heavily integrated with Github, I can edit them with markdown the same way as
all my other documentation (more preciselly
[Github Flavourse Markdown](https://github.github.com/gfm/), one of the most
complete markdown syntaxes), and have syntax highlight support by free. This
integration also includes the ability to show project pages as sub-paths of your
personal domain, so it seems to be the perfect place to host a (techie geekie)
blog :-)

## Create the blog

The first step is to create the blog itself. Github Pages has been used for a
[lot of use cases](https://github.com/cristinafsanz/github-pages) where a static
site is enough (also as a cheap CDN...). Since it will be used as my main blog
and website, I'm going to generate it as a "user site". This means that it will
be available under a domain like http://piranna.github.io (you can be able later
to config a custom domain to redirect to it, if you want), and for doing so,
it's just enough by creating a Github repo with the name `piranna.github.io`.

Github Pages are powered by [Jekyll](https://jekyllrb.com/), a generator of
static web sites. It could be possible to create it from scratch (an
`index.html` or a `README.md` file are just enought), but to make it easier and
faster, I'm going to use [Jekyll Now](https://github.com/barryclark/jekyll-now).
It provides an already configured Jekyll site ready to be used as a blog by
default and enabled to make use of [Disqus](https://disqus.com/) comments and
[Google Analytics](https://analytics.google.com/), and since it's a plain Jekyll
site, you can later customize it yourself.

Jekyll Now has the problem than the original project owner is missing with no
activity in two years and the project seems to be unmaintained, so things like
changing the theme using the Github own
[Jekyll Theme Chooser](https://help.github.com/articles/adding-a-jekyll-theme-to-your-github-pages-site-with-the-jekyll-theme-chooser/)
or [Jekyll themes](https://help.github.com/articles/about-jekyll-themes-on-github/)
doesn't work, and changing the theme needs to be done by hand, or you can fix the
bug by [deleting](https://github.com/barryclark/jekyll-now/issues/745#issuecomment-364339715)
the `_layouts/default.html` so it doesn't overwrites the one in the selected
theme (since now it's possible to use external templates, it should be moved to
one of them). Due to this things, that's why I've proposed to
[fork the project](https://github.com/barryclark/jekyll-now/issues/1352) and
maintain it collaboratelly (in-real-life problems of project developers and
maintainers or also their death are by far, with the burn-out of not being
payed nor recognized for our work while corps make a bucket of money, the main
problem of Open Source...).

After forking Jekyll Now, the first thing you need to do is to edit the
`_config.yml` file. This is needed for two purposses. The first one is to set
your own information in the blog, like name, email, or online accounts. The
second one is because by forking Jekyll Now you have only got a copy of the blog
code, and by editing the file (and due to this, adding a commit in the repo),
you are forcing Github to exec Jekyll on your repo and generate the static files
and publish your blog online. The most quick and simple way to edit the file is
doing it directly in the browser as it's shown in the instruction of the Jekyll
Now `README.md` file. Alternatively, you can clone your blog repo in your local
machine so you can edit the config and blog posts from your favorite text or
code editor, with the additional benefict of being able to edit your posts
offline. I must to admit I was reticent to use Jekyll due to this (I wanted to
do it online from anywhere), but it's more confortable and I'm still able to do
it online with the Github online code editor :-) Finally, after submitting the
changes, in some seconds you'll have your blog online.

## Customize your blog

Jekyll Now has customized the format of the blog posts paths, that it's showing
just only the post title. I find it nicer to have the date since I'm planning to
use the blog to also store random notes too small to be blog posts by themselves
(somewhat similar to [Tumblr](https://www.tumblr.com)), so in `_config.yml` file
I'll change the `permalink` attribute from `/:title/` to the default `pretty`
format to include them.

### Twitter as comments system

Jekyll Now includes support to use Disqus as blog comments platform. This makes
sense because it uses the current URL as ID for the comments box, but I find it
too much invasive, and there are serious concerns about security issues. I've
found [several alternatives](https://darekkay.com/blog/static-site-comments/) to
have comments in a static blog like Jekyll, some of them really interesting like
[using Github issues as comments platform](http://donw.io/post/github-comments/)
(something similar to what I already did for [NodeOS](https://node-os.com) with
[GitBlog](https://github.com/NodeOS/GitBlog)), or to use Jekyll data files to
[store the comments](https://haacked.com/archive/2018/06/24/comments-for-jekyll-blogs/)
(so this way they could be stored in the same repo than the blog itself) or in
Google Spreadsheets, and also there are tools like
[staticman](https://staticman.net/) that can be able to automate the process.
For a standalone blog, probably I would have choosen that last option, so this
way I could be able to have both posts and comments on a single place ready to
be moved elsewhere, but since I wanted to use my blog as a promotion tool too, I
found it better to use Twitter threads instead, so they can be used both to
publish about new blog posts, and to use the replies as the comments themselves.
Unluckily it seems Twitter has changed the format of its embed widget and it's
not possible to show tweet threads (just only the context of the tweet it's
responding from), so now instead of showing embeded threads, just only show a
direct link to the Tweet published about your blog post, so people will need to
navigate there to see and comment your post. It's the problem with Internet data
silos again, if you don't like them, maybe one alternative storing the blog
comments in Github as previosly explained (probably I'll do this in the future,
since Twitter is becoming a toxic place anyway...), or having your own server
would fit better.

To use Twitter as a comments platform, the process needs to be split in two
tasks: publish the posts in Twitter, and show the Twitter threads in the blog
itself. For the first one, I took the idea from
https://ictsolved.github.io/blog/blogging/auto-post-articles-from-jekyll-blog-to-social-sites
where show how to use [IFTTT](https://ifttt.com/) to publish new tweets from
your blog RSS feed. The title is a bit fake since it only shows how to do it
with Twitter, but it's interesting since it's easy to do and also it's done in a
way where just only publish the most recent one and not all the posts in the
feed. Regarding putting the Twitter threads in the post, at
https://flamiszoltan.me/twitter-as-comment-system propose a system where the
tweet ID is added manually to the blog posts
[front matter](https://jekyllrb.com/docs/front-matter/) (the mechanism that
Jekyll has to add metadata to the markdown files) and used to render the tweets
thread. After that, it's just a matter of having some code in the blog posts
layout to add the tweet thread. The code shown there is bare enough to show the
tweet based on the "embed tweet" link, and also includes some code to show a
card in your published tweet that improve the appearance of the tweet itself, so
it complements the blog posts publication using IFTTT.

When I started with the idea of using Github as a blog platform, one of my
intents was to publish the blog posts and show the twitter threads automatically
in the blog posts themselves, so since I was not able to find an already done
solution, I crafted it myself.

[Jekyll Social](https://github.com/piranna/jekyll-social) is a CLI tool (build
in Node.js, as usual :-P) that inspect all the blog posts in a Jekyll
repository, publish the non-already published ones to several social networks
(at the moment just only Twitter, but it's designed to be easily extensible, and
I plan to add shortly support for [LinkedIn](https://www.linkedin.com/)), AND
update the blog posts front matters and commit them back to the Github
repository, all from a single shoot :-) And not only that, but I've also decided
to use it to learn how to use the new
[Github Actions](https://github.com/features/actions) to do the automation part.
I'm planning to do a new blog post in the near future showing how Jekyll Social
works and what I've learned crafting it in detail, but for now, to use it in
your blog is just a matter of creating a new workflow for a `push` event, using
`piranna/jekyll-social@master` as action with the `GITHUB_TOKEN` secret enabled,
and a new secret `social` with a JSON string with the Twitter auth credentials,
and Jekyll Social will auto-detect all the remaining configuration. Take in
account that due to some limits in GitHub Actions, it's not possible to force a
GitHub Pages render by using a `GITHUB_TOKEN` secret, only with user tokens, so
until it gets fixed, you'll need to also set a `user_access_token` secret too.

## Online edition

Now that we have the blog up and running and tweets are being shown as comments
system, how to edit the blog posts online? Easy, the same way we modified before
the `_config.yml` file to bootstrap the render of the pages, we can do the same
to create new blog entries. Just only you need to go the the `_posts` folder in
your blog repo, and create a new file with its name in the format
`<year>-<month>-<day>-<post url title>.md`. After that, you can edit your blog
post using Markdown. This is the basic default form, but you can add some extra
metadata by adding a [front matter](https://jekyllrb.com/docs/front-matter/),
that's small fragment with a [yaml](https://yaml.org/) structure at begin of the
file. You can then define there as metadata a clean `title` for the page, or the
`layout` that it should have if you've defined several of them, for example.
Anyway, it would be easier if you do it downloading your blog repo with `git`
and edit its pages using your favorite text editor.

## Future work

And that's it! Now you have your blog hosted on github, having full control of
your posts :-) Besides that, there are some other improvements that can be done
in the future, like storing the blog comments directly on Github itself, to also
keep control over them. In the end it's a Jekyll website, so you can do whatever
you want with it :-) Happy blogging! :-D
