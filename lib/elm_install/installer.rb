module ElmInstall
  class Installer < Base
    def initialize(options = {})
      @identifier = Identifier.new Dir.new(Dir.pwd), options
      @resolver = Resolver.new @identifier

      puts "Resolving packages..."

      @graph = @resolver.resolve

      initial = @identifier.initial_dependencies.map do |dependency|
        dependency.constraints.map do |constraint|
          [dependency.name, constraint]
        end
      end
      .flatten(1)

      puts "Solving dependencies..."

      results =
        Solve
          .it!(@graph, initial)
          .map { |name, version|
            dep = @resolver.dependencies[name]
            dep.version = Semverse::Version.new(version)
            dep
          }

      (Populator.new results).populate

      puts "Packages configured successfully!"
    end
  end
end
