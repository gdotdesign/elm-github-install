require 'git_clone_url'
require 'forwardable'
require 'fileutils'
require 'solve'
require 'json'
require 'git'

require_relative './elm_install/installer'

# The main module for the gem.
module ElmInstall
  module_function

  def install
    Installer.new(verbose: true).install
  end
end
