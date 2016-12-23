module ElmInstall
  # This class is for building dependency graphs from a cache.
  class GraphBuilder
    attr_reader :graph

    # Returns a graph from a cache.
    def self.graph_from_cache(cache, options = { verbose: false })
      graph = new cache, options
      graph.build
      graph.graph
    end

    # Initialies a graph build with a cache
    def initialize(cache, options = { verbose: false })
      @graph = Solve::Graph.new
      @options = options
      @cache = cache
    end

    # Builds the graph.
    def build
      @cache.each do |package, versions|
        add_versions package, versions
      end
    end

    private

    # Adds the given package & version combinations to the graph.
    def add_versions(package, versions)
      versions.each do |version, dependencies|
        add_version package, version, dependencies
      end
    end

    # Adds the given package, version and dependency
    # combinations to the graph.
    def add_version(package, version, dependencies)
      artifact = @graph.artifact(package, version)

      dependencies.each do |dependency|
        add_dependency artifact, *dependency
      end
    rescue
      if @options[:verbose]
        puts "WARNING: Could not add version #{version} to #{package}."
      end
    end

    # Adds the given package version and single dependency to the
    # graph.
    def add_dependency(artifact, package, version)
      artifact.depends package, version
    rescue
      if @options[:verbose]
        puts "
          WARNING: Could not add dependency #{package}-#{version} to #{artifact}
        ".strip
      end
    end
  end
end
