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
      @ref_cache = {}
      @cache = {}
      load
    end

    # Saves the cache into the json file.
    def save
      File.binwrite(ref_file, JSON.pretty_generate(@ref_cache))
      File.binwrite(file, JSON.pretty_generate(@cache))
    end

    # Loads a cache from the json file.
    def load
      @ref_cache = JSON.parse(File.read(ref_file))
      @cache = JSON.parse(File.read(file))
    rescue
      @ref_cache = {}
      @cache = {}
    end

    def clear
      @ref_cache = {}
    end

    # Returns the directory where the cache is stored.
    def directory
      @options[:directory] || File.join(Dir.home, '.elm-install')
    end

    # Returns if there is a package in the cache (with at least one version).
    def package?(package)
      @ref_cache.key?(package) && @cache.key?(package)
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
      repo = nil

      if Dir.exist?(repo_path)
        repo = Git.open(repo_path)
        repo.reset_hard

        unless @ref_cache[path]
          refs = refs_for(repo_path)

          if HashDiff.diff(@ref_cache[path], refs).empty?
            Utils.log_with_arrow "Package: #{path.bold} is outdated fetching changes..."
            repo.fetch
          end

          @ref_cache[path] = refs
        end
      else
        Utils.log_with_arrow "Package: #{path.bold} not found in cache, cloning..."
        repo = Git.clone(path, repo_path)
        @ref_cache[path] = refs_for(repo_path)
      end

      repo
    end

    private

    def refs_for(repo_path)
      refs = Git.ls_remote(repo_path)
      refs.delete('head')
    end

    def ref_file
      File.join(directory, 'ref-cache.json')
    end

    # Returns the path to the json file.
    def file
      File.join(directory, 'cache.json')
    end
  end
end
