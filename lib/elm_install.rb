require 'smart_colored/extend'
require 'git_clone_url'
require 'forwardable'
require 'indentation'
require 'fileutils'
require 'hashdiff'
require 'solve'
require 'json'
require 'git'

require_relative './elm_install/version'
require_relative './elm_install/installer'

# The main module for the gem.
module ElmInstall
  module_function

  def install(options = { verbose: false })
    Installer.new(options).install
  end
end
