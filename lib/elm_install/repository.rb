module ElmInstall
  # Handles git repositories.
  class Repository < Base
    extend Forwardable

    attr_reader :url, :path

    def_delegators :repo, :fetch

    def initialize(url, path)
      @path = path
      @url = url
    end

    # Downloads the version into a temporary directory
    Contract String => Dir
    def checkout(ref)
      repo.reset_hard
      repo.checkout ref
      directory
    end

    # Returns the directory of the repository
    Contract None => Dir
    def directory
      # This removes the .git from filename
      Dir.new(File.dirname(repo.repo.path))
    end

    def versions
      repo
        .tags
        .map(&:name)
        .map { |tag| Semverse::Version.try_new tag }
        .compact
    end

    def repo
      return clone unless Dir.exist?(path)
      repo = Git.open path
      repo.reset_hard
      repo
    end

    # Clonse the repository
    Contract None => Git::Base
    def clone
      Logger.arrow "Package: #{url.bold} not found in cache, cloning..."
      FileUtils.mkdir_p path
      Git.clone(url, path)
    end
  end
end
