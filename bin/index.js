#! /usr/bin/env node

var argv = require('minimist')(process.argv.slice(2))
var install_direct = require('../src/install_direct.js')
var install = require('../src/index.js')

if(argv._.length == 0){
  install()
} else {
  var package = argv._[0]
  var ref = argv._[1]
  install_direct(package, ref)
}
