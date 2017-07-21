module ElmInstall
  # Git Source
  class GitSource < Source
    # @return [Uri] The uri
    attr_reader :uri

    # @return [Branch] The branch
    attr_reader :branch

    Contract Uri, Branch => GitSource
    # Initializes a git source by URI and branch
    #
    # @param uri [Uri] The uri
    # @param branch [Branch] The branch
    #
    # @return [GitSource]
    def initialize(uri, branch)
      @branch = branch
      @uri = uri
      self
    end

    Contract Or[String, Semverse::Version] => Dir
    # Downloads the version into a temporary directory
    #
    # @param version [Semverse::Version] The version to fetch
    #
    # @return [Dir] The directory for the source of the version
    def fetch(version)
      # Get the reference from the branch
      ref =
        case @branch
        when Branch::Just
          @branch.ref
        when Branch::Nothing
          version.to_simple
        end

      repository.checkout ref
    end

    Contract Semverse::Version, Pathname => nil
    # Copies the version into the given directory
    #
    # @param version [Semverse::Version] The version
    # @param directory [Pathname] The pathname
    #
    # @return nil
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

    Contract ArrayOf[Solve::Constraint] => ArrayOf[Semverse::Version]
    # Returns the available versions for a repository
    #
    # @param constraints [Array] The constraints
    #
    # @return [Array] The versions
    def versions(constraints)
      # Get updates from upstream
      Logger.arrow "Getting updates for: #{package_name.bold}"
      repository.fetch

      case @branch
      when Branch::Just
        [identifier.version(fetch(@branch.ref))]
      when Branch::Nothing
        matching_versions constraints
      end
    end

    Contract ArrayOf[Solve::Constraint] => ArrayOf[Semverse::Version]
    # Returns the matchign versions for a repository for the given constraints
    #
    # @param constraints [Array] The constraints
    #
    # @return [Array] The versions
    def matching_versions(constraints)
      repository
        .versions
        .select do |version|
          constraints.all? { |constraint| constraint.satisfies?(version) }
        end
        .sort
        .reverse
    end

    Contract None => String
    # Returns the url for the repository
    #
    # @return [String] The url
    def url
      @uri.to_s
    end

    Contract None => String
    # Returns the temporary path for the repository
    #
    # @return [String] The path
    def path
      File.join(options[:cache_directory].to_s, host, package_name)
    end

    Contract None => String
    # Returns the host for the repository
    #
    # @return [String] The host
    def host
      case @uri
      when Uri::Github
        'github.com'
      else
        @uri.uri.host
      end
    end

    Contract None => String
    # Returns the package name for the repository
    #
    # @return [String] The name
    def package_name
      case @uri
      when Uri::Github
        @uri.name
      else
        @uri.uri.path.sub(%r{^/}, '')
      end
    end

    Contract None => Repository
    # Returns the local repository
    #
    # @return [Repository] The repository
    def repository
      @repository ||= Repository.new url, path
    end

    Contract None => Or[String, NilClass]
    # Returns the log format
    #
    # @return [String]
    def to_log
      case @uri
      when Uri::Ssh, Uri::Http
        case @branch
        when Branch::Just
          "#{url} at #{@branch.ref}"
        else
          # NOTE: Cannot happen
          # :nocov:
          url
          # :nocov:
        end
      else
        url
      end
    end
  end
end
