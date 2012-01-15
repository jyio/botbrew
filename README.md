# BotBrew - *nix tools and package management for Android

This project compiles various *nix tools and makes Opkg packages suitable for installation on ARM devices running Android.

## Prebuilt

If you just want to use prebuilt binaries, get a shell on your rooted Android device and run:

    wget http://botbrew.inportb.com/opkg/install.sh -O- | su

Otherwise, keep reading to roll your own.

## Prerequisites

The following Debian packages are required for using BotBrew.

- git-core
- mercurial
- subversion
- build-essential
- autoconf
- libtool
- libglib2.0-dev
- python
- python-yaml
- ruby1.9.1

In addition, the Android NDK (r6 recommended) is required.

## Cookbook

BotBrew knows how to make

- bzip2
- curl
- ncurses
- openssl
- opkg
- python
- readline
- ruby
- vim

## Configuration

Create a new file `config.mk` to define a couple of Make variables

- OPKG_MAINTAINER := your name and &lt;email address&gt; in RFC822 format
- NDKPATH := absolute path to the NDK

## Usage

`make all`

- builds and packages all projects

`make install`

- builds all projects

`make package`

- packages all projects

`make clean`

- cleans all projects

`make clobber`

- cleans and removes source code from all projects

`make opkg.tgz`

- makes a package for opkg distributable without opkg

`make cookbook/<project>/install`

- builds `<project>`

`make cookbook/<project>/package/*`

- packages `<project>`

`make cookbook/<project>/clean`

- cleans `<project>`

`make cookbook/<project>/clobber`

- cleans and removes source code from `<project>`
