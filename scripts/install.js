var request = require('request')
var shell = require('shelljs')
var tar = require('tar-fs')
var path = require('path')
var zlib = require('zlib')
var fs = require('fs')
var os = require('os')

var versionPath = path.join(__dirname, '../lib/elm_install/version.rb')
var version =
  fs.readFileSync(versionPath, 'utf-8')
    .match(/(\d+\.\d+\.\d+)/)[1]

var homedir = path.join(os.homedir(), '.elm-install')
var platform = os.platform()
var arch = process.arch

var prefix =
  "https://github.com/gdotdesign/elm-github-install/releases/download"

var extractor = tar.extract(homedir)

var packageUrl = function(suffix) {
  return [ prefix,
    'v' + version,
    'elm-install-' + version + '-' + suffix + '.tar.gz'
  ].join('/')
}

var download = function(suffix){
  request
    .get(packageUrl(suffix))
    .pipe(zlib.createGunzip())
    .pipe(extractor)
}

if(platform == 'linux' && arch == 'x64') {
  download('linux-x86_64')
} else if (platform == 'linux') {
  download('linux-x86')
} else if (platform == 'darwin') {
  download('osx')
} else if (platform == 'win32') {
  console.log('Windows is not yet supported!')
} else {
  console.log('Your operating system is not supported.')
}
