---
lang: en
layout: post
title: How to build WebRTC for Android in Ubuntu 21.04
twitter: '1385546685472854019'
---

Google used to provide
[prebuild Android images](https://bintray.com/google/webrtc/google-webrtc) of
`libWebRTC` library, and in fact, it's (still) the recomended way to use them on
[its own documentation](https://webrtc.github.io/webrtc-org/native-code/android/#prebuilt-libraries).
But starting on WebRTC M80 release (January 2020), they decided to
[deprecate the binary mobile libraries](https://groups.google.com/g/discuss-webrtc/c/Ozvbd0p7Q1Y/m/M4WN2cRKCwAJ),
and the reasons were that the builds were intended just only for development
purposses, and
[users were already using building themselves with their own customizations, or using third party libraries that embeded them](https://bloggeek.me/how-to-pick-the-right-webrtc-mobile-sdk-build-for-your-application/)
(where have been left developers that just want to build a WebRTC enabled mobile
app?), and they just only provided another build in August 2020 (1.0.32006) to
fill some important security holes, in case someone (everybody?) was still using
the binary mobile libraries.

In addition to that, that binary libraries are available to use with Maven, but
[Bintray will be deprecated](https://jfrog.com/blog/into-the-sunset-bintray-jcenter-gocenter-and-chartcenter/)
on May 1st 2021, and seems they will not be available after February 1st 2022,
so it's not clear if the binary mobile libraries would still be available when
using Maven itself.

Due to both problems (no new libraries versions, and not sure about future
availability  of current ones), and since I've not able to find other online
providers for the binary libraries, best option seems to waste some hard disk
space (16GB... it downloads all the Chrome source code and the build environment
tools) and compile them myself. The automated build script that generates the
binary mobile library `.aar` file was published and
[there are instructions to build it yourself](https://medium.com/@abdularis/how-to-compile-native-webrtc-from-source-for-android-d0bac8e4c933),
that's a huge advantage over needing to compile and build the libraries yourself
by hand. But while I was using it, I've found some issues and errors in the
instructions themselves when executing them on Ubuntu 21.04 (released just
yesterday :-) ), so here are the fixed instructions with some additional
comments:

1. Create a new folder where to work in. This seems obvious, but if not, you'll
   end up filling with garbage your `$HOME` directory (I'm n00b). Maybe having
   there the tools and a big `src/` folder where to host all company projects
   makes sense inside Google organization itself...:

   ```sh
   mkdir webrtc_android
   cd webrtc_android
   ```

2. Install Chromium `depot_tools` and export them:

   ```sh
   git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
   export PATH=$PATH:$PWD/depot_tools
   ```

3. Install Python. `depot_tools` makes use of the `python` executable, because
   it's compatible with both Python 2 and 3. On Ubuntu 21.04 it's not available
   since it was traditionally linked to the now deprecated Python 2, and to
   differenciate from it, it was being used the `python3` executable, so in a
   clean slate install, `depot_tools` will fail because it's not found. To fix
   that, we can install the `python-is-python3` package:

   ```sh
   sudo apt install python-is-python3
   ```

4. Get the build environment tools and Chromium source code using `depot_tools`,
   and `cd` inside it. This will a 16GB checkout and will take **A LONG TIME**.
   In my case, it lasted 4.5 hours for the `fetch` command and more than one
   hour for the `gsync` one...:

   ```sh
   fetch --nohooks webrtc_android
   gsync sync
   cd src
   ```

5. Install build dependencies. This will download again more dependencies, in
   this case system wide build tools. One of them will be Python 2, so the
   previously installed `python-is-python3` package will be removed:

   ```sh
   ./build/install-build-deps.sh
   ```

6. Select the release to build. Until WebRTC M80 release, there were branches
   for each one of the Chromium releases, so it was easy to know what version
   was each one, but after that, Google started to create branches in a daily
   basis. Use what's currently in `master` branch or from any of the daily
   branches is totally fine, but if you want to build the exact copy of the
   library of a particular release, you can search for your desired Milestion at
   [Chromium data website](https://chromiumdash.appspot.com/branches), and match
   it with the *WebRTC* column to find the daily branch number. For example, to
   build the `libWebrtc` library version used by latest stable Chrome 91 (build
   number `4472`) you would just need to change to the `branch-heads/4472`:

   ```sh
   git checkout branch-heads/4472
   ```

   This will left the repository in detached mode, but it's not something to
   worry about. Also, you can see all available branches in case you want to
   use another daily branch by executing `git branch -r`. At this moment, latest
   one is `4485`.

   Once changed to the desired daily build branch, we need to
   [reset and sync the repository code](https://stackoverflow.com/a/61321315/586382),
   and download again more dependencies and code. It seems this is needed
   because previous `gsync` when we were in `master` branch would have left some
   temporal files (maybe we could have changed branches before?) so the build
   could fail, so this way we make sure to have the correct ones:

   ```sh
   gclient revert
   gclient sync
   ```

7. Finally, compile the AAR file. This will compile `libWebrtc` library for all
   the Android native supported platforms (`arm64-v8a`, `armeabi-v7a`, `x86` and
   `x86_64`) and package them in a `libwebrtc.aar` file in the root of the
   `src` folder that can be used in our Android project as a local dependency or
   published to our own Maven repository:

   ```sh
   tools_webrtc/android/build_aar.py
   ```

8. Once we have build the library, to update the code and build newer versions
   is just a matter of run `git remote update` to get the new daily build
   branches, and repeat the steps 6 and 7.

Ideally, all this steps could be automated and run in a nightly basis, creating
a new reference in Maven to this automated builds.
[Github Actions](https://github.com/features/actions) could do a good job for
this, storing the nightly builds as project releases or also as a
[Github Packages Maven repository](https://github.com/features/packages), but
the Github Actions only provides 2000 minutes per month (a bit more than 1 hour
per day), so without a cache it would be problematic to generate nightly builds,
but checking only to run where there are new Milestones (similar to what I do in
[OS lifecycle](https://github.com/projectlint/OS-lifecycle) repo), it could
probably work... Maybe one day I'll implement it :-)

## Bonus update: add the library as a dependency

An important topic I've not covered before: how to use the compiled `.aar` file.
[Android documentation](https://developer.android.com/studio/projects/android-library#AddDependency)
has full info about how to create and use libraries as dependencies with
[Android Studio](https://developer.android.com/studio), but the important steps
for our use case are:

1. Add the `libwebrtc.aar` file:

   1. Click **File > New > New Module**.
   2. Click **Import .JAR/.AAR Package**, then click **Next**.
   3. Enter the location of the `libwebrtc.aar` file then click **Finish**.

   Android Studio creates a module directory, copies the `libwebrtc.aar` file
   into the module, and generates a `build.gradle` file for it, with the following contents:

   ```gradle
   configurations.maybeCreate("default")
   artifacts.add("default", file('libwebrtc.aar'))
   ```

2. Make sure the `libwebrtc` library is listed at the top of your
   `settings.gradle` file, like this:

   ```gradle
   include ':app', ':libwebrtc'
   ```

3. Open the app module's `build.gradle` file and add a new line for the
   `libwebrtc` library to the `dependencies` block as shown in the following
   snippet:

   ```gradle
   dependencies {
      implementation project(":libwebrtc")
   }
   ```

   In case there was a reference to the old `libwebrtc` library from the Maven
   registry, remove it too.

4. Click **Sync Project with Gradle Files**.

From now on, next project builds will be using your build of the `libwebrtc.aar`
file located at `libwebrtc/libwebrtc.aar`, instead of obsolete one provided by
Maven.
