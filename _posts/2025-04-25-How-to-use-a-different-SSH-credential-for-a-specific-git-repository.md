---
lang: en
layout: post
title: How to use a different SSH credential for a specific git repository
tags: git, ssh
---

If you have multiple SSH keys and want to use a specific one for a particular Git repository, you can do so by configuring it on the SSH config file:

```config
# ~/.ssh/config

Host gitlab.foo-repo
  HostName gitlab.com
  IdentitiesOnly yes
  IdentityFile ~/.ssh/gitlab_rsa.foo-repo
```

Here we have two key points:

1. The `Host` line is the name of the repository. It doesn't need to be a real
   hostname, but it needs to be unique. The trick here is to use that _domain_
   as the git URL domain. Later the `HostName` line is the actual hostname of
   the repository, like `git@gitlab.foo-repo:user/repo.git`. This is the one
   that will be used to connect to the server.
2. SSH by defult will try to use all the keys available in the `~/.ssh` folder,
   starting by the default key (`~/.ssh/id_rsa`) and then the rest of the keys.
   So, if you already have another key for the same server, it will try to
   connect with that key first. The trick here is to use the
   `IdentitiesOnly yes` line, so it will only use the key specified in the
   `IdentityFile` line.
