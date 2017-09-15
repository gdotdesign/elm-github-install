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
          case version
          when String
            version
          else
            version.to_simple
          end
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

    Contract String => String
    # Returns the supported Elm version the given ref.
    #
    # @param ref [String] The ref
    #
    # @return [Array] The version
    def elm_version_of(ref)
      @@elm_versions ||= {}
      @@elm_versions[url] ||= {}
      @@elm_versions[url][ref] ||= identifier.elm_version(fetch(ref))
    end

    Contract ArrayOf[Solve::Constraint],
             String, Bool => ArrayOf[Semverse::Version]
    # Returns the available versions for a repository
    #
    # @param constraints [Array] The constraints
    # @param elm_version [String] The Elm version to match against
    #
    # @return [Array] The versions
    def versions(constraints, elm_version, should_update)
      if repository.cloned? && !repository.fetched? && should_update
        # Get updates from upstream
        Logger.arrow "Getting updates for: #{package_name.bold}"
        repository.fetch
      end

      case @branch
      when Branch::Just
        [identifier.version(fetch(@branch.ref))]
      when Branch::Nothing
        matching_versions constraints, elm_version
      end
    end

    Contract ArrayOf[Solve::Constraint], String => ArrayOf[Semverse::Version]
    # Returns the matchign versions for a repository for the given constraints
    #
    # @param constraints [Array] The constraints
    # @param elm_version [String] The Elm version to match against
    #
    # @return [Array] The versions
    def matching_versions(constraints, elm_version)
      repository
        .versions
        .select do |version|
          elm_version_of(version.to_s) == elm_version &&
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
