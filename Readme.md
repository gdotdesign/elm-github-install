# elm-github-install

This node script and package that allows you to install Elm packages **directly
from Github**, bypassing the package repository (package.elm-lang.org) while also
enabling restricted (effect manager and natvie) packages to be installed.

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
* Loads the dependencies of the packages form Github and transforms them also
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
