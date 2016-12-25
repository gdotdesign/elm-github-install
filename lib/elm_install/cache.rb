require_relative './base'

module ElmInstall
  # This class is responsible for maintaining a cache
  # of all the repositories their versions and their dependencies.
  #
  # By default the clones of the repositories live in the users
  # home directory (~/.elm-install), this can be changed with
  # the `directory` option.
  class Cache < Base
    def initialize(options)
      @file = 'cache.json'
      super options
    end

    # Adds a new dependency to the cache for a given package & version
    # combination.
    def dependency(package, version, constraint)
      ensure_package version
      @cache[package][version] << constraint
    end

    # Ensures that a package & version combination exists in the cache.
    def ensure_version(package, version)
      ensure_package package
      @cache[package][version] ||= []
    end

    # Ensures that a package exists in the cache.
    def ensure_package(package)
      @cache[package] ||= {}
    end
  end
end
