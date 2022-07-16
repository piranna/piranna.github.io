---
lang: en
layout: post
title: How to use a different email for a group of git repositories
twitter: '1548423325302415360'
---

If you have a folder with multiple repositories that you want your commits use a
different email account, but keep using your (personal) one for anything else,
you can do it in two steps:

1. create a new file with the git config that you want to use (not only email,
   you can change anything) for the repositories. For tidyness, I set it at the
   repositories folder named `gitconfig.ini`, since `.gitconfig` file uses the
   [ini file format](https://en.wikipedia.org/wiki/INI_file).

   ```ini
   [user]
     email = <your-new-email>
   ```

2. include the file in your `.gitconfig` file, only for the repositories on that
   folder.

   ```ini
   [includeIf "gitdir:~/<your-grouped-repositories-folder>/"]
     path = ~/<your-grouped-repositories-folder>/gitconfig.ini
   ```

Now any commit that you do on the repositories stored under
`~/<your-grouped-repositories-folder>` folder will be done with the new email.
Don't forget to register your new email account as an alias on your
[Github account](https://github.com/settings/emails) or cloud git provider, so
your commits can be binded to your personal account.
