#! /usr/bin/env node

var exec = require('child_process').spawnSync
var path = require('path')
var os = require('os')

var config = require(path.join(__dirname, '../package.json'))

var homedir = path.join(os.homedir(), '.elm-install')
var version = config.version
var platform = os.platform()
var arch = process.arch

var executablePath = function(suffix) {
  return path.join(
    homedir,
    [ 'elm-install-' + version + '-' + suffix ].join('/'),
    'elm-install'
  )
}

if(platform == 'linux' && arch == 'x64') {
  exec(executablePath('linux-x86_64'), [ 'install' ], { stdio: 'inherit' })
} else if (platform == 'linux') {
  exec(executablePath('linux-x86'), [ 'install' ], { stdio: 'inherit' })
} else if (platform == 'darwin') {
  exec(executablePath('linux-osx'), [ 'install' ], { stdio: 'inherit' })
} else if (platform == 'win32') {
  console.log('Windows is not yet supported!')
} else {
  console.log('Your operating system is not supported.')
}
