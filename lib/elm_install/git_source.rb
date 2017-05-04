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
          version.to_simple
        end

      repository.checkout ref
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
    Contract ArrayOf[Solve::Constraint] => ArrayOf[Semverse::Version]
    def versions(constraints)
      case @branch
      when Branch::Just
        [identifier.version(fetch(@branch.ref))]
      when Branch::Nothing
        matches = matching_versions constraints
        return matches if matches.any?
        Logger.arrow(
          "Could not find matching versions for: #{package_name.bold}"\
          ' in cache. Fetching updates.'
        )
        repository.fetch
        matching_versions constraints
      end
    end

    def matching_versions(constraints)
      repository
        .versions
        .select do |version|
          constraints.all? { |constraint| constraint.satisfies?(version) }
        end
    end

    # Returns the url for the repository
    Contract None => String
    def url
      @uri.to_s
    end

    # Returns the temporary path for the repository
    Contract None => String
    def path
      File.join(options[:cache_directory], host, package_name)
    end

    Contract None => String
    def host
      case @uri
      when Uri::Github
        'github.com'
      else
        @uri.uri.host
      end
    end

    # Returns the temporary path for the repository
    Contract None => String
    def package_name
      case @uri
      when Uri::Github
        @uri.name
      else
        @uri.uri.path.sub(%r{^/}, '')
      end
    end

    # Returns the local repository
    Contract None => Repository
    def repository
      @repository ||= Repository.new url, path
    end

    def to_log
      case @uri
      when Uri::Ssh, Uri::Http
        case @branch
        when Branch::Just
          "#{url} at #{@branch.ref}"
        else
          url
        end
      end
    end
  end
end
