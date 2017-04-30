module Semverse
  class Version
    def to_simple
      "#{major}.#{minor}.#{patch}"
    end

    def self.try_new(version)
      new version
    rescue
      nil
    end
  end
end

module Solve
  class Graph
    attr_reader :artifacts_by_name
  end
end

module ElmInstall
  class Base
    include Contracts::Core
    include Contracts::Builtin
  end

  Branch = ADT do
    Just(ref: name) |
    Nothing()
  end

  Uri = ADT do
    Ssh(uri: URI::SshGit::Generic) |
    Http(uri: URI::HTTP)
  end

  Type = ADT do
    Git(uri: Uri, branch: Branch) {
      def source
        Source.new uri, branch
      end
    } |
    Directory(path: Dir) {
      def source
      end
    } |
    Registry(source: Class)
  end

  # Abstract class for resolving
  class Source < Base
    Contract Uri, Branch => Source
    def initialize(uri, branch)
      @brach = branch
      @uri = uri
      self
    end

    # Downloads the version into a temporary directory
    Contract Semverse::Version => Dir
    def fetch(version)
      repo = open
      repo.checkout(version)
      dir(repo)
    end

    def dir(repo)
      # Remove .git from filename
      Dir.new(File.dirname(repo.repo.path))
    end

    # Copies the version into the given directory
    Contract Semverse::Version, Dir => nil
    def copy_to(version, directory)
      repo = open
      repo.checkout version.to_simple
      FileUtils.cp_r("#{dir(repo).path}/.", directory)
      FileUtils.rm_rf(File.join(directory, '.git'))
      nil
    end

    def versions
      repo = open
      repo
        .tags
        .map(&:name)
        .map { |tag| Semverse::Version.try_new tag }
        .compact
    end

    def cache_file_path
      case @uri
      when Uri::Http
        File.join('.cache', @uri.uri.path.sub(%r{^/}, '') + '.versions' )
      end
    end

    def url
      case @uri
      when Uri::Http
        @uri.uri.to_s
      end
    end

    def path
      case @uri
      when Uri::Http
        File.join('.cache', @uri.uri.path.sub(%r{^/}, ''))
      end
    end

    def open
      return clone url, path unless Dir.exist?(path)

      repo = Git.open path
      repo.reset_hard
      repo
    end

    def clone(url, path)
      Logger.arrow "Package: #{url.bold} not found in cache, cloning..."
      FileUtils.mkdir_p path
      Git.clone(url, path)
    end
  end

  # Dependency
  class Dependency < Base
    extend Forwardable

    attr_reader :constraints
    attr_accessor :version
    attr_reader :source
    attr_reader :name

    # Initializes a new dependency
    Contract String, Source, ArrayOf[Solve::Constraint] => Dependency
    def initialize(name, source, constraints)
      @constraints = constraints
      @source = source
      @name = name
      self
    end

    Contract [Solve::Constraint] => Dependency
    def with_different_constraints(constraints)
      self.class.new name, source, constraints
    end
  end

  # Identifies dependencies
  class Identifier < Base
    attr_reader :options

    # Initialize a new identifier.
    # - Initial dependencies are required to
    #   resolve conflicts from different types.
    Contract ArrayOf[Dependency] => Identifier
    def initialize(initial_dependencies)
      @initial_dependencies = initial_dependencies
      @options = {}
      self
    end

    # Identifies dependencies from a directory
    Contract Dir => ArrayOf[Dependency]
    def identify(directory)
      raw = json(directory)

      dependencies = raw['dependencies'].to_h
      dependency_sources = raw['dependency-sources'].to_h

      dependencies.map do |package, constraint|
        constraints = Utils.transform_constraint constraint

        type =
          if dependency_sources.key?(package) then
            # TODO: Handle different source
          else
            uri = GitCloneUrl.parse("https://github.com/#{package}")
            if uri.is_a?(URI::HTTP)
              Type::Git(Uri::Http(uri), Branch::Nothing())
            end
          end

        Dependency.new(package, type.source, constraints)
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

  # Resolves dependencies
  class Resolver < Base
    attr_reader :dependencies

    def initialize(identifier)
      @dependencies = {}
      @graph = Solve::Graph.new
      @identifier = identifier
    end

    # Resolves the constraints for a version
    Contract ArrayOf[Dependency] => Solve::Graph
    def resolve(dependencies)
      dependencies.each do |dependency|
        resolve_dependency dependency
      end

      @graph
    end

    def resolve_dependency(dependency)
      return if @graph.artifacts_by_name.key?(dependency.name)

      @dependencies[dependency.name] ||= dependency

      dependency
        .source
        .versions
        .each do |version|
          resolve_dependencies(dependency, version)
        end
    end

    def resolve_dependencies(main, version)
      dependencies = @identifier.identify(main.source.fetch(version))
      artifact = @graph.artifact main.name, version

      dependencies.each do |dependency|
        dependency.constraints.each do |constraint|
          artifact.depends dependency.name, constraint
        end

        resolve_dependency dependency
      end
    end
  end

  class Installer < Base
    def initialize
      @identifier = Identifier.new []
      @resolver = Resolver.new @identifier

      @initial_dependencies = @identifier.identify Dir.new(Dir.pwd)

      @graph = @resolver.resolve @initial_dependencies

      initial = @initial_dependencies.map do |dependency|
        dependency.constraints.map do |constraint|
          [dependency.name, constraint]
        end
      end
      .flatten(1)

      results =
        Solve
          .it!(@graph, initial)
          .map { |name, version|
            dep = @resolver.dependencies[name]
            dep.version = Semverse::Version.new(version)
            dep
          }

      (Populator.new results).populate
    end
  end

  # Populator for 'elm-stuff' directory
  class Populator < Base
    # Initializes a new populator
    Contract ArrayOf[Dependency] => Populator
    def initialize(dependencies)
      @dependencies = dependencies
      self
    end

    # Populates 'elm-stuff'
    Contract None => Int
    def populate
      copy_dependencies
      write_exact_dependencies
    end

    # Writes the 'elm-stuff/exact-dependencies.json'
    Contract None => Int
    def write_exact_dependencies
      File.binwrite(
        File.join('elm-stuff', 'exact-dependencies.json'),
        JSON.pretty_generate(exact_dependencies)
      )
    end

    # Returns the contents for 'elm-stuff/exact-dependencies.json'
    Contract None => HashOf[String => String]
    def exact_dependencies
      @dependencies.each_with_object({}) do |dependency, memo|
        memo[dependency.name] = dependency.version.to_simple
      end
    end

    # Copies dependencies to `elm-stuff/packages/package/version` directory
    Contract None => Any
    def copy_dependencies
      @dependencies.each do |dependency|
        path =
          File.join(
            'elm-stuff',
            'packages',
            dependency.name,
            dependency.version.to_simple
          )

        FileUtils.mkdir_p path

        dependency.source.copy_to(dependency.version, Dir.new(path))
      end
    end
  end
end
