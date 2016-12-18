var SemverResolver = require('semver-resolver').SemverResolver;
var exec = require('child_process').exec;
var request = require('request');
var semver = require('semver');
var colors = require('colors');
var async = require('async');
var path = require('path');
var tmp = require('tmp');
var fs = require('fs');
var AdmZip = require('adm-zip');

var config = {};

var isSsh = function(packageName) {
    var pkgConf = config[packageName];
    return !!pkgConf;
};

var repoHost = function(packageName) {
    return config[packageName];
};

// Returns a function that downloads the given github repository at the given
// reference and extracts it to elm-stuff/packages/owner/repository/reference
var installExternalPackage = function (packageName, ref) {
    return function (callback) {

        // Skip if it's already downloaded
        var packagePathStr = 'elm-stuff/packages/' + packageName;
        if (fs.existsSync(path.resolve(packagePathStr + '/' + ref))) {
            console.log(' ●'.blue, packageName + ' - ' + ref + ' (already present)');
            return callback()
        }

        if (isSsh(packageName)) {

            var h = repoHost(packageName);

            var cmd = 'rm -rf ' + packagePathStr +
                ' && git clone --depth 1 --branch ' +
                ref + ' git@' + h +
                ':' + packageName + '.git ' + packagePathStr + '/' + ref;

            // console.log("installExternalPackage: cmd=" + cmd);

            exec(cmd, function(error, stdout, stderr){
                if (error) {
                    console.log(' ●'.red, packageName + ' - ' + ref, error, stdout, stderr);
                    callback(error);
                } else {
                    console.log(' ●'.green, packageName + ' - ' + ref + " (ssh@"
                        + h
                        + ")"
                    );
                    callback();
                }
            });


        } else {

            var packagePath = path.resolve(packagePathStr);
            var archiveUrl = 'https://github.com/' + packageName + '/archive/' + ref + '.zip';

            // Set up a temp file to store the archive in
            var tmpFile = tmp.fileSync({});

            // Get the archive into the temp file
            request
                .get(archiveUrl)
                .pipe(fs.createWriteStream(tmpFile.name))
                .on('error', function(err) {
                    callback(err);
                })
                .on('finish', function () {
                    // Extract the contents to the directory
                    var zip = new AdmZip(tmpFile.name);
                    var repo = packageName.split('/').pop();
                    zip.extractAllTo(path.resolve(packagePath), true);
                    fs.renameSync(path.resolve(packagePath, repo + '-' + ref), path.resolve(packagePath, ref));
                    console.log(' ●'.green, packageName + ' - ' + ref);
                    callback();
                })
        }
    }
};

// Converts an Elm dependency version into a semver.
// For exmaple: 4.0.4 <= v < 5.0.0  becomes >= 4.0.4 < 5.0.0
var getSemerVersion = function (version) {
    var match = version.match(/(\d+\.\d+\.\d+)<=v<(\d+\.\d+\.\d+)/);
    if (match) {
        return '>=' + match[1] + ' <' + match[2];
    }
    match = version.match(/(\d+\.\d+\.\d+)<=v<=(\d+\.\d+\.\d+)/);
    if (match) {
        return '>=' + match[1] + ' <=' + match[2];
    }
    match = version.match(/(\d+\.\d+\.\d+)<v<=(\d+\.\d+\.\d+)/);
    if (match) {
        return '>' + match[1] + ' <=' + match[2];
    }
    match = version.match(/(\d+\.\d+\.\d+)<v<(\d+\.\d+\.\d+)/);
    if (match) {
        return '>' + match[1] + ' <' + match[2];
    }
    return version;
};

// Transform all Elm dependencies into the semver versions.
var transformDependencies = function (deps) {
    var result = {};
    Object.keys(deps).forEach(function (key) {
        result[key] = getSemerVersion(deps[key].replace(/\s/g, ''));
    });
    return result;
};

// Get the dependencies for a given package and reference.
var getDependencies = function (packageName, ref) {
    return new Promise(function (fulfill, reject) {
        getPackageJson(packageName, ref)
            .then(function (json) {
                fulfill(transformDependencies(json.dependencies));
            })
            .catch(function(err) {
                reject(err);
            });
    });
};


