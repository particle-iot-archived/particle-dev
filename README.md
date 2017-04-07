# Particle Dev package for Atom

Particle Dev is a professional, open source, hackable IDE, designed for use with the Particle devices.

[![Build Status](https://travis-ci.org/spark/particle-dev.svg?branch=master)](https://travis-ci.org/spark/particle-dev)

## Installing

#### Particle Dev App

Download and install the latest [Particle Dev App](https://github.com/spark/particle-dev-app)

#### GitHub Atom

To install Particle Dev package you'll need following dependencies:

##### Requirements

###### Windows

* [GitHub for Windows](https://desktop.github.com/)
* [Visual Studio Community 2013 for Windows Desktop](https://www.visualstudio.com/en-us/downloads/download-visual-studio-vs#DownloadFamilies_2)

###### OS X

* [XCode](https://itunes.apple.com/gb/app/xcode/id497799835?mt=12) (you need to run it first in order to finish the installation)

###### Linux

* [Download Atom for your distribution](https://github.com/atom/atom/releases/latest)
* Build dependencies:

	**Ubuntu / Debian**

	`$ sudo apt-get install build-essential`

	**Fedora / CentOS / RHEL**

	`$ sudo dnf --assumeyes install make gcc gcc-c++ glibc-devel`

	**Arch**

	`$ sudo pacman -S --needed gconf base-devel`

	**openSUSE**

	`$ sudo zypper install make gcc gcc-c++ glibc-devel`

##### Installation

Install following packages:

* [console-panel](https://atom.io/packages/console-panel)
* [tool-bar](https://atom.io/packages/tool-bar)
* [particle-dev](https://atom.io/packages/particle-dev)
* [particle-dev-cloud-functions](https://atom.io/packages/particle-dev-cloud-functions)
* [particle-dev-cloud-variables](https://atom.io/packages/particle-dev-cloud-variables)

After installation of `particle-dev` package, restart Atom. If you see a red bug icon in status bar, click it, then click `Rebuild Modules` button and `Restart Atom` again.

## Usage

See [our documentation](https://docs.particle.io/guide/tools-and-features/dev/) to learn about how to use Particle Dev for software development.
