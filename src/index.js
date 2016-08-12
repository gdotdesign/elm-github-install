var SemverResolver = require('semver-resolver').SemverResolver
var exec = require('child_process').exec
var extract = require('extract-zip')
var request = require('request')
var semver = require('semver')
var colors = require('colors')
var async = require('async')
var path = require('path')
var tmp = require('tmp')
var fs = require('fs')

// Returns a function that downloads the given github repository at the given
// reference and extracts it to elm-stuff/packages/owner/repository/reference
installExternalPackage = function(package, ref) {
  return function(callback){
    // Skip if it's already downloaded
    if(fs.existsSync(path.resolve('elm-stuff/packages/' + package + '/' + ref))){
      return callback()
    }

    var packageUrl = 'https://github.com/' + package + '/raw/' + ref + '/elm-package.json'
    var archiveUrl = 'https://github.com/' + package + '/archive/' + ref + '.zip'
    var packagePath = path.resolve('elm-stuff/packages/' + package)

    // Set up a temp file to store the archive in
    var tmpFile = tmp.fileSync()

    // Get the archive into the temp file
    request
      .get(archiveUrl)
      .pipe(fs.createWriteStream(tmpFile.name))
      .on('finish', function(){
        // Extract the contents to the directory
        extract(tmpFile.name, { dir: packagePath }, function(error){
          if(error) {
            console.log(' ✘'.red, package + ' - ' + ref)
            console.log('   ▶', error)
            callback(true)
          } else {
            // Rename the directory the archived had ( core-4.0.4 ) to
            // the given reference (4.0.4)
            var repo = package.split('/').pop()
            fs.renameSync(path.resolve(packagePath, repo + '-' + ref),
                          path.resolve(packagePath, ref))
            console.log(' ●'.green, package + ' - ' + ref)
            callback()
          }
          // Remove the temp file
          tmpFile.removeCallback()
        })
      })
  }
}

// Converts an Elm dependency version into a semver.
// For exmaple: 4.0.4 <= v < 5.0.0  becomes >= 4.0.4 < 5.0.0
var getSemerVersion = function(version) {
  var match = version.match(/(\d+\.\d+\.\d+)<=v<(\d+\.\d+\.\d+)/)
  if(match) { return '>=' + match[1] + ' <' + match[2] }
  var match = version.match(/(\d+\.\d+\.\d+)<=v<=(\d+\.\d+\.\d+)/)
  if(match) { return '>=' + match[1] + ' <=' + match[2] }
  var match = version.match(/(\d+\.\d+\.\d+)<v<=(\d+\.\d+\.\d+)/)
  if(match) { '>' + match[1] + ' <=' + match[2] }
  var match = version.match(/(\d+\.\d+\.\d+)<v<(\d+\.\d+\.\d+)/)
  if(match) { '>' + match[1] + ' <' + match[2] }
  return version
}

// Transform all Elm dependencies into the semver versions.
var transformDependencies = function(deps){
  var result = {}
  Object.keys(deps).forEach(function(key) {
    result[key] = getSemerVersion(deps[key].replace(/\s/g, ''))
  })
  return result
}

// Get the dependencies for a given package and reference.
var getDependencies = function(package, ref) {
  return new Promise(function (fulfill, reject){
    getPackageJson(package, ref)
      .then(function(json){
        fulfill(transformDependencies(json.dependencies))
      })
  })
}


// Get the contents of the elm-package.json of the given package and reference
var getPackageJson = function(package, ref){
  var packageUrl = 'https://github.com/' + package + '/raw/' + ref + '/elm-package.json'

  return new Promise(function (fulfill, reject){
    request.get(packageUrl, function(error, response, body){
      fulfill(JSON.parse(body))
    })
  })
}

// Get all available versions (tags) for a given package
var getVersions = function(package){
  return new Promise(function (fulfill, reject){
    var cmd = 'git ls-remote git://github.com/' +  package + ".git | awk -F/ '{ print $3 }'"
    exec(cmd, function(error, stdout, stderr){
      var versions = stdout.trim()
                           .split("\n")
                           .filter(function(version) {
                              // filter out not valid tags (0.2.3^{})
                              return semver.valid(version)
                           })
      fulfill(versions)
    })
  })
}

// The installer function
module.exports = function(){
  // Get the config of the elm-package.json
  var packageConfig = require(path.resolve('elm-package.json'))

  // Transform dependencies into semver versions
  var packages = transformDependencies(packageConfig.dependencies)

  // Create a resolver
  var resolver = new SemverResolver(packages, getVersions, getDependencies)

  console.log('Resolving versions...')

  resolver.resolve().then(function(deps){
    // We have all the dependencies resolved

    // Create an array of install functions
    var installs = Object.keys(deps).map(function(package){
      return installExternalPackage(package, deps[package])
    })

    console.log('Starting downloads...\n')

    // Run installs in paralell
    async.parallel(installs, function(error){
      if(error) {
        console.log('\nSome packages failed to install!')
      } else {
        // Write te exact-dependencies.json
        fs.writeFileSync(path.resolve('elm-stuff/exact-dependencies.json'),
                         JSON.stringify(deps, null, '  '))
        console.log('\nPackages configured successfully!')
      }
    })
  }, function(){
    console.log('error', arguments)
  })
}
