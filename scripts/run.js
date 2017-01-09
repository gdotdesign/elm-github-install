#! /usr/bin/env node

var exec = require('child_process').spawnSync
var path = require('path')
var os = require('os')
var fs = require('fs')

var versionPath = path.join(__dirname, '../lib/elm_install/version.rb')
var version =
  fs.readFileSync(versionPath, 'utf-8')
    .match(/(\d+\.\d+\.\d+)/)[1]

var homedir = path.join(os.homedir(), '.elm-install')
var platform = os.platform()
var arch = process.arch

var execute = function(suffix) {
  exec(executablePath(suffix), [ process.argv.slice(2) ], { stdio: 'inherit' })
}

var executablePath = function(suffix) {
  return path.join(
    homedir,
    [ 'elm-install-' + version + '-' + suffix ].join('/'),
    'elm-install'
  )
}

if(platform == 'linux' && arch == 'x64') {
  execute('linux-x86_64')
} else if (platform == 'linux') {
  execute('linux-x86')
} else if (platform == 'darwin') {
  execute('linux-osx')
} else if (platform == 'win32') {
  exec(executablePath('win32') + '.bat', [ process.argv.slice(2) ], { stdio: 'inherit' })
} else {
  console.log('Your operating system is not supported.')
}
