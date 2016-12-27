require_relative './base'

module ElmInstall
  # This class is responsible for maintaining a cache
  # of all the repositories their versions and their dependencies.
  #
  # By default the clones of the repositories live in the users
  # home directory (~/.elm-install), this can be changed with
  # the `directory` option.
  class Cache < Base
    # Initializes a cache with the given options.
    #
    # @param options [Hash] The options
    def initialize(options)
      @file = 'cache.json'
      super options
    end

    # Adds a new dependency to the cache for a given package & version
    # combination.
    #
    # @param package [String] The url of the package
    # @param version [String] The semver version (1.0.0 or 1.0.0+master)
    # @param constraint [Array] The constraint ["pacakge", "<= 1.0.0"]
    #
    # @return [Array] The dependencies of the package & version combination
    def dependency(package, version, constraint)
      ensure_package version
      @cache[package][version] << constraint
    end

    # Ensures that a package & version combination exists in the cache.
    #
    # @param package [String] The url of the package
    # @param version [String] The semver version (1.0.0 or 1.0.0+master)
    #
    # @return [Array] The dependencies of the package & version combination
    def ensure_version(package, version)
      ensure_package package
      @cache[package][version] ||= []
    end

    # Ensures that a package exists in the cache.
    #
    # @param package [String] The url of the package
    #
    # @return [Hash] The dependency hash of the package
    def ensure_package(package)
      @cache[package] ||= {}
    end
  end
end
