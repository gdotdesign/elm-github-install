module ElmInstall
  # Installer class
  class Installer < Base
    def initialize(options = {})
      @identifier = Identifier.new Dir.new(Dir.pwd), options
      @resolver = Resolver.new @identifier
    end

    def install
      puts 'Resolving packages...'
      @graph = @resolver.resolve

      puts 'Solving dependencies...'
      (Populator.new results).populate

      puts 'Packages configured successfully!'
    end

    def results
      Solve
        .it!(@graph, initial_solve_constraints)
        .map do |name, version|
          dep = @resolver.dependencies[name]
          dep.version = Semverse::Version.new(version)
          dep
        end
    end

    def initial_solve_constraints
      @identifier.initial_dependencies.flat_map do |dependency|
        dependency.constraints.map do |constraint|
          [dependency.name, constraint]
        end
      end
    end
  end
end
