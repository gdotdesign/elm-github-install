var request = require('request')
var shell = require('shelljs')
var tar = require('tar-fs')
var path = require('path')
var zlib = require('zlib')
var fs = require('fs')
var os = require('os')

var config = require(path.join(__dirname, '../package.json'))

var homedir = path.join(os.homedir(), '.elm-install')
var platform = os.platform()
var version = config.version
var arch = process.arch

var prefix =
  "https://github.com/gdotdesign/elm-github-install/releases/download"

var packageUrl = function(suffix) {
  return [ prefix,
    'v' + version,
    'elm-install-' + version + '-' + suffix + '.tar.gz'
  ].join('/')
}

var extractor = tar.extract(homedir)

if(platform == 'linux' && arch == 'x64') {
  request
    .get(packageUrl('linux-x86_64'))
    .pipe(zlib.createGunzip())
    .pipe(extractor)
} else if (platform == 'linux') {
  request
    .get(packageUrl('linux-x86'))
    .pipe(zlib.createGunzip())
    .pipe(extractor)
} else if (platform == 'darwin') {
  request
    .get(packageUrl('linux-osx'))
    .pipe(zlib.createGunzip())
    .pipe(extractor)
} else if (platform == 'win32') {
  console.log('Windows is not yet supported!')
} else {
  console.log('Your operating system is not supported.')
}
