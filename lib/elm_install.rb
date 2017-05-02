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
require_relative './elm_install/logger'
require_relative './elm_install/ext'
require_relative './elm_install/base'
require_relative './elm_install/types'
require_relative './elm_install/source'
require_relative './elm_install/directory_source'
require_relative './elm_install/repository'
require_relative './elm_install/git_source'
require_relative './elm_install/dependency'
require_relative './elm_install/identifier'
require_relative './elm_install/resolver'
require_relative './elm_install/populator'
require_relative './elm_install/installer'

# The main module for the gem.
module ElmInstall
  module_function

  # Starts an install with the given isntallation.
  #
  # @param options [Hash] The options
  #
  # @return [void]
  def install(options = { verbose: false })
    Installer.new(options).install
  end
end
