# elm-github-install

[![npm version](https://badge.fury.io/js/elm-github-install.svg)](https://badge.fury.io/js/elm-github-install)

This node script and package that allows you to install Elm packages **directly
from Github** (via https), or from **arbitrary git remotes** (ssh), bypassing the package repository (package.elm-lang.org) while also
enabling restricted (effect manager and native) packages to be installed.

## Description

There are some things that made this possible:
* The basic design of Elm packages: using github, semantic versioning and tags
* [Semver package](https://www.npmjs.com/package/semver) to validate versions
* [SemverResolver package](https://github.com/pghalliday/semver-resolver) that
  does the actual resolving

These are the steps the installer takes:
* Reads the dependencies from `elm-package.json`
* Transforms them to semver dependencies - **4.0.4 <= v < 5.0.0** becomes
	**>= 4.0.4 < 5.0.0**
* Loads the dependencies of the packages form Github (or remote), and transforms them also
* Resolve the dependencies
* Install resolved dependencies into `elm-stuff/packages`
* Writes `elm-stuff/exact-dependencies.json` with the resolved dependencies

## Warnings

There are some caveats though:
* [TODO] This installer doesn't check the installed elm-version
* [DEPENDENCY] Git tags (semver) are needed other references cannot be installed
	(branch-name, commit-hash)
* [DEPENDENCY] Git is needed
* [DEPENDENCY] Node is needed

## Usage

Install it:
```
npm install -g elm-github-install
```

Elm packages are name after their github repositories, so you can simply declare the
github package you want the way you would declare any other package.
For example, if you want to install [NoRedInk's Elm css](https://github.com/NoRedInk/nri-elm-css)
at version 1.3.0, you would do the following:

```
# elm-package.json
{
  ...
  "dependencies": {
    ...
    "githubUser/repoName": "desiredVersion <= v < someLargerNumber",
    "NoRedInk/nri-elm-css": "1.3.0 <= 1.3.0 < 2.0.0",
    ...
  }
  ...
}
```

### Remote git repos

Elm packages can also be hosted on arbitrary git remote repos. In order to use them, 
you need to use a config file named `elm-github-package.json`, located in the root 
project dir, aside `elm-package.json`. This file indicates the hosts associated to the 
packages that are not in github.

Here's an example using a fictious `myuser/my-elm-lib` package, that exists on a 
private git/ssh remote, cloneable at `git@mygit.myco.com:myuser/my-elm-lib.git`.

The `elm-package.json` is the usual one :

```
{
  ...
  "dependencies": {
    ...
    "myuser/my-elm-lib": "1.0.0 <= v < 1.1.0",
    ...
  }
  ...
}
```

And the `elm-github-package.json` config file defines the host :


```
{
    "myuser/my-elm-lib" : "mygit.mycompany.com"    
}
```
   
With that, `elm-github-package` will use ssh for and the provided host in order 
to resolve and download the `myuser/my-elm-lib` package.


You can find the current version of the package in the repository's `elm-package.json`.

Use the command:
```
elm-github-install
```

## Demonstration
The following repositories have their packages successfully installed and
the main file successfully compiled (2016-06-12):
* [STANDARD] https://github.com/debois/elm-mdl/tree/v7/demo - Demo.elm
* [STANDARD] https://github.com/evancz/elm-sortable-table/tree/master/examples -
	1-presidents.elm
* [HAVE GITHUB DEPS] https://github.com/gdotdesign/elm-ui-website - source/Main.elm
