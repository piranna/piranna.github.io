---
lang: en
layout: post
title: How to get all branches from a git remote and push them to a new remote
tags: git, howto
---

```config
git push newremote refs/remotes/oldremote/*:refs/heads/*
```

This command will push all branches from the `oldremote` to the `newremote`. The
`refs/remotes/oldremote/*` part specifies that we want to push all branches from
the `oldremote`, and the `refs/heads/*` part specifies that we want to push them
to the `newremote` as branches.

For tags, that would not be a problem, just `git push newremote --tags` would be
enough.

Found at <https://www.metaltoad.com/blog/git-push-all-branches-new-remote>.
