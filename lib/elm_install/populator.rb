module ElmInstall
  # Populator for 'elm-stuff' directory
  class Populator < Base
    Contract ArrayOf[Dependency] => Populator
    # Initializes a new populator
    #
    # @param dependencies [Array] The dependencies to populate
    #
    # @return Populator The populator instance
    def initialize(dependencies)
      @dependencies = dependencies
      self
    end

    Contract None => NilClass
    # Populates 'elm-stuff' directory and writes
    # 'elm-stuff/exact-dependencies.json'.
    #
    # @return nil
    def populate
      copy_dependencies
      write_exact_dependencies
    end

    Contract None => NilClass
    # Writes the 'elm-stuff/exact-dependencies.json'
    #
    # @return nil
    def write_exact_dependencies
      File.binwrite(
        File.join('elm-stuff', 'exact-dependencies.json'),
        JSON.pretty_generate(exact_dependencies)
      )
      nil
    end

    Contract None => HashOf[String => String]
    # Returns the contents for 'elm-stuff/exact-dependencies.json'
    #
    # @return [Hash] The dependencies
    def exact_dependencies
      @dependencies.each_with_object({}) do |dependency, memo|
        memo[dependency.name] = dependency.version.to_simple
      end
    end

    Contract None => NilClass
    # Copies dependencies to 'elm-stuff/packages/package/version' directory
    #
    # @return nil
    def copy_dependencies
      @dependencies.each do |dependency|
        path =
          File.join('elm-stuff', 'packages', dependency.name,
                    dependency.version.to_simple)

        log_dependency dependency

        dependency.source.copy_to(dependency.version, Pathname.new(path))
      end
      nil
    end

    Contract Dependency => NilClass
    # Logs the dependency with a dot
    #
    # @param dependency [Dependency] The dependency
    #
    # @return nil
    def log_dependency(dependency)
      log = "#{dependency.name} - "
      log += dependency.source.to_log.to_s
      log += " (#{dependency.version.to_simple})"

      Logger.dot log
      nil
    end
  end
end
