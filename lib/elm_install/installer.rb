module ElmInstall
  # Installer class
  class Installer < Base
    Contract KeywordArgs[cache_directory: Or[String, NilClass],
                         verbose: Or[Bool, NilClass]] => Installer
    # Initializes an installer with the given options
    #
    # @param options [Hash] The options
    #
    # @return [Installer] The installer instance
    def initialize(options = {})
      @identifier = Identifier.new Dir.new(Dir.pwd), options
      @resolver = Resolver.new @identifier
      self
    end

    Contract None => NilClass
    # Installs packages
    #
    # @return nil
    def install
      puts 'Resolving packages...'
      @graph = @resolver.resolve

      puts 'Solving dependencies...'
      (Populator.new results).populate

      puts 'Packages configured successfully!'
      nil
    rescue Solve::Errors::NoSolutionError => error
      Logger.arrow "No solution found: #{error}"
      Process.abort
    end

    Contract None => ArrayOf[Dependency]
    # Returns the results of solving
    #
    # @return [Array] Array of dependencies
    def results
      Solve
        .it!(@graph, initial_solve_constraints)
        .map do |name, version|
          dep = @resolver.dependencies[name]
          dep.version = Semverse::Version.new(version)
          dep
        end
    end

    Contract None => Array
    # Returns the inital constraints
    #
    # @return [Array] Array of dependency names and constraints
    def initial_solve_constraints
      @identifier.initial_dependencies.flat_map do |dependency|
        dependency.constraints.map do |constraint|
          [dependency.name, constraint]
        end
      end
    end
  end
end
