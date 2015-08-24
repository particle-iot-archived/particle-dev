# Particle Dev

Particle Dev is a professional, open source, hackable IDE, designed for use with the Particle devices.

[![Build Status](https://travis-ci.org/spark/spark-dev.svg?branch=master)](https://travis-ci.org/spark/spark-dev)

## Installing

### Mac OS X

Download the latest [Particle Dev release](https://github.com/spark/spark-dev/releases/latest).

Particle Dev will automatically update when a new release is available.

### Windows

Download the latest [Particle Dev release](https://github.com/spark/spark-dev/releases/latest).

Particle Dev for Windows does not currently automatically update when a new release is available; you will have to download a new version manually when updates are released. We hope to see this change in the future.

### Linux

Currently there isn't a standalone Particle Dev build for Linux. It is possible to use Particle's packages with Atom though. To do so you need to:

1. [Download Atom for your distribution](https://github.com/atom/atom/releases/latest)
2. Install dependencies
 ##### Ubuntu / Debian
 `$ sudo apt-get install build-essential`
 
 ##### Fedora / CentOS / RHEL
 `$ sudo dnf --assumeyes install make gcc gcc-c++ glibc-devel`
 
 ##### Arch
 `$ sudo pacman -S --needed gconf base-devel`
 
 ##### openSUSE
 `$ sudo zypper install make gcc gcc-c++ glibc-devel`
3. Install following packages:
  * [spark-dev](https://atom.io/packages/spark-dev)
  * [particle-dev-cloud-functions](https://atom.io/packages/particle-dev-cloud-functions)
  * [particle-dev-cloud-variables](https://atom.io/packages/particle-dev-cloud-variables)
  * [tool-bar](https://atom.io/packages/tool-bar)
4. Run following in terminal:

  ```bash
  $ cd ~/.atom/packages/spark-dev
  $ npm install nopt
  $ rm -rf node_modules/serialport
  $ export ATOM_NODE_VERSION=0.22.3
  $ apm install .
  $ apm rebuild-module-cache
  ```
5. Go to Atom, hit `Cmd+Shift+P`, type `cache` and select `Incompatible Packages: Reload Atom And Recheck Packages`

## Using

See [our documentation](http://docs.particle.io/core/dev) to learn about how to use Particle Dev for software development.
