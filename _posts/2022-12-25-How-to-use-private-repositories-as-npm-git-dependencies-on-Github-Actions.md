---
lang: en
layout: post
tags: Mafalda SFU
title: How to use private repositories as npm git dependencies on Github Actions
twitter: '1607096594700140544'
---

I'm advocate of automatization, and that includes not only CI/CD pipelines, but
also I wanted to do it for documentation publishing.
[Mafalda](https://mafalda.io/) is split in a lot of packages (currently more
than 30!), so I wanted to have a single place where to publish the documentation
of all of them. [Github Pages](https://pages.github.com/) allows to host a
website for your organization or username by free (this blog and personal site
[already makes use of it](https://github.com/piranna/piranna.github.io)), and it
can also host automatically a website for each repository as sub-paths of your
username/organization main website. Problem is, that it only works for open
source repositories or for paid plans, and most of the Mafalda SFU repositories
are private ones. So since the Mafalda SFU project website is already hosted on
Github Pages as a
[public repository](https://github.com/Mafalda-SFU/Mafalda-SFU.github.io), I
decided to store and serve from it all the other repositories documentation as
well... doing it in an automated way :-)

The task can be splitted in two halves:
[generate the documentation](#generate-the-documentation), and
[publish it](#publish-the-documentation).

## TL;DR

This is the Github Actions workflow I'm using to tests the different Mafalda
SFU sub-projects, generate their documentation, and publish it to the Mafalda
SFU project website:

```yaml
name: test, build documentation and publish

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - uses: webfactory/ssh-agent@v0.7.0
        with:
          ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}

      - run: npm ci
      - run: npm test
      - run: npm run docs

      - uses: cpina/github-action-push-to-another-repository@v1.5.1
        env:
          SSH_DEPLOY_KEY: ${{ secrets.SSH_DEPLOY_KEY }}
        with:
          destination-github-username: Mafalda-SFU
          destination-repository-name: Mafalda-SFU.github.io
          source-directory: docs
          target-directory: docs/${{ github.event.repository.name }}
          user-email: bot@mafalda.io
          user-name: Mafalda bot
```

## Generate the documentation

To automatically generate the documentation, we have two aproaches: generate it
as a [git hook](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks), or do
it on the CI servers. I use to prefer the first option, specially for complex
projects where people of different levels are working on the code (like Juniors
& Seniors, or new employees), or for the projects where the documentation is
going to be directly published on Github Pages (like open source projects) so
the documentation is close to the code as reference, and also it's possible to
see how it has evolved during the time. But since it's not possible to publish
it as I've already said it before (if not, I would not be writing this post
:-) ), it has had more weight my policy of not having generated code or
artifacts stored as part of the source code of the git repository itself, so I
decided to generate the documentation on the CI servers.

To generate the documentation, I'm using the
[jsdoc-to-markdown](https://github.com/jsdoc2md/jsdoc-to-markdown) package. This
imply to need to install the project dependencies on the CI servers, and this is
where the problem arises: since I have not published any of the Mafalda SFU
dependencies as a npm package, I need to use them as git dependencies, and being
private ones, the Github Actions CI servers needs permissions to access to them.
In normal conditions where only it's accessed the repo itself, or when using
private packages from the
[Github Packages Registry](https://github.com/features/packages), it's enough
with the `GITHUB_TOKEN` secret or with a
[Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token),
but since we're using git dependencies, it's not possible to use them to
authenticate the git requests, only possible is with git credentials and/or an
SSH key pair.

The first thing I've done is to create a new
[machine user](https://docs.github.com/en/developers/overview/managing-deploy-keys#machine-users)
account to authenticate and operate from Github Actions. This is for security, I
could have used my own account, but then all operations would have been done in
my name. This way, it's possible to have a separate user with the lowest needed
permissions (in this case just only read access to the private repositories,
that's the one set when adding an user as one of the organization members by
default), and also it's possible to revoke the access to the repositories if
needed. After that, I've created a new SSH key pair, and added the public key to
the Github *machine user* account I've just created before, so it can operate on
the repositories

After that, what we need to do is to add the private key to the Github Actions,
so it can be available when trying to install the git dependencies. This can be
done with the [ssh-agent](https://github.com/webfactory/ssh-agent) action, that
registers globally the provided private key. To do so, we need to set the
private key as one of the repository secrets (it's not possible to add it as an
organization level secret on free plans), and then use it in the config of the
`ssh-agent` action in the `ssh-private-key` parameter. Just with that, we can be
able to install the npm git dependencies from Github Actions CI servers, and
generate our documentation.

## Publish the documentation

Once that we have the documentation generated, it's time to copy it to the main
repository. This is done with the
[github-action-push-to-another-repository](https://cpina.github.io/push-to-another-repository-docs/)
action, that can push the contents of a directory to another repository
different of the one where the action is running on. The config of the action is
pretty straighforward, just setting the
[source directory](https://cpina.github.io/push-to-another-repository-docs/configuration.html#source-directory)
from where to copy the files, the
[destination repository name](https://cpina.github.io/push-to-another-repository-docs/configuration.html#destination-repository-name),
the
[Github username/organization](https://cpina.github.io/push-to-another-repository-docs/configuration.html#destination-github-username)
that owns the destination repository, and the
[target directory](https://cpina.github.io/push-to-another-repository-docs/configuration.html#target-directory-optional)
where to copy them (this is important, by default it fully wipes the target
repository). Just by config that parameters it would work, but commits would be
mostly annonimous, so it's better to also set the
[user name](https://cpina.github.io/push-to-another-repository-docs/configuration.html#user-name-optional)
and
[user email](https://cpina.github.io/push-to-another-repository-docs/configuration.html#user-email-optional)
that will be used to commit the changes.

The only tricky part of configuring `github-action-push-to-another-repository`
is the access to the repository itself, since we need to provide another
credentials with write access. The most safe way to do it is to
[create a new SSH deploy key](https://cpina.github.io/push-to-another-repository-docs/setup-using-ssh-deploy-keys.html#setup-ssh-deploy-keys)
that will be used to provide write access *only* on the destination repository,
in this case the main documentation one. This is done by creating a new SSH key
pair, and adding the public key to the destination repository as a deploy key
with write access. Then, we need to add the private key as one of the repository
secrets, and use it in the config of the action in the `SSH_DEPLOY_KEY`. After
that, each time that the action is executed, it will push the generated
documentation to the main repository, creating a new commit with the user email
and name that we provided, and a commit message pointing to the original commit
in the source repository where we generated the documentation from, having this
way a two-ways cross-reference.
