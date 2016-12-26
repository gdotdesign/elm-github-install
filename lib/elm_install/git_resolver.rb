require_relative './logger'

module ElmInstall
  # This class if for cloning and fetching repositories based
  # on a cache.
  class GitResolver < Base
    def initialize(options)
      @file = 'ref-cache.json'
      super options
      @check_cache =
        @cache.keys.each_with_object({}) { |key, memo| memo[key] = true }
    end

    def refs(url)
      self.class.refs(url)
    end

    def clear
      @check_cache = {}
    end

    def self.refs(url)
      refs = Git.ls_remote url
      refs.delete 'head'
      JSON.parse(refs.to_json)
    end

    def package?(url)
      @check_cache.key?(repository_path(url))
    end

    # :reek:FeatureEnvy
    def repository_path(url)
      uri = GitCloneUrl.parse(url)
      File.join(directory, uri.host, uri.path)
    end

    def repository(url)
      open(url) do |repo|
        update_cache repo
      end
    end

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

    def open(url)
      path = repository_path(url)

      return clone url, path unless Dir.exist?(path)

      repo = Git.open path
      repo.reset_hard

      yield repo unless @check_cache[path]

      repo
    end

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
