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

// Returns a function that downloads the given github repository at the given
// reference and extracts it to elm-stuff/packages/owner/repository/reference
var installExternalPackage = function (packageName, ref) {
    return function (callback) {

        var opts = packageNameToOptions(packageName);

        // Skip if it's already downloaded
        if (fs.existsSync(path.resolve('elm-stuff/packages/' + opts.package + '/' + ref))) {
            console.log(' ●'.blue, opts.package + ' - ' + ref + ' (already present)');
            return callback()
        }

        var packagePathStr = 'elm-stuff/packages/' + opts.package;

        // console.log("installExternalPackage: packagePathStr=" + packagePathStr);

        if (opts.ssh) {

            var cmd = 'rm -rf ' + packagePathStr +
                ' && git clone --depth 1 --branch ' +
                ref + ' git@' + opts.gitHubUrl +
                ':' + opts.package + '.git ' + packagePathStr + '/' + ref;

            // var cmd2 = 'echo "fooo"';

            // console.log("installExternalPackage: cmd=" + cmd);

            exec(cmd, function(error, stdout, stderr){
                if (error) {
                    console.log(' ●'.red, opts.package + ' - ' + ref, error, stdout, stderr);
                    callback(error);
                } else {
                    console.log(' ●'.green, opts.package + ' - ' + ref + " (ssh@"
                        + opts.gitHubUrl
                        + ")"
                    );
                    callback();
                }
            });


        } else {

            var packagePath = path.resolve(packagePathStr);
            var archiveUrl = 'https://' + opts.gitHubUrl + '/' + opts.package + '/archive/' + ref + '.zip';

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
                    console.log(' ●'.green, opts.package + ' - ' + ref);
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
    var opts = packageNameToOptions(packageName);

    if (opts.ssh) {
        return getPackageJsonSsh(opts, ref);
    } else {
        var packageUrl = 'https://' + opts.gitHubUrl + '/' + opts.package + '/raw/' + ref + '/elm-package.json';
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

var getPackageJsonSsh = function(urlAndPackage, ref) {

    // console.log("getPackageJsonSsh: urlAndPackage=" + JSON.stringify(urlAndPackage, null, "  ") + ", ref=" + ref);

    return new Promise(function (fulfill, reject) {

        var repoName = urlAndPackage.package.split('/')[1];

        var cmd = 'cd /tmp && rm -rf ' + repoName +
            ' && git clone --no-checkout --depth 1 --branch ' +
            ref + ' git@' + urlAndPackage.gitHubUrl +
            ':' + urlAndPackage.package + '.git &&' +
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


// return the github url for package
var packageNameToOptions = function (packageName) {
    var parts = packageName.split(":");
    if (parts.length == 1) {
        return {
            gitHubUrl: "github.com",
            package: packageName,
            ssh: false
        };
    } else if (parts.length == 2) {
        return {
            gitHubUrl: parts[0],
            package: parts[1],
            ssh: true
        }
    } else {
        throw "Unsupported package name : " + packageName;
    }
};


// Get all available versions (tags) for a given package
var getVersions = function (packageName) {

    // console.log("getVersions: package=" + package);

    var urlAndPackage = packageNameToOptions(packageName);

    return new Promise(function (fulfill, reject) {

        var sshStr = urlAndPackage.ssh ? '+ssh' : '';

        var cmd = 'git ls-remote git' + sshStr + '://' + urlAndPackage.gitHubUrl + '/' + urlAndPackage.package + ".git | awk -F/ '{ print $3 }'";

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
                var cleanDeps = {};
                Object.keys(deps).forEach(function (key) {
                    var opts = packageNameToOptions(key);
                    cleanDeps[opts.package] = getSemerVersion(deps[key].replace(/\s/g, ''));
                });

                var depsStr = JSON.stringify(cleanDeps, null, '  ');
                fs.writeFileSync(path.resolve('elm-stuff/exact-dependencies.json'), depsStr);
                console.log('\nPackages configured successfully!');
            }
        })
    }, function () {
        console.log('error', arguments)
    });
};
