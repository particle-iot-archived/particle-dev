# Developing Particle Dev package

## First steps

```sh
$ rm -rf ~/.atom/packages/particle-dev
$ git clone git@github.com:spark/particle-dev.git
$ cd particle-dev
$ apm install
$ apm link
```

At this point when you run Atom it will use your locally cloned `particle-dev`. After making any changes you'll need to reload Atom window (`View` -> `Developer` -> `Reload Window`). It's also usefull to open a new window in Dev Mode (`View` -> `Developer` -> `Open in Dev Mode...`) and use Dev Tools (`View` -> `Developer` -> `Toggle Developer Tools`).

If you're adding/changing dependencies, you need to run `apm install` or `Update Package Dependencies: Update` command from the Atom palette when having `particle-dev` directory open.
