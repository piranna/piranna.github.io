---
lang: en
layout: post
title: Minimal and secure Python distroless Docker images with Poetry
tags: docker
---

For a recent project, I needed to create a Docker image for a Python application
that is being handled with [Poetry](https://python-poetry.org/). I already done
it one year ago using
[distroless images](https://github.com/GoogleContainerTools/distroless), that
provide minimal Docker images based on Debian without package managers, shells
or any other tools commonly found in traditional images, and optimized for
security and size. But after the release of Debian 12 and Poetry 2.0, and so
much improvements on the ecosystem during this year, this time I wanted to take
the opportunity to create a more secure and minimal image, and to know what
would be the best practices for doing so.

One of the changes in the process has been to use the distroless images also for
the build stages, instead of using the
[official Python images](https://hub.docker.com/_/python), also based on Debian.
The reason for that is to ensure having the same environment (OS, Python
version, etc.) as the final image (official Python images has more recent Python
versions, but binaries are located in a different path than the regular Debian
Python packages, and by extension distroless images, uses). This makes it more
complex to set up, since in distroless images there's no shell available to run
commands, strings interpolation
([shell expansion](https://www.gnu.org/software/bash/manual/html_node/Shell-Expansions.html)),
multi-lines, or debugging. However, it ensures that the final image will work as
expected, and that no unexpected issues will arise, like mismatched location of
Python executables.

The configuration of this `Dockerfile` I've created is mostly based on
<https://stackoverflow.com/a/57886655/586382> and
<https://github.com/GoogleContainerTools/distroless/issues/1543#issuecomment-2214730798>,
and it generates three stages:

1. `distroless-poetry`: This stage generates a docker image with PIP, Poetry and
   their dependencies ready to use in a distroless image.
2. `builder`: Built on top of the previous one, this stage creates a virtual
   environment and installs there the application and its dependencies.
3. `final`: This stage copies the `bin/` and `lib/` folders from the `builder`
   stage to create the final image for production.

## Dockerfile setup

First of all, we specify the versions of Debian and Python we want to use. This
way we ensure the same values are used throughout the `Dockerfile`, and making
it easier to update them in the future, especially now that
[Debian 13](https://www.debian.org/releases/stable/release-notes/index.html)
with Python 3.13 has been released (and
[Python 3.14](https://www.python.org/downloads/release/python-3140rc2/) will be
released in less than one month), but it's not yet available in distroless
images.

Additionally, we specify the `Dockerfile` syntax version to use the upcoming
experimental features, in particular the
[`COPY --exclude`](https://docs.docker.com/reference/dockerfile/#copy---exclude)
feature, to explicitly exclude files from the build context when copying the
virtual environment files.

```Dockerfile
# syntax=docker/dockerfile:1-labs

ARG DEBIAN_VERSION=12    # Debian 13 is not yet available in distroless
ARG PYTHON_VERSION=3.11  # Python 3.13 is not yet available in distroless
```

## Distroless with PIP and Poetry

The first stage is based on the
[distroless image for Python 3 on Debian](https://gcr.io/distroless/python3-debian12).
It uses the regular version running commands as `root`, so we can install
[PIP](https://pip.pypa.io/en/stable/) and [Poetry](https://python-poetry.org/)
as global system commands, available in the `$PATH` by default.

Poetry makes use of PIP to be installed, so to install it first, we download the
[`get-pip.py`](https://bootstrap.pypa.io/get-pip.py) script with Python's
standard library function
[`urllib.request.urlretrieve`](https://docs.python.org/3/library/urllib.request.html#urllib.request.urlretrieve)
as an alternative to [`curl`](https://curl.se/) or
[`wget`](https://www.gnu.org/software/wget/), which are not available in the
distroless images. Then we just run the script, and get it installed in the
system. We need to use the `--break-system-packages` flag to force integration
with the Debian Python files hierarchy.

Having PIP installed, we can install Poetry and the
[bundle plugin](https://github.com/python-poetry/poetry-plugin-bundle), using
the `--no-cache-dir` option to don't add useless cache files in the docker
images, and again we need to use the `--break-system-packages` flag to force
integration with the Debian Python files hierarchy. The poetry bundle plugin
will help us to create a virtual environment with our project and all its
dependencies installed in the next stage.

```Dockerfile
FROM gcr.io/distroless/python3-debian${DEBIAN_VERSION} AS distroless-poetry

# Install PIP
RUN ["python3", "-c", "from urllib.request import urlretrieve; urlretrieve('https://bootstrap.pypa.io/get-pip.py', 'get-pip.py')"]
RUN ["python3", "get-pip.py", "--break-system-packages"]

# Install Poetry and the bundle plugin
RUN ["pip", "install", "--break-system-packages", "--no-cache-dir", "poetry", "poetry-plugin-bundle"]
```

## Builder stage

Second stage is based on the previous one, and it will create a virtual
environment with our application and its dependencies installed. We copy the
`pyproject.toml` and `poetry.lock` files to the image, so Poetry knows which
dependencies to install, and also the `README.md` file, since it's a requirement
of Poetry when creating a package, although it's not actually needed for the
installation itself (is it forcing to apply packaging best practices?). We also
copy our application Python package, in this case located in the `my_package/`
folder.

Then, we create the virtual environment with the `poetry bundle venv` command,
that also installs the application with the packages of its dependencies. As we
did before, we use the `--no-cache` option to avoid useless cache files in the
docker image. We set the `POETRY_VIRTUALENVS_OPTIONS_NO_PIP` environment
variable to `true` to avoid installing PIP in the virtual environment, since we
will not need to add new packages later in the image, and would open a security
risk. The same for the `--only=main` option, to avoid installing development
dependencies, which are not needed in production.

```Dockerfile
FROM distroless-poetry AS builder

# Copy project files to the image
WORKDIR /src

COPY poetry.lock pyproject.toml README.md ./
COPY my_package ./my_package

# Create the bundled virtualenv
ARG POETRY_VIRTUALENVS_OPTIONS_NO_PIP=true
RUN ["poetry", "bundle", "venv", "--no-cache", "--only=main", "/venv"]
```

## Final stage

The final stage is the actual image we will use in production. It's also based
on the same version of the distroless image for Python 3 on Debian from scratch,
but this time using the `nonroot` variant, which runs as a non-root user by
default. Its home folder and image default working directory is located at
`/home/nonroot`, so we can mount our data volume there.

Later, we copy the virtual environment files created in the previous stage to
the `/venv` folder in the final image. This way, we would have isolated the
application code from both the rest of the operating system files, and from the
application data at the home folder of the `nonroot` user.

To optimize the image size, we only copy the `uvicorn` binary that will launch
our application later (this is an example for a
[FastAPI](https://fastapi.tiangolo.com/) project, you can use any entrypoint
script that fits your own one), and the `lib/` folder from the virtual
environment created in the previous stage, with the Python packages and
dependencies. We also exclude useless files that are not needed in the final
image (that's the reason of using `syntax=docker/dockerfile:1-labs` before),
such as `__pycache__` folders and most of the files in the `.dist-info` folders,
except the `LICENSE` files, which could be needed for compliance reasons (an
alternative maybe could be to move them out to a separate directory).

To increase the security, we use the `--chown` flag to set the group of the
files to the `nonroot` group, and use the `--chmod` flag to set the permissions
to `050` for the `uvicorn` binary. This way, only the group (`nonroot`) can
read and execute it. We also use the `--chmod` flag so only the `nonroot` group
can read and access the `lib/` folder.

Final step is to run the application. For this, we set the `PYTHONPATH`
environment variable to include the path to the `site-packages` folder in the
virtual environment, so Python can find the installed packages. We expose the
application directly on the port `80`, that's the standard port for HTTP, so
there's no need to specify it when accessing the application, just only when
mapping the port on the host. Finally, we set the default command to launch the
application with `uvicorn`, binding to all network interfaces (`0.0.0.0`).

```Dockerfile
FROM gcr.io/distroless/python3-debian${DEBIAN_VERSION}:nonroot

# WORKDIR is already /home/nonroot, mount your data volume there
VOLUME /home/nonroot

# Copy files from builder
COPY \
  --chmod=050 --chown=root:nonroot \
  --from=builder /venv/bin/uvicorn /venv/bin/uvicorn
COPY \
  --chmod=a-rwx,g+rX --chown=root:nonroot \
  --exclude=**/__pycache__ --exclude=**/*.dist-info \
  --exclude=!**/*.dist-info/LICENSE* --exclude=!**/*.dist-info/licenses \
  --from=builder /venv/lib /venv/lib

# Set PYTHONPATH to find packages installed in the virtualenv
ARG PYTHON_VERSION
ENV PYTHONPATH=/venv/lib/python${PYTHON_VERSION}/site-packages

# Run the web server
EXPOSE 80

CMD ["/venv/bin/uvicorn", "my_package.web:app", "--host", "0.0.0.0", "--port", "80"]
```

And that's it, only remaining step is to build the image with `docker build .`.

Once the docker container is built, a way to run this image (including a
read-only root filesystem to increase security even further, although with the
usage of `--chmod` should not be necessary) would be:

```sh
docker run \
  --publish 8000:80 --read-only --rm --volume /path/to/data:/home/nonroot \
  my-image
```

## Future improvements

The docker image already have only the minimal set of files needed to run the
application, but it could be further optimized in size. For example, we could
remove symlinks to Python binaries that are not needed, or documentation or
system config files that are not being used. Another option would be to review
and remove the test files included in some packages, although in this case, it
would be better to contact the package maintainers to avoid including them in
the first place.

But in a more experimental way, the most promising approach would be to compress
Python packages in the virtual environment at the `site-packages` folder, and
use [Python zipimport](https://docs.python.org/3/library/zipimport.html) to
import them directly from the zip file. The compressed file could be added to
the `PYTHONPATH` environment variable, and the packages could be
[imported from there](https://realpython.com/python-zip-import/#use-pythonpath-for-system-wide-zip-imports).
This would need some testing to ensure that all packages work correctly when
imported from the zip file, mostly due to writing files to the filesystem under
packages directories, but if the image works correctly with the `--read-only`
flag, it should be safe and save a lot of space in the final image.
