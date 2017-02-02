require_relative './logger'

module ElmInstall
  # This class if for cloning and fetching repositories based
  # on a cache.
  class GitResolver < Base
    # Initializes a git resolver with the given options.
    #
    # @param options [Hash] The options
    def initialize(options)
      @file = 'ref-cache.json'
      super options
      @check_cache =
        @cache.keys.each_with_object({}) { |key, memo| memo[key] = true }
    end

    # Returns the refs for a given url.
    #
    # @param url [String] the url
    #
    # @return [Hash] The refs
    def refs(url)
      self.class.refs(url)
    end

    # Clears the cache
    #
    # @return [void]
    def clear
      @check_cache = {}
    end

    # Returns the refs for a given url.
    #
    # @param url [String] the url
    #
    # @return [Hash] The refs
    def self.refs(url)
      refs = Git.ls_remote url
      refs.delete 'head'
      JSON.parse(refs.to_json)
    end

    # Returns if the given package (url) is in the cache.
    #
    # @param url [String] The url
    #
    # @return [Boolean] True if exists false if not
    def package?(url)
      @check_cache.key?(repository_path(url))
    end

    # Returns the path of the repository for a given url.
    #
    # :reek:FeatureEnvy
    #
    # @param url [String] The url
    #
    # @return [String] The path
    def repository_path(url)
      return url.sub('file://', '') if url.start_with?('file://')
      uri = GitCloneUrl.parse(url)
      File.join(directory, uri.host, uri.path)
    end

    # Returns a git repository object for the given url, cloning it
    # if it does not exists.
    #
    # @param url [String] The url
    #
    # @return [Git::Base] The repository
    def repository(url)
      open(url) do |repo|
        update_cache repo
      end
    end

    # Updates a repository checking it's refs and fetching changes if needed.
    #
    # @param repo [Git::Base] The repository
    #
    # @return [void]
    def update_cache(repo)
      directory = File.dirname(repo.repo.path)
      url = repo.remote.url
      refs = refs(url)

      unless HashDiff.diff(cache[directory], refs).empty?
        Logger.arrow "Package: #{url.bold} is outdated, fetching changes..."
        repo.fetch
      end

      @check_cache[directory] = true
      cache[directory] = refs
    end

    # Opens a git repository cloning if it's not exists.
    #
    # @param url [String] The url
    #
    # @return [Git::Base] The repository
    def open(url)
      path = repository_path(url)

      return clone url, path unless Dir.exist?(path)

      repo = Git.open path
      repo.reset_hard

      yield repo unless @check_cache[path]

      repo
    end

    # Clones the repostiry from the given url to the given path.
    #
    # @param url [String] The url
    # @param path [String] The path
    #
    # @return [Git::Base] The repository
    def clone(url, path)
      Logger.arrow "Package: #{url.bold} not found in cache, cloning..."
      FileUtils.mkdir_p path
      repo = Git.clone(url, path)
      @check_cache[path] = true
      cache[path] = refs url
      repo
    end
  end
end
