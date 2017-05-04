module ElmInstall
  # Identifies dependencies
  class Identifier < Base
    attr_reader :initial_dependencies
    attr_reader :options

    Contract Dir, Hash => Identifier
    # Initialize a new identifier.
    #
    # @param directory [Dir] The initial directory
    # @param options [Hash] The options
    #
    # @return [Indentifier] The identifier instance
    def initialize(directory, options = {})
      @options = options
      @dependency_sources = dependency_sources directory
      @initial_dependencies = identify directory
      self
    end

    Contract Dir => HashOf[String => Any]
    # Returns the dependency sources for the given directory.
    #
    # @param directory [Dir] The directory
    #
    # @return [Hash] The directory sources
    def dependency_sources(directory)
      json(directory)['dependency-sources'].to_h
    end

    Contract Dir => Semverse::Version
    # Returns the version of a package in the given directory.
    #
    # @param directory [Dir] The directory
    #
    # @return [Semverse::Version] The version
    def version(directory)
      Semverse::Version.new(json(directory)['version'])
    end

    Contract Dir => ArrayOf[Dependency]
    # Identifies dependencies from a directory
    #
    # @param directory [Dir] The directory
    #
    # @return [Array] The dependencies
    def identify(directory)
      raw = json(directory)

      dependencies = raw['dependencies'].to_h

      dependency_sources =
        raw['dependency-sources']
        .to_h
        .merge(@dependency_sources)

      dependencies.map do |package, constraint|
        constraints = Utils.transform_constraint constraint

        type =
          if dependency_sources.key?(package)
            source = dependency_sources[package]
            case source
            when Hash
              uri_type source['url'], Branch::Just(source['ref'])
            when String
              if File.exist?(source)
                Type::Directory(Pathname.new(source))
              else
                uri_type source, Branch::Just('master')
              end
            end
          else
            Type::Git(Uri::Github(package), Branch::Nothing())
          end

        type.source.identifier = self
        type.source.options = @options

        Dependency.new(package, type.source, constraints)
      end
    end

    Contract String, Branch => Type
    # Returns the type from the given arguments.
    #
    # @param url [String] The base url
    # @param branch [Branch] The branch
    #
    # @return [Type] The type
    def uri_type(url, branch)
      uri = GitCloneUrl.parse(url)
      case uri
      when URI::SshGit::Generic
        Type::Git(Uri::Ssh(uri), branch)
      when URI::HTTP
        Type::Git(Uri::Http(uri), branch)
      end
    end

    Contract Dir => HashOf[String => Any]
    # Returns the contents of the 'elm-package.json' for the given directory.
    #
    # @param directory [Dir] The directory
    #
    # @return [Hash] The contents
    def json(directory)
      path = File.join(directory, 'elm-package.json')
      JSON.parse(File.read(path))
    rescue JSON::ParserError
      exit "Invalid JSON in file: #{path.bold}"
      {}
    rescue Errno::ENOENT
      exit "Could not find file: #{path.bold}"
      {}
    end

    Contract String => NilClass
    # Exits the current process and logs a given message.
    #
    # @param message [String] The message
    #
    # @return nil
    def exit(message)
      Logger.arrow message
      Process.exit
      nil
    end
  end
end
