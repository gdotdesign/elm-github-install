require 'smart_colored/extend'
require 'git_clone_url'
require 'forwardable'
require 'indentation'
require 'fileutils'
require 'contracts'
require 'hashdiff'
require 'json'
require 'adts'
require 'git'

require 'solve/constraint'
require 'solve'

require_relative './elm_install/version'
require_relative './elm_install/utils'
require_relative './elm_install/resolver'
require_relative './elm_install/logger'

# The main module for the gem.
module ElmInstall
  module_function

  # Starts an install with the given isntallation.
  #
  # @param options [Hash] The options
  #
  # @return [void]
  def install(options = { verbose: false })
    Installer.new
  end
end
