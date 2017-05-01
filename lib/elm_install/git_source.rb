module ElmInstall
  # Git Source
  class GitSource < Source
    attr_reader :uri, :branch

    # Initializes a git source by URI and branch
    Contract Uri, Branch => GitSource
    def initialize(uri, branch)
      @branch = branch
      @uri = uri
      self
    end

    # Downloads the version into a temporary directory
    Contract Or[String, Semverse::Version] => Dir
    def fetch(version)
      # Get the reference from the branch
      ref =
        case @branch
        when Branch::Just
          @branch.ref
        when Branch::Nothing
          version
        end

      repository.reset_hard
      repository.checkout ref
      repository_directory
    end

    # Returns the directory of the repository
    Contract None => Dir
    def repository_directory
      # This removes the .git from filename
      Dir.new(File.dirname(repository.repo.path))
    end

    # Copies the version into the given directory
    Contract Semverse::Version, Pathname => nil
    def copy_to(version, directory)
      # Delete the directory to make sure no pervious version remains if
      # we are using a branch or symlink if using Dir.
      FileUtils.rm_rf(directory) if directory.exist?

      # Create directory if not exists
      FileUtils.mkdir_p directory

      # Copy hole repository
      FileUtils.cp_r("#{fetch(version).path}/.", directory)

      # Remove .git directory
      FileUtils.rm_rf(File.join(directory, '.git'))

      nil
    end

    # Returns the available versions for a repository
    Contract None => ArrayOf[Semverse::Version]
    def versions
      case @branch
      when Branch::Just
        [ identifier.version(fetch(@branch.ref)) ]
      when Branch::Nothing
        repository
          .tags
          .map(&:name)
          .map { |tag| Semverse::Version.try_new tag }
          .compact
      end
    end

    # Returns the url for the repository
    Contract None => String
    def url
      case @uri
      when Uri::Github
        "https://github.com/#{@uri.name}"
      when Uri::Ssh
        @uri.uri.to_s
      when Uri::Http
        @uri.uri.to_s
      end
    end

    # Returns the temporary path for the repository
    Contract None => String
    def path
      case @uri
      when Uri::Github
        File.join(options[:cache_directory], @uri.name)
      when Uri::Ssh
        File.join(options[:cache_directory], @uri.uri.path.sub(%r{^/}, ''))
      when Uri::Http
        File.join(options[:cache_directory], @uri.uri.path.sub(%r{^/}, ''))
      end
    end

    # Returns the local repository
    Contract None => Git::Base
    def repository
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
