require_relative './graph_builder'

module ElmInstall
  # This class is responsible for maintaining a cache
  # of all the repositories their versions and their dependencies.
  #
  # By default the clones of the repositories live in the users
  # home directory (~/.elm-install), this can be changed with
  # the `directory` option.
  class Cache
    extend Forwardable

    def_delegators :@cache, :each

    # Initializes a new cache with the given options.
    def initialize(options = {})
      @options = options
      @cache = {}
      load
    end

    # Saves the cache into the json file.
    def save
      File.binwrite(file, JSON.pretty_generate(@cache))
    end

    # Loads a cache from the json file.
    def load
      @cache = JSON.parse(File.read(file))
    rescue
      @cache = {}
    end

    # Returns the directory where the cache is stored.
    def directory
      @options[:directory] || File.join(Dir.home, '.elm-install')
    end

    # Returns if there is a package in the cache (with at least one version).
    def package?(package)
      @cache.key?(package)
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

    # Returns the path to the repository of the given package.
    def repository_path(package)
      File.join(directory, package)
    end

    # Returns the Git repository of the given package in a ready to use state.
    def repository(path)
      repo_path = repository_path(path)

      if Dir.exist?(repo_path)
        repo = Git.open(repo_path)
        repo.reset_hard
        repo
      else
        Git.clone(path, repo_path)
      end
    end

    private

    # Returns the path to the json file.
    def file
      File.join(directory, 'cache.json')
    end
  end
end
