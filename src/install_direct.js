var request = require('request')
var AdmZip = require('adm-zip')
var rmdir = require('rimraf')
var path = require('path')
var tmp = require('tmp')
var fs = require('fs')

// Returns a function that downloads the given github repository at the given
// reference and extracts it to elm-stuff/packages/owner/repository/reference
module.exports = function(package, ref) {
  console.log('Installing directly from github ref...')
  var packageUrl = 'https://github.com/' + package + '/raw/' + ref + '/elm-package.json'
  var archiveUrl = 'https://github.com/' + package + '/archive/' + ref + '.zip'
  var packagePath = path.resolve('elm-stuff/packages/' + package)

  // Set up a temp file to store the archive in
  var tmpFile = tmp.fileSync()

  // Get package.json
  request(packageUrl, function(error, response, body){
    version = JSON.parse(body).version

    // Get the archive into the temp file
    request
      .get(archiveUrl)
      .pipe(fs.createWriteStream(tmpFile.name))
      .on('finish', function(){
        // Extract the contents to the directory
        var zip = new AdmZip(tmpFile.name);
        var repo = package.split('/').pop();
        zip.extractAllTo(path.resolve(packagePath));
        rmdir(path.resolve(packagePath, version), { glob: false }, function(){
          fs.renameSync(path.resolve(packagePath, repo + '-' + ref),
                        path.resolve(packagePath, version));
          console.log(' ●'.green, package + ' - ' + ref + '(' + version + ')');

          var extDepsPath = path.resolve('elm-stuff/exact-dependencies.json')
          var deps = require(extDepsPath)
          deps[package] = version

          fs.writeFileSync(extDepsPath,JSON.stringify(deps, null, '  '))
        })
      })
  })
}
