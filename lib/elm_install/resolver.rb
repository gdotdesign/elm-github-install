module ElmInstall
  # Resolves dependencies
  class Resolver < Base
    attr_reader :dependencies

    def initialize(identifier)
      @dependencies = {}
      @graph = Solve::Graph.new
      @identifier = identifier
    end

    # Resolves the constraints for a version
    Contract None => Solve::Graph
    def resolve
      @identifier.initial_dependencies.each do |dependency|
        resolve_dependency dependency
      end

      @graph
    end

    def resolve_dependency(dependency)
      return if @dependencies[dependency.name]

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
end