// Get the contents of the elm-package.json of the given package and reference
var getPackageJson = function (packageName, ref) {

    // console.log("getPackageJson: package=" + package + ", ref=" + ref);

    if (isSsh(packageName)) {
        return getPackageJsonSsh(packageName, ref);
    } else {
        var packageUrl = 'https://github.com/' + packageName + '/raw/' + ref + '/elm-package.json';
        return new Promise(function (fulfill, reject) {
            request.get(packageUrl, function (error, response, body) {
                if (error) {
                    reject(error);
                } else {
                    fulfill(JSON.parse(body));
                }
            });
        });
    }
};

var getPackageJsonSsh = function(packageName, ref) {

    // console.log("getPackageJsonSsh: urlAndPackage=" + JSON.stringify(urlAndPackage, null, "  ") + ", ref=" + ref);

    return new Promise(function (fulfill, reject) {

        var repoName = packageName.split('/')[1];

        var host = repoHost(packageName);

        var cmd = 'cd /tmp && rm -rf ' + repoName +
            ' && git clone --no-checkout --depth 1 --branch ' +
            ref + ' git@' + host +
            ':' + packageName + '.git &&' +
            'cd elm-cassie && git show HEAD:elm-package.json';

        // console.log("getVersions: cmd=" + cmd);

        exec(cmd, function(error, stdout, stderr){
            if (error) {
                console.error(stdout);
                console.error(stderr);
                reject(error);
            } else {
                fulfill(JSON.parse(stdout));
            }
        });

    });
};


// Get all available versions (tags) for a given package
var getVersions = function (packageName) {

    // console.log("getVersions: package=" + package);

    return new Promise(function (fulfill, reject) {

        var cmd;
        if (isSsh(packageName)) {
            cmd = 'git ls-remote git+ssh://' + repoHost(packageName) + '/' + packageName + ".git | awk -F/ '{ print $3 }'";
        } else {
            cmd = 'git ls-remote git://github.com/' + packageName + ".git | awk -F/ '{ print $3 }'";
        }

        // console.log("getVersions: cmd=" + cmd);

        exec(cmd, function (error, stdout, stderr) {
            if (error) {
                console.error(stdout);
                console.error(stderr);
                reject(error);
            } else {
                var versions = stdout.trim()
                    .split("\n")
                    .filter(function (version) {
                        // filter out not valid tags (0.2.3^{})
                        return semver.valid(version);
                    });
                fulfill(versions);
            }
        });
    });
};

// The installer function
module.exports = function () {

    var curDir = process.cwd();

    var configFileName = curDir + '/elm-github-package.json';
    var configFilePath = path.resolve(configFileName);
    if (fs.existsSync(configFilePath)) {
        console.log("Config file found in " + configFilePath);
        config = JSON.parse(fs.readFileSync(configFilePath, { encoding: 'utf-8' }));
    // } else {
    //     console.log("No config file found in current dir");
    }


    // Get the config of the elm-package.json
    var packageConfig = require(path.resolve('elm-package.json'));

    // Transform dependencies into semver versions
    var packages = transformDependencies(packageConfig.dependencies);

    // Create a resolver
    var resolver = new SemverResolver(packages, getVersions, getDependencies);

    console.log('Resolving versions...');

    resolver.resolve().then(function (deps) {
        // We have all the dependencies resolved

        // Create an array of install functions
        var installs = Object.keys(deps).map(function (packageName) {
            return installExternalPackage(packageName, deps[packageName]);
        });

        console.log('Starting downloads...\n');

        // Run installs in paralell
        async.parallel(installs, function (error) {
            if (error) {
                console.log('\nSome packages failed to install!');
            } else {
                // Write te exact-dependencies.json
                var depsStr = JSON.stringify(deps, null, '  ');
                fs.writeFileSync(path.resolve('elm-stuff/exact-dependencies.json'), depsStr);
                console.log('\nPackages configured successfully!');
            }
        })
    }, function () {
        console.log('error', arguments)
    });
};
