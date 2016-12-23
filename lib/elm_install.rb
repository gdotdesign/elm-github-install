require 'git_clone_url'
require 'forwardable'
require 'fileutils'
require 'colorize'
require 'solve'
require 'json'
require 'git'

require_relative './elm_install/installer'

# The main module for the gem.
module ElmInstall
  module_function

  def install(options = { verbose: false })
    Installer.new(options).install
  end
end

ElmInstall.install
