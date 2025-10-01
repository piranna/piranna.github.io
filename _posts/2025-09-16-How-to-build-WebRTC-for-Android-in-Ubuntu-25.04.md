---
lang: en
layout: post
redirect_from:
  - /2021/04/23/How-to-build-WebRTC-for-Android-in-Ubuntu-21.04/
  - /2023/02/27/How-to-build-WebRTC-for-Android-in-Ubuntu-22.04/
tags: webrtc, android, ubuntu, build, libwebrtc, aar, mediasoup, sfu, video, streaming
title: How to build WebRTC for Android in Ubuntu 25.04
---

Google used to provide
[prebuild Android images](https://bintray.com/google/webrtc/google-webrtc) of
`libWebRTC` library, and in fact, it's (still) the recomended way to use them on
[its own documentation](https://webrtc.github.io/webrtc-org/native-code/android/#prebuilt-libraries).
But starting on WebRTC M80 release (January 2020), they decided to
[deprecate the binary mobile libraries](https://groups.google.com/g/discuss-webrtc/c/Ozvbd0p7Q1Y/m/M4WN2cRKCwAJ),
and the reasons were that the builds were intended just only for development
purposes, and
[users were already building it themselves with their own customizations, or using third party libraries that embedded them](https://bloggeek.me/how-to-pick-the-right-webrtc-mobile-sdk-build-for-your-application/)
(where have been left developers that just want to build a WebRTC enabled mobile
app?), and they just only provided another build in August 2020 (1.0.32006) to
fill some important security holes, in case someone (everybody?) was still using
the binary mobile libraries.

**Editor's note**: original version for Ubuntu 21.04 at April 23rd 2021. Content
updated to reflect the latest changes in the build process for Ubuntu 22.04 at
February 27th 2023, and for Ubuntu 25.04 at September 16th 2025.

In addition to that, that binary libraries were available to use with Maven, but
[Bintray was deprecated](https://jfrog.com/blog/into-the-sunset-bintray-jcenter-gocenter-and-chartcenter/)
on May 1st 2021, and they were not be available after February 1st 2022, so the
binary mobile libraries are not available when using Maven itself.

Due to both problems (no new libraries versions, and not sure about future
availability  of current ones), and since I've been not able to find other
online providers for the binary libraries, best option seems to waste some hard
disk space (16GB... it downloads all the Chrome source code and the build
environment tools) and compile them myself. The automated build script that
generates the binary mobile library `.aar` file was published and
[there are instructions to build it yourself](https://medium.com/@abdularis/how-to-compile-native-webrtc-from-source-for-android-d0bac8e4c933),
that's a huge advantage over needing to compile and build the libraries yourself
by hand. But while I was using it, I found some issues and errors in the
instructions themselves when executing them on Ubuntu 25.04 and newer versions,
so here are the fixed instructions with some additional comments:

1. **Create a new folder where to work in**. This seems obvious, but if not,
   you'll end up filling with garbage your `$HOME` directory (I'm n00b). Maybe
   having there the tools and a big `src/` folder where to host all company
   projects makes sense inside Google organization...:

   ```sh
   mkdir webrtc_android
   cd webrtc_android
   ```

2. **Download the Chromium `depot_tools`**, and export them:

   ```sh
   git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
   export PATH=$PATH:$PWD/depot_tools
   ```

3. **Install the `python` command**. `depot_tools` makes use of the `python`
   executable, because it's compatible with both Python 2 and 3. On Ubuntu
   25.04 it's not available since it was traditionally linked to the now
   deprecated Python 2, and to differentiate from it, it was being used the
   `python3` executable, so in a clean slate install, `depot_tools` will fail
   because it's not found. To fix that, we can install the `python-is-python3`
   package:

   ```sh
   sudo apt install python-is-python3
   ```

   I need to check if this is still needed in future Ubuntu releases, but for
   now, it doesn't hurt.

4. **Install [snap](https://snapcraft.io/)**. I hate it (I'm old school, and an
   [APT](https://en.wikipedia.org/wiki/APT_(software)) fan), but now Chromium
   build tools make use of [bazel](https://bazel.build/), and it's only
   available as snap packages, at least for recent versions. I will need to
   review this in the future, but for now, just install it:

   ```sh
   sudo apt install snap
   ```

5. **Configure `git` credentials**. This was not needed before, but now access
   to Chromium source code requires to be authenticated with a Google account.
   To do that, go to <https://webrtc.googlesource.com/new-password> and identify
   yourself with your Google account. It will generate a small script that you
   need to execute in your terminal, and it will generate a `.gitcookies` file
   in your `$HOME` folder with the needed credentials. The generated script
   looks like this:

   ```sh
   eval 'set +o history' 2>/dev/null || setopt HIST_IGNORE_SPACE 2>/dev/null
   touch ~/.gitcookies
   chmod 0600 ~/.gitcookies

   git config --global http.cookiefile ~/.gitcookies

   tr , \\t <<\__END__ >>~/.gitcookies
   webrtc.googlesource.com,FALSE,/,TRUE,2147483647,o,git-jesus.leganes.combarro.gmail.com=1//<long-string-with-access-token>
   webrtc-review.googlesource.com,FALSE,/,TRUE,2147483647,o,git-jesus.leganes.combarro.gmail.com=1//<long-string-with-access-token>
   __END__
   eval 'set -o history' 2>/dev/null || unsetopt HIST_IGNORE_SPACE 2>/dev/null
   ```

6. **Get the build environment tools and Chromium source code** using
   `depot_tools`, and `cd` inside it. This will do a 16GB checkout and compile
   the tools, and it will take **A LONG TIME**. In my case, with 300mbps, 8 CPU
   cores, and 32GB of RAM, it lasted 40 minutes:

   ```sh
   fetch --nohooks webrtc_android
   gclient sync
   cd src
   ```

7. **Update all system dependencies**. It should not be needed, but the fact is
   that building the library has failed me in a slate install of Ubuntu 22.04.
   After updating the system to the latests packages, it worked fine. So, just
   in case, execute the following commands:

   ```sh
   apt update
   apt upgrade
   apt dist-upgrade
   ```

8. **Install build dependencies**. This will download again more dependencies,
   in this case system wide build tools. One of them will be Python 2, so the
   previously installed `python-is-python3` package will be removed:

   ```sh
   ./build/install-build-deps.sh
   ```

   In case you are not using one of the Ubuntu LTS versions, you may need to
   use the `--unsupported` flag to by-pass the version checks and install the
   dependencies, but it didn't worked for me. Your mileage may vary.

9. **Select the release to build**. Until WebRTC M80 release, there were
   branches for each one of the Chromium releases, so it was easy to know what
   version matched each one, but after that, Google started to create branches
   in a daily basis.

   Additionally, some time later they moved out of using regular branches heads
   (referenced at `.git/refs/heads` folder) to use their own `branch-heads`
   references, maybe for public tidyness, or to force devs to use the latest
   code at `main` branch. Using what's currently in `main` or `master` branches
   (they are synced and always point to the same commit) is totally fine, but if
   you want to build the exact copy of the library of a particular release or
   daily branch, we need to recover them. To do it, we need to configure the
   *refspec* to fetch the `branch-heads` references too...

   ```sh
   git config --add remote.origin.fetch \
      '+refs/branch-heads/*:refs/remotes/origin/branch-heads/*'
   ```

   ...and update the local references:

   ```sh
   git remote update
   ```

   , you can search for your desired Milestone at

   After that, you can search for your desired Milestone at
   [Chromium data website](https://chromiumdash.appspot.com/branches), and match
   it with the *WebRTC* column to find the daily branch number. For example, to
   build the `libWebrtc` library version used by latest stable Chrome 140 (build
   number `7339`) you would just need to change to the `branch-heads/7339`:

   ```sh
   git checkout branch-heads/7339
   ```

   Also, you can see all available branches in case you want to use another
   daily branch by executing `git branch -r`. At this moment (2025-09-16),
   latest one is `7418`.

   Once changed to the desired daily build branch, we need to
   [reset and sync the repository code](https://stackoverflow.com/a/61321315/586382),
   and download again more dependencies and code. It seems this is needed
   because previous `gclient` when we were in `main` branch would have left some
   temporal files (maybe we could have changed branches before?) and the build
   could fail, so this way we make sure we have the correct ones:

   ```sh
   gclient revert
   gclient sync
   ```

10. Finally, **compile the AAR file**. This will compile `libWebrtc` library for
    all the Android native supported platforms (`arm64-v8a`, `armeabi-v7a`,
    `x86` and `x86_64`) and package them in a `libwebrtc.aar` file in the root
    of the `src` folder that can be used in our Android project as a local
    dependency or published to our own Maven repository:

    ```sh
    tools_webrtc/android/build_aar.py
    ```

11. Once we have build the library, to **update the code** and build newer
    versions is just a matter of run `git remote update` to get the new daily
    build branches, and compile again. In case of problems, repeat the steps 6
    and 7 to fully download again the build tools and dependencies and compile
    once again.

Ideally, all this steps could be automated and run in a nightly basis, creating
a new reference in Maven to this automated builds.
[Github Actions](https://github.com/features/actions) could do a good job for
this, storing the nightly builds as project releases or also as a
[Github Packages Maven repository](https://github.com/features/packages), but
the Github Actions only provides 2000 minutes per month (a bit more than 1 hour
per day), so without a cache it would be problematic to generate nightly builds,
but checking only to run when there are new Milestones (similar to what I do in
[OS lifecycle](https://github.com/projectlint/OS-lifecycle) repo), it could
probably work... Maybe one day I'll implement it :-) By the moment, the raw JSON
info for the different Milestones can be found at
<https://chromiumdash.appspot.com/fetch_milestones>.

## Bonus update: add the library as a dependency

An important topic I've not covered before: how to use the compiled `.aar` file.
[Android documentation](https://developer.android.com/studio/projects/android-library#AddDependency)
has full info about how to create and use libraries as dependencies with
[Android Studio](https://developer.android.com/studio), but the important steps
to [use our compiled `libwebrtc.aar` file](https://developer.android.com/studio/projects/android-library#psd-add-aar-jar-dependency)
for our use case are:

1. Add the `libwebrtc.aar` file:

   1. Click **File > Project Structure > Dependencies**.
   2. Click **➕**, and select **Jar Dependency** in the menu.
   3. Enter the location of the `libwebrtc.aar` file, and select
      **implementation** option. Then click **OK**.

2. Open the app module's `build.gradle` or `build.gradle.kts` file, and confirm
   there's a new line for the `libwebrtc` library to the `dependencies` block as
   shown in the following snippet:

   ```gradle
   dependencies {
      implementation files("path/to/libwebrtc.aar")
   }
   ```

   In case there's a reference to the old `libwebrtc` library, remove it too.

3. Click **Sync Project with Gradle Files**.

From now on, next project builds will be using your build of the `libwebrtc.aar`
file, instead of the previous one.
