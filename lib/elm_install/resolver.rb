module ElmInstall
  # Resolves dependencies
  class Resolver < Base
    # @return [Array<Dependency>] The dependencies
    attr_reader :dependencies

    Contract Identifier, Hash => Resolver
    # Initializes a resolver
    #
    # @param identifier [Identifier] The identifier
    # @param options [Hash] The options
    #
    # @return [Resolver]
    def initialize(identifier, options = {})
      @graph = Solve::Graph.new
      @identifier = identifier
      @dependencies = {}
      @options = options
      self
    end

    Contract None => Solve::Graph
    # Resolves the constraints for a version
    #
    # @return [Solve::Graph] Returns the graph
    def resolve
      @identifier.initial_dependencies.each do |dependency|
        resolve_dependency dependency
      end

      @graph
    end

    Contract Dependency => NilClass
    # Resolves the dependencies of a dependency
    #
    # @param dependency [Dependency] The dependency
    #
    # @return nil
    def resolve_dependency(dependency)
      @dependencies[dependency.name] ||= dependency

      dependency
        .source
        .versions(
          dependency.constraints,
          @identifier.initial_elm_version,
          !@options[:skip_update],
          @options[:only_update]
        )
        .each do |version|
          next if @graph.artifact?(dependency.name, version)
          resolve_dependencies(dependency, version)
        end

      nil
    end

    Contract Dependency, Semverse::Version => NilClass
    # Resolves the dependencies of a dependency and version
    #
    # @param main [Dependency] The dependency
    # @param version [Semverse::Version] The version
    #
    # @return nil
    def resolve_dependencies(main, version)
      dependencies = @identifier.identify(main.source.fetch(version))
      artifact = @graph.artifact main.name, version

      dependencies.each do |dependency|
        dependency.constraints.each do |constraint|
          artifact.depends dependency.name, constraint
        end

        resolve_dependency dependency
      end

      nil
    end
  end
end
