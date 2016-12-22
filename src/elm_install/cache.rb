module ElmInstall
  class Cache
    def initialize
      load
    end

    def save
      File.binwrite(file, @cache.to_json)
    end

    def load
      @cache = JSON.parse(File.read(file))
    rescue
      @cache = {}
    end

    def directory
      File.join(Dir.home, '.elm-github-install')
    end

    def file
      File.join(directory, 'cache.json')
    end

    def package?(package)
      @cache.key?(package)
    end

    def dependency?(package, version, constraint)
      @cache[package] &&
        @cache[package][version] &&
        @cache[package][version].include?(constraint)
    end

    def dependency(package, version, constraint)
      @cache[package] ||= {}
      @cache[package][version] ||= []
      @cache[package][version] << constraint
    end

    def ensure_version(package, version)
      @cache[package] ||= {}
      @cache[package][version] ||= []
    end

    def to_graph
      graph = Solve::Graph.new

      @cache.each do |package, versions|
        versions.each do |version, deps|
          begin
            artifact = graph.artifact(package, version)

            deps.each do |dep|
              begin
                artifact.depends(*dep)
              rescue
              end
            end
          rescue
          end
        end
      end
      graph
    end
  end
end
