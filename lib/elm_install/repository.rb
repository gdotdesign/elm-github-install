module ElmInstall
  # Handles git repositories.
  class Repository < Base
    extend Forwardable

    # The url of the git repository
    # @return [String]
    attr_reader :url

    # The path to the directory where the repository lives
    # @return [String]
    attr_reader :path

    def_delegators :repo, :fetch

    Contract String, String => Repository
    # Initializes a repository.
    #
    # @param url [String] The url
    # @param path [String] The path
    #
    # @return [Repository] The repository instance
    def initialize(url, path)
      @path = path
      @url = url
      self
    end

    Contract String => Dir
    # Checks out the version and returns it's directory
    #
    # @param ref [String] The reference to checkout
    #
    # @return [Dir] The directory
    def checkout(ref)
      repo.checkout ref
      directory
    end

    Contract None => Dir
    # Returns the directory of the repository
    #
    # @return [Dir] The directory
    def directory
      # This removes the .git from filename
      Dir.new(File.dirname(repo.repo.path))
    end

    Contract None => ArrayOf[Semverse::Version]
    # Returns the versions of the repository
    #
    # @return [Array<Semverse::Version>] The versions
    def versions
      repo
        .tags
        .map(&:name)
        .map { |tag| Semverse::Version.try_new tag }
        .compact
    end

    Contract None => Git::Base
    # Returns the existing repository or clones it if it does not exists.
    #
    # @return [Git::Base]
    def repo
      clone unless Dir.exist?(path)
      @repo ||= Git.open path
      @repo.reset_hard
      @repo
    end

    Contract None => Git::Base
    # Clones the repository
    #
    # @return [Git::Base]
    def clone
      Logger.arrow "Package: #{url.bold} not found in cache, cloning..."
      FileUtils.mkdir_p path
      @repo = Git.clone(url, path)
    end
  end
end
