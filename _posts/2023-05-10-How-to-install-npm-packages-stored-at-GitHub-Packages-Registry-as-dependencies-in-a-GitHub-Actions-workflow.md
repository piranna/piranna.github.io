---
lang: en
layout: post
tags: Mafalda SFU
title: How to install npm packages stored at GitHub Packages Registry as dependencies in a GitHub Actions workflow
---

When working on `npm` projects with multiple subprojects as dependencies,
there's a problem when you need to do frequent updates. Ideally, that
dependencies should have their own tests and versioning, but that's not always
possible (for example, private packages) and sometimes we would need to publish
multiple development versions while trying to debug some obscure issues. This
is tedious and nasty, so that's why so much people like monorepos.

Problem with them, is that `npm` was designed with modularity on mind, and tried
to enforce the "one package, one repo" identity. That's why native support for
monorepos and workspaces has been delayed for so much time. I personally agree
with that original `npm` concept, so a simple solution that I usually use are
[git dependencies](https://docs.npmjs.com/cli/v9/configuring-npm/package-json#git-urls-as-dependencies),
and fetch them directly from git repositories. Problem with that aproach is that
their own `devDependencies` are being installed too, making the install process
longer, specially when some of them need to be transpiled or compiled. This can
be a problem on Github Actions, since it seems there's a timeout of 10-15
minutes for each workflow step.

So, the solution for that would be to create new standalone packages, and
install them. For private ones, one of the best options is to publish them on
[Github Packages Registry](https://github.com/features/packages). Problem with
that is that it requires authentication also for public packages, so we need to
configure its access on our workflow, and it's not so easy as it should be, nor
documentation is fully clear about that. So after trying several aproachs and
reading a lot of posts and comments, I was able to understand how they works,
and get the minimal needed config with the less permissions (no need of creating
and using
[Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token))
to make it work, and understand why that configs are needed.

There are two places were we need to configure the access to the registry: on
the workflow that's going to install the packages, and on the access
permissions of the package itself.

On the workflow, we need to do the next configurations:

1. Add read access to organization packages on the `GITHUB_TOKEN` secret:

   ```yaml
   permissions:
     contents: read
     packages: read
   ```

   Although it's the default value, We need to also define the `contents: read`
   permission because setting the `permissions` key fully overwrittes the
   previous value, instead of just cascade mask it. If we don't do that, the
   `checkout` Github Action would fail to download the code of the repo itself
   due to not having permissions (a bit dumb in my opinion, specially since it's
   enabled by default).

2. Configure the registry URL on the `setup-node` Github Action to point to
   Github Packages Registry:

   ```yaml
   - uses: actions/setup-node@v3
     with:
       registry-url: https://npm.pkg.github.com
   ```

   This can seem obvious, but the docs lead to think that just by setting the
   auth token would be enough to use it, that's not the case. Also you could
   think that by defining the scope in a `.npmrc` file and upload it to the repo
   would be enough, but the fact is that the
   [setup-node](https://github.com/actions/setup-node) overwrites its content,
   so any config there will be lost. If possible, it's better to publish
   packages in both [npmjs](http://npmjs.org/) and Github Packages Registry,
   add the `.npmrc` file to the `.npmignore`file, and left it as a per-user
   config just only to use the Github Packages Registry for development
   purposes, as it's intended for.

3. Use `GITHUB_TOKEN` as `NODE_AUTH_TOKEN` environment variable when installing
   the dependencies:

   ```yaml
   - run: npm ci --verbose
     env:
       NODE_AUTH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
   ```

   Since we added before the `packages: read`, we don't need to use a
   `Personal Access Token` anymore.

   (The `--verbose` flag of `npm` is not needed, but it's really useful to know
   when an install process has failed when running the workflow)

Now that we have properly configured the workflow to politely ask for the
packages, it's time to provide access to them. For that, we need to go to the
target dependency package settings, and configure what repos can have workflows
that can access to them. Not doing so, will result in a 403
`Permission permission_denied: read_package` error when trying to install them.
This will need to be done not only for the direct dependencies, but for all the
packages in the dependencies tree with the defined scope, so instead of
providing access repository by repository and package by package, if you are
using [Github Enterprise](https://github.com/enterprise) you can define the
packages visibility as `internal` instead of `private`, and they'll be
accessible to all the repos of the organization (that's the default behaviour
for Github Enterprise organizations, by the way).

## Bonuses

I've found that defining a scope-to-registry map in the `.npmrc` file force all
requests to go there, so although Github Packages Registry can proxy packages to
`npmjs` registry, it's not being done for the actual scoped packages, so it's
not possible to have some packages published on `npmjs` and other ones on Github
Packages Registry with the same scope and use both: if you define a scope on the
file, all the needed packages need to be hosted on that registry, so it's better
to publish all of them to both registries, or left Github Packages Registry just
only for in-development packages, that's its real purpose, not for general
consumption. Failing to do so, you'll get a confusing error about the package
doesn't exist.

I've also found that removing the `.npmrc` file and running `npm install` is not
enough to update the `package-lock.json` file, but instead packages defined
there will still be downloaded from the previous registry until you delete and
re-create the `package-lock.json` file again.
