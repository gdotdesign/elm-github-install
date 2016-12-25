require_relative './logger'

module ElmInstall
  # This class if for cloning and fetching repositories based
  # on a cache.
  class GitResolver < Base
    def initialize(options)
      @file = 'ref-cache.json'
      super options
    end

    def refs(url)
      self.class.refs(url)
    end

    def self.refs(url)
      refs = Git.ls_remote url
      refs.delete 'head'
      refs
    end

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

      cache[directory] = refs
    end

    def open(url)
      path = repository_path(url)

      return clone url, path unless Dir.exist?(path)

      repo = Git.open path
      repo.reset_hard

      yield repo unless cache[path]

      repo
    end

    def clone(url, path)
      Logger.arrow "Package: #{url.bold} not found in cache, cloning..."
      FileUtils.mkdir_p path
      repo = Git.clone(url, path)
      cache[path] = refs url
      repo
    end
  end
end
