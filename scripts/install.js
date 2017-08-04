var progress = require('request-progress')
var ProgressBar = require('progress')
var request = require('request')
var AdmZip = require('adm-zip')
var shell = require('shelljs')
var tar = require('tar-fs')
var path = require('path')
var zlib = require('zlib')
var tmp = require('tmp')
var fs = require('fs')
var os = require('os')

var versionPath = path.join(__dirname, '../lib/elm_install/version.rb')
var version =
  fs.readFileSync(versionPath, 'utf-8')
    .match(/(\d+\.\d+\.\d+)/)[1]

var homedir = path.join(__dirname, 'dist-' + version)

// We already have that version downloaded
if(fs.existsSync(homedir)){ process.exit() }

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

var downloadRequest = function(url) {
  var bar, lastTransferred

  return progress(request.get(url))
    .on("progress", function(data){
      if (bar) {
        bar.tick(data.size.transferred - lastTransferred)
        lastTransferred = data.size.transferred
      } else {
        lastTransferred = 0
        bar = new ProgressBar(
          'Downloading and extracting the binary: [:bar] :rate/bps :percent :etas',
          {
            total: data.size.total,
            incomplete: ' ',
            complete: '=',
            width: 60
          }
        )
      }
    })
}

var download = function(suffix){
  downloadRequest(packageUrl(suffix))
    .pipe(zlib.createGunzip())
    .pipe(extractor)
}

if(platform === 'linux' && arch === 'x64') {
  download('linux-x86_64')
} else if (platform === 'linux') {
  download('linux-x86')
} else if (platform === 'darwin') {
  download('osx')
} else if (platform === 'win32') {
  var tmpFile = tmp.fileSync()
  var url =
    [ prefix,
      'v' + version,
      'elm-install-' + version + '-win32.zip'
    ].join('/')

  downloadRequest(url)
    .pipe(fs.createWriteStream(tmpFile.name))
    .on('finish', function(){
      var zip = new AdmZip(tmpFile.name)
      zip.extractAllTo(homedir)
    })
} else {
  console.log('Your operating system is not supported.')
}
