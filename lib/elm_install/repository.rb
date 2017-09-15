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

    # Whether or not the repository has been fetched (updated)
    # @return [Bool]
    attr_reader :fetched

    Contract String, String => Repository
    # Returns the repository for the given url and path
    #
    # @param url [String] The url
    # @param path [String] The path
    #
    # @return [Repository] The repository
    def self.of(url, path)
      @repositories ||= {}
      @repositories[url] ||= new url, path
    end

    Contract String, String => Repository
    # Initializes a repository.
    #
    # @param url [String] The url
    # @param path [String] The path
    #
    # @return [Repository] The repository instance
    def initialize(url, path)
      @fetched = false
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
      @versions ||=
        repo
        .tags
        .map(&:name)
        .select { |tag| tag =~ /(.*\..*\..*)/ }
        .map { |tag| Semverse::Version.try_new tag }
        .compact
    end

    Contract None => Git::Base
    # Returns the existing repository or clones it if it does not exists.
    #
    # @return [Git::Base]
    def repo
      clone unless cloned?
      @repo ||= Git.open path
      @repo.reset_hard
      @repo
    end

    # Returns if the repository has been cloned yet or not
    #
    # @return [Bool]
    def cloned?
      Dir.exist?(path)
    end

    # Fetches changes from a repository
    #
    # @return [Void]
    def fetch
      return if fetched
      repo.fetch
      @fetched = true
    end

    Contract None => Git::Base
    # Clones the repository
    #
    # @return [Git::Base]
    def clone
      Logger.arrow "Package: #{url.bold} not found in cache, cloning..."
      FileUtils.mkdir_p path
      @fetched = true
      @repo = Git.clone(url, path)
    end
  end
end
