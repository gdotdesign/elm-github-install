module ElmInstall
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

    # Copies dependencies to 'elm-stuff/packages/package/version' directory
    Contract None => Any
    def copy_dependencies
      @dependencies.each do |dependency|
        path =
          File.join('elm-stuff', 'packages', dependency.name,
                    dependency.version.to_simple)

        log_dependency dependency

        dependency.source.copy_to(dependency.version, Pathname.new(path))
      end
    end

    def log_dependency(dependency)
      log = "#{dependency.name} - "
      log += dependency.source.to_log.to_s
      log += " (#{dependency.version.to_simple})"

      Logger.dot log
    end
  end
end
