# Documentation and scripts that were used for building PuTTY-url

## PuTTY-url has been discontinued

This repository contains some documentation and scripts that were used to build
it.

## Adapting the patch for a new version

Example showing the process for 0.83.

```shell
# Download the new version
wget https://the.earth.li/~sgtatham/putty/latest/putty-0.83.tar.gz \
     https://the.earth.li/~sgtatham/putty/latest/putty-0.83.tar.gz.gpg

# Verify signature
gpg --verify putty-0.83.tar.gz.gpg putty-0.83.tar.gz

# Unpack and make a copy (to which we will apply the previous version's patch)
tar -xf putty-0.83.tar.gz
cp -r putty-0.83 putty-url-0.83

# Apply the previous version's patch
cd putty-url-0.83
patch -p1 < path/to/putty-url-0.81.patch

# Manually fix all failed hunks. Most releases, this is just version.h (where
# " (url)" should be appended to TEXTVER).

# Once all rejected hunks have been applied, clean up any remaining *.orig and
# *.rej files created by patch
find -name '*.orig' -delete
find -name '*.rej' -delete

# Then create a patch for the new version
cd ..
git diff --no-index --no-prefix putty-0.83 putty-url-0.83 > putty-url-0.83.patch
```

## Building binaries

The official PuTTY-url binaries were built on Debian using clang-cl from the upstream [LLVM repositories](https://apt.llvm.org/).

### Headers

To build you will need a set of Windows headers, which can be acquired either
using [msvc-headers-downloader](https://github.com/tobbez/msvc-headers-downloader),
or by copying them from a Windows installation.

The headers should be stored on a case insensitive file system (such as a
loopback-mounted vfat disk image, or in a case-folded ext4 directory), since
they are not internally consistent in terms of casing.

Alternatively, [msvc-extract](https://git.tartarus.org/?p=simon/msvc-extract.git)
(developed by the PuTTY author) could be used instead.

`MSVC_FILES_ROOT` in `build_putty_cmake.bash` should be updated to point to the
location of the headers. See `msvc_root_files.txt` for an example of the
expected file layout.

### Build steps

```shell
# Create sources directory for this version
mkdir ~/sources-0.83

# and populate it
cp putty-0.83.tar.gz ~/sources-0.83/
cp putty-url-0.83.patch ~/sources-0.83/
cp path/to/putty-url-icons.tar.gz ~/sources-0.83/

# create the output directory and switch to it
mkdir ~/autobuilt-0.83
cd ~/autobuilt-0.83

# and start the build
~/build_putty_cmake.bash 0.83

# the resulting files will be written to ./dist/ in the current directory
```
