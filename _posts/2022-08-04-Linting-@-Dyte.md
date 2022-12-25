---
lang: en
layout: post
title: Linting @ Dyte
twitter: '1607096592103866369'
---

*Corporate version previously published at <https://dyte.io/blog/linting-at-dyte>*

At [Dyte](https://www.dyte.io/) we are now 44 persons, most of them developers,
and each one has his own personal code style. This has lead sometimes to huge
code conflicts when doing merges that create some annoyances and delays, so we
decided to create an unified linting code style for all of Dyte projects
(including a Jira ticket too!), just only we have been procrastinating it due to
some other priorities. So, after the last merge conflict in a new project just
created some days before, we decided to fix that issue once for all. Come and
follow us to see how at Dyte we take code quality serious, and how at Dyte we
don’t just simply apply a linter to our source code.

![Dyte does not simple apply a linter to its code](../images/2022-08-04-Linting-@-Dyte.jpg)

## Linting

As linting engine we’ll make use of [eslint](https://eslint.org/), that’s one of
the current most popular and configurable linting engines for Javascript and
Typescript. In that way, `@dyte-in/eslint-config` package is the central element
for our unified linting scheme, since it host the
[shareable config](https://eslint.org/docs/developer-guide/shareable-configs)
with all our customized linting rules. Later each project can extend the rules
applying their own project specific ones, although we’ve adjusted the common
rules to be used without needing to do any extra customizations.

Shareable config is defined in the `.eslint.js` file, being it the package main
export. It can feels extrange to use a hidden file, but that’s on purposse since
it’s one of the filenames that eslint uses when looking for a project config, so
this way we can reuse it to lint the shareable config project itself. That’s the
reason why we are exporting it as a Javascript file instead of as a static JSON
one, too.

The shareable config extends and enable rules from
[eslint:recommended](https://eslint.org/docs/rules/) and
[import/recommended](https://www.npmjs.com/package/eslint-plugin-import)
configs, and for Typescript files it additionally makes use of the
[typescript-eslint/recommended and typescript-eslint/recommended-requiring-type-checking configs](https://github.com/typescript-eslint/typescript-eslint/tree/main/packages/eslint-plugin#recommended-configs).
This last one makes use of the actual tsconfig.json file being used by the
project, so our config also looks for and uses it automatically on the project
root, including when using an eslint custom named one, like
`tsconfig.eslint.json` file.

Regarding the rules that we’ve enabled or customized to our usage habits, the
most interesting ones are:

- [consistent-return](https://eslint.org/docs/rules/consistent-return): enforces
  returned values are of the same type. This has helped us to find A LOT of bugs
  where we were returning `undefined` to notify failure instead of throwing an
  exception (or by the case, returning a failed Promise), probably due to some
  legacy code from [EduMeet](https://github.com/edumeet/edumeet) project that
  Dyte used on its origins.
- [import/order](https://github.com/import-js/eslint-plugin-import/blob/main/docs/rules/order.md):
  ensure all `import` statements are sorted alphabetically, for tidyness and
  prevent duplicates or misconfigurations.
- [max-len](https://eslint.org/docs/rules/max-len): strict length of lines,
  where we’ve customized it to allow unlimited length only on commen lines with
  an URL, so we doesn’t break it.
- [no-restricted-globals](https://eslint.org/docs/rules/no-restricted-globals)
  and
  [no-restricted-properties](https://eslint.org/docs/rules/no-restricted-properties):
  configured to prevent usage of deprecated global `event` variable (due to
  being in most of the cases a bug) and usage of setInterval statement (due to
  performance and runtime execution stability).

And for Typescript specific rules, the most interesting ones are:

- [@typescript-eslint/ban-ts-comment](https://github.com/typescript-eslint/typescript-eslint/blob/main/packages/eslint-plugin/docs/rules/ban-ts-comment.md):
  forbid usage of `ts-comment`s to disable Typescript checkings without a
  detailed reason of why it has been disabled.
- Multiple rules to notify of usage of unsafe `any` type.
- [no-restricted-syntax](https://eslint.org/docs/rules/no-restricted-syntax):
  configured to prevent usage of Typescript `private` keyword instead of
  Javascript `#[private]` class members.

To use the `eslint-config` package is just like using any other `eslint` shared
config, and you only need two steps:

1. install the package as a devDependency:

   ```jsx
   npm install --save-dev @dyte-in/eslint-config
   ```

2. extends the eslint config from our project `.eslintrc` file. Since package
   follows the `@<scope>/eslint-config` name, eslint will detect and find it
   from the `node_modules` folder automatically, so it’s only needed to provide
   the scope name:

   ```json
   {
     "extends": ["@dyte-in"]
   }
   ```

## Semantic releases

After finishing implementing the
[eslint-config](https://www.notion.so/Linting-Dyte-79cec456569d47b8bf9a22b0ab2d2d37)
package, it was time to publish it so all the other projects can use it as a
`devDependency`. At Dyte we are using the
[semantic-release](https://github.com/semantic-release/semantic-release) tool to
automate the publish and release of packages new versions, just only we were
copying its configuration by hand. It showed us to be ironic to unify and
automate the linting rules configuration, while at the same time we needed to
copy again by hand the semantic release configuration, so we decided to fix that
too. Not only that, but also it made usage of `semantic-release` easier by not
needing to install all the release process dependencies, since they are already
installed by the `semantic-release-config` package itself.

Similar to eslint-config package, we created a
[shareable configuration](https://semantic-release.gitbook.io/semantic-release/usage/shareable-configurations)
where to store all our common release configurations. This is stored in a
[release.config.js](https://semantic-release.gitbook.io/semantic-release/usage/configuration)
file that’s exported as package `main` entry for the same reasons we did
something similar with eslint-config `.eslintrc.js` one: to be able to make use
of the config on the project itself, so we can automate the semantic releases of
the `semantic-release-config` package itself.

In contrast to `eslint-config`, rules are more generic, just only
[analyzing the commit](https://github.com/semantic-release/commit-analyzer),
generating the
[release notes](https://github.com/semantic-release/release-notes-generator) and
the [changelog](https://github.com/semantic-release/changelog) (and upgrading
the package version number), and publishing the package release in both the
[Github Packages Registry](https://github.com/semantic-release/npm) and as
[an asset of the Github release](https://github.com/semantic-release/github).
Only interesting points are that we detect the environment we are working on and
flag the release as a `prerelease` in case we are running in our staging
(preproduction) environment, and that we don’t
[commit the release version upgrade changes](https://github.com/semantic-release/git)
in the source code if all the previous steps has been succesful.

To use the `semantic-release-config` package is only needed two steps:

1. install the package as a devDependency:

   ```jsx
   npm install --save-dev @dyte-in/semantic-release-config
   ```

2. configure semantic-release in `.releaserc` file:

   ```json
   {
     "extends": "@dyte-in/semantic-release-config"
   }
   ```

To run the `semanic-release` command, it's recommended to install the
`semantic-release` package as devDependency and add a `semanic-release` script
in the `package.json` file:

```json
{
  "scripts": {
    "semanic-release": "semantic-release"
  }
}
```

## Releases in Github Actions

Now that we have created the packages for the unified `eslint` and
`semantic-release` configs, it’s time to use them in all the other projects. And
yes, both `@dyte-in/eslint-config` and `@dyte-in/semantic-release-config` are
devDependencies between them and makes use one of the other, but I’m not talking
about that, but about the *other* projects.

Since we are using kubernetes to deploy our systems (and by extension, Docker), we needed some way to provide access to private packages in Github Packages Registry from inside Docker containers. The way we were doing it was by providing a custom `NPM_TOKEN` environment variable (that in fact host a Github [Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)), and use it as `authToken` for the Github Packages Registry entry in the project [.npmrc](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-npm-registry#installing-a-package) file used to define that project dependencies need to be fetch from the Github Packages Registry. Problem with this aproach is that it requires a token with elevated permissions (including write packages) for all the operations related to npm packages also when they are not needed (more specifically, install packages), not allowing a fine grain access control opening a security threat. But more specially, it prevented developers to install packages easily in local environments by not using standard location for users [npmrc authentication](https://docs.npmjs.com/cli/v8/configuring-npm/npmrc). This has given us problems in the past, both to setup local environments, but also to install packages inside [Github Actions](https://github.com/features/actions) CI servers, since token needed to be provided read access by hand for all the repos that would need to be used from.

For that reasons, we decided to take an aproach more aligned on how [Github Actions](https://github.com/features/actions) works, allowing us to simplify the process by removing the addition of useless environment variables, and make it more secure. The first step was obviously remove the usage of the `NPM_TOKEN` inside the project `.npmrc` file, and any other environment variable being set in the [Github environment variables](https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#setting-an-environment-variable), setting them instead as [env](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#jobsjob_idstepsenv) entries of the `npm install` and `npm ci` Github Actions steps, and replace it in all the config files it was being used in the project for `GITHUB_TOKEN`, the Github Actions standard default one with lowered permissions (mostly just only read access to the repos). In local environments, it would be using the standard global `~/.npmrc` auth config, so developers would just need to authenticate agains Github Packages Registry only once and forget about it.

```yaml
- run: npm install
  env:
    NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

On the other hand, for the Github Actions steps that will publish the packages, we’ll use the `npm` Github Action standard `NODE_AUTH_TOKEN` environment variable with the same Github Personal Access Token we were using before, since it’s just needed only to [publish packages](https://docs.github.com/en/actions/publishing-packages/publishing-nodejs-packages#publishing-packages-to-the-npm-registry). We’ll use to assign the Github Access Token to the `GITHUB_TOKEN` environment variable to create the Github release itself, too. There’s a little push down though: Docker containers are fully isolated from the host environment, so usage of the [registry-url](https://github.com/actions/setup-node/blob/eeb10cff27034e7acf239c5d29f62154018672fd/action.yml#L17-L18) field in the Github standard [setup-node](https://github.com/actions/setup-node) action will not work. We’ll need to replicate what `setup-node` does… that in fact, it overwrites and updates the content of the project `.npmrc` file to add explicitly the line with the token, just the same way we were doing before 😅 just only using the standard `NODE_AUTH_TOKEN` environment variable, and doing it in the checkout code without commiting and pushing it afterwards, so it’s safe to do the modification. In our case, we are doing it [inside the Docker container](https://stackoverflow.com/a/69848428/586382) itself, so we are equaly safe here 🙂

```docker
RUN echo //npm.pkg.github.com/:_authToken=$NODE_AUTH_TOKEN >> .npmrc
```

## Bonus: print secrets in Github Actions

Github Action detects when you want to print a secret on the console, so it prevents to get them logged by replacing the secret strings with `***`. Sometimes we need to get them printed for debugging purposses, so we need to trick it. The most simple way is to just concatenate the output with the secret using the unix [sed](https://en.wikipedia.org/wiki/Sed) command to [split the secret string using spaces](https://zellwk.com/blog/debug-github-actions-secret/):

```yaml
run: echo ${{secrets.YOUR_SECRET }} | sed 's/./& /g'
```

This way, Github Action could not match the output with any of the stored secrets, and would print the string verbatin.

**Disclaimer**: please don’t do that with your production secrets, just use some ones deditated for testing purposses, and ideally one-use-only throw away ones.
