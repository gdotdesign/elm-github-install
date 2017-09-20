# elm-install

[![Gem Version](https://badge.fury.io/rb/elm_install.svg)](https://badge.fury.io/rb/elm_install)
[![Npm version](https://badge.fury.io/js/elm-github-install.svg)](https://badge.fury.io/js/elm-github-install)
[![Code Climate](https://codeclimate.com/github/gdotdesign/elm-github-install/badges/gpa.svg)](https://codeclimate.com/github/gdotdesign/elm-github-install)
[![Test Coverage](https://codeclimate.com/github/gdotdesign/elm-github-install/badges/coverage.svg)](https://codeclimate.com/github/gdotdesign/elm-github-install/coverage)
[![Inline docs](http://inch-ci.org/github/gdotdesign/elm-github-install.svg?branch=master)](http://inch-ci.org/github/gdotdesign/elm-github-install)
[![Build Status](https://travis-ci.org/gdotdesign/elm-github-install.svg?branch=master)](https://travis-ci.org/gdotdesign/elm-github-install)

This gem/npm-package allows you to install Elm packages **in a decentralized way from Git repositories**, this allows:
* installing of **effect manager** and **native** packages
* installing **forks of packages** for testing or unreleased features
* using packages from **local directories**
* installing **private packages** using private git repositories
* installing packages **offline** (packages are cached)

## Installation

If you have ruby installed on your machine then you can install it directly from
[rubygems.org](https://rubygems.org/gems/elm_install):
```
gem install elm_install
```

If you have npm installed on your machine then you can install it directly from
[npm](https://www.npmjs.com/package/elm-github-install):

```
npm install elm-github-install -g
```

There are also dependency free versions available for every release in the
[releases page](https://github.com/gdotdesign/elm-github-install/releases).

## Basic Usage
Once installed `elm-install` can be used instead of `elm-package` as a
replacement:

`elm-package.json`:
```
{
  ...
  "dependencies": {
    "elm-lang/core": "5.0.0 <= v < 6.0.0",
    "elm-lang/svg": "2.0.0 <= v < 3.0.0",
    "elm-lang/dom": "1.1.1 <= v < 2.0.0"
  }
  ...
}
```

Command:
```
$ elm-install

Resolving packages...
  ▶ Package: https://github.com/elm-lang/core not found in cache, cloning...
  ▶ Package: https://github.com/elm-lang/svg not found in cache, cloning...
  ▶ Package: https://github.com/elm-lang/html not found in cache, cloning...
  ▶ Package: https://github.com/elm-lang/virtual-dom not found in cache, cloning...
  ▶ Package: https://github.com/elm-lang/dom not found in cache, cloning...
Solving dependencies...
  ● elm-lang/core - https://github.com/elm-lang/core (5.1.1)
  ● elm-lang/svg - https://github.com/elm-lang/svg (2.0.0)
  ● elm-lang/dom - https://github.com/elm-lang/dom (1.1.1)
  ● elm-lang/html - https://github.com/elm-lang/html (2.0.0)
  ● elm-lang/virtual-dom - https://github.com/elm-lang/virtual-dom (2.0.4)
Packages configured successfully!
```

## Advanced Usage
Sources can be defined in the `dependency-sources` field in `elm-package.json`
for any package defined in the `dependencies` field.

The source can be defined as:
* an URL pointing to a Git repository:
  ```
  "elm-lang/core": "git@github.com:someuser/core"
  ```
* a hash containing the URL and the reference (tag, commit hash, branch) to use:
  ```
  "gdotdesign/elm-install-test": {
    "url": "gdotdesign@bitbucket.org:gdotdesign/elm-install-test",
    "ref": "master"
  }
  ```
* an absolute or relative path to the package in your hard drive:
  ```
  "elm-lang/dom": "../elm-lang/dom"
  ```

If a reference or a path is defined then the version in the `dependencies` field is
ignored and the **version will be used from the `elm-package.json` at that source**.

Examples:
```
  ...
  "dependencies": {
    "gdotdesign/elm-install-test": "1.0.0 <= v < 2.0.0",
    "elm-lang/core": "5.0.0 <= v < 6.0.0",
    "elm-lang/svg": "2.0.0 <= v < 3.0.0",
    "elm-lang/dom": "1.1.1 <= v < 2.0.0"
  },
  "dependency-sources": {
    "elm-lang/core": "git@github.com:someuser/core",
    "elm-lang/dom": "../elm-lang/dom",
    "gdotdesign/elm-install-test": {
      "url": "gdotdesign@bitbucket.org:gdotdesign/elm-install-test",
      "ref": "master"
    }
  }
  ...
```

### CLI
Help for the `elm-install` command:
```
NAME:

  elm-install

DESCRIPTION:

  Install Elm packages from Git repositories.

COMMANDS:

  help    Display global or [command] help documentation
  install Install Elm packages from the elm-package.json file.

GLOBAL OPTIONS:

  -h, --help
      Display help documentation

  -v, --version
      Display version information

  -t, --trace
      Display backtrace when an error occurs
```

Help for the `elm-install install` command.
```
NAME:

  install

SYNOPSIS:

  elm-install install

DESCRIPTION:

  Install Elm packages from the elm-package.json file.

OPTIONS:

  --cache-directory STRING
      Specifies where the cache is stored

  --skip-update
      Skips the update stage of packages

  --only-update STRING
      Only updates the given package

  --verbose
```

## Known Issues
* Using the NPM package or the released binaries in windows while specifing a
  relative directory as a package will fail because of the 2.2 travelling
  ruby dependency. Using the >Ruby 2.3 with the gem installed works properly.
  More #36

## FAQ

#### Do I need to use SSH keys?

It depends on your use case, but for public repositories in Github or Bitbucket
it's not needed.

#### What url protocols are supported?
The following protocols can be used:

* ssh://[user@]host.xz[:port]/path/to/repo.git/
* git://host.xz[:port]/path/to/repo.git/
* http[s]://host.xz[:port]/path/to/repo.git/
* [user@]host.xz:path/to/repo.git/

#### Can I install from private repositories?
Yes private repositories are supported provided you have authentication
(for example SSH keys).
