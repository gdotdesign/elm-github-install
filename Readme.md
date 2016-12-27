# elm-install

[![Gem Version](https://badge.fury.io/rb/elm_install.svg)](https://badge.fury.io/rb/elm_install)
[![Code Climate](https://codeclimate.com/github/gdotdesign/elm-github-install/badges/gpa.svg)](https://codeclimate.com/github/gdotdesign/elm-github-install)
[![Inline docs](http://inch-ci.org/github/gdotdesign/elm-github-install.svg?branch=master)](http://inch-ci.org/github/gdotdesign/elm-github-install)

This gem allows you to install Elm packages **directly from any Git repository
(event private ones)**, bypassing the package repository (package.elm-lang.org)
while also enabling restricted (effect manager and native) packages to be
installed.

## Installation

If you have ruby installed on your machine then you can install it directy from
[rubygems.org](https://rubygems.org/gems/elm_install):
```
gem install elm-install
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
```sh
$ elm-install install

Resolving packages...
  ▶ Package: git@github.com:elm-lang/core not found in cache, cloning...
  ▶ Package: git@github.com:elm-lang/svg not found in cache, cloning...
  ▶ Package: git@github.com:elm-lang/html not found in cache, cloning...
  ▶ Package: git@github.com:elm-lang/virtual-dom not found in cache, cloning...
  ▶ Package: git@github.com:elm-lang/dom not found in cache, cloning...
Solving dependencies...
Saving package cache...
  ● elm-lang/core - 5.0.0 (5.0.0)
  ● elm-lang/svg - 2.0.0 (2.0.0)
  ● elm-lang/dom - 1.1.1 (1.1.1)
  ● elm-lang/html - 2.0.0 (2.0.0)
  ● elm-lang/virtual-dom - 2.0.2 (2.0.2)
Packages configured successfully!
```

## Advanced Usage
Sources (urls for git repositories) can be defined in the `dependency-sources`
field in `elm-package.json` for any package defined the the `dependencies`
field. There is only one restriction: the pacakges name must match the path of
the url of the git repository, this is because it could cause conflicts.

The source can be defined by a string or a hash containing the url and the
reference (tag, commit hash, branch) to use. If a reference is defined then
the version in the `dependencies` field is ignored and the **version will be
used `elm-package.json` is at that reference (= 2.0.0)**.

```
  ...
  "dependencies": {
    "gdotdesign/elm-install-test": "1.0.0 <= v < 2.0.0",
    "elm-lang/core": "5.0.0 <= v < 6.0.0",
    "elm-lang/svg": "2.0.0 <= v < 3.0.0",
    "elm-lang/dom": "1.1.1 <= v < 2.0.0"
  },
  "dependency-sources": {
    "elm-lang/core": "git@github.com:elm-lang/core",
    "gdotdesign/elm-install-test": {
      "url": "gdotdesign@bitbucket.org:gdotdesign/elm-install-test",
      "ref": "master"
    }
  }
  ...
```
