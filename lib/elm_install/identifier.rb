module ElmInstall
  # Identifies dependencies
  class Identifier < Base
    attr_reader :initial_dependencies
    attr_reader :options

    # Initialize a new identifier.
    Contract Dir => Identifier
    def initialize(directory)
      @dependency_sources = dependency_sources directory
      @initial_dependencies = identify directory
      @options = {}
      self
    end

    Contract Dir => HashOf[String => Any]
    def dependency_sources(directory)
      json(directory)['dependency-sources'].to_h
    end

    Contract Dir => Semverse::Version
    def version(directory)
      Semverse::Version.new(json(directory)['version'])
    end

    # Identifies dependencies from a directory
    Contract Dir => ArrayOf[Dependency]
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
          if dependency_sources.key?(package) then
            source = dependency_sources[package]
            case source
            when Hash
              uri_type source['url'], Branch::Just(source['ref'])
            when String
              uri_type source, Branch::Just('master')
            end
          else
            Type::Git(Uri::Github(package), Branch::Nothing())
          end

        type.source.identifier = self

        Dependency.new(package, type.source, constraints)
      end
    end

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
    def json(directory)
      path = File.join(directory, 'elm-package.json')
      JSON.parse(File.read(path))
    rescue JSON::ParserError
      exit "Invalid JSON in file: #{path.bold}", options
    rescue Errno::ENOENT
      exit "Could not find file: #{path.bold}", options
    end

    def exit(message, options)
      return {} if options[:silent]
      Logger.arrow message
      Process.exit
    end
  end
end
