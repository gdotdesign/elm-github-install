module ElmInstall
  # This class is responsible for populating the `elm-stuff` directory.
  class Populator
    # Initializes a new populator.
    #
    # @param git_resolver [GitResolver] The git resolver to use.
    def initialize(git_resolver, sources)
      @git_resolver = git_resolver
      @sources = sources
    end

    # Populates `elm-stuff` from the given solution.
    #
    # @param solution [Hash] The solution.
    #
    # @return [void]
    def populate(solution)
      solution.each do |package, version|
        resolve_package package, version
      end

      write_exact_dependencies(solution)
    end

    # Resolves and copies a package and it's version to `elm-stuff/packages`
    # directory.
    #
    # :reek:TooManyStatements { max_statements: 9 }
    #
    # @param package [String] The package
    # @param version_str [String] The resolved version
    #
    # @return [void]
    def resolve_package(package, version_str)
      version, ref = self.class.version_and_ref(version_str)

      package_path = File.join('elm-stuff', 'packages', package, version)

      source_url = @sources.resolve(package)

      message = ''
      message += ref.bold if version_str =~ /\+/
      message += '@' + source_url.bold unless source_url.start_with?('https://github.com/elm-lang')

      final_message = message.empty? ? '' : "(#{message})"

      @git_resolver.repository(source_url).checkout(ref)

      Logger.dot "#{package.bold} - #{version.bold} #{final_message}"

      FileUtils.rm_rf(package_path) if Dir.exist?(package_path)

      copy_package package, package_path
    end

    # Copies the given package from it's repository to the given path.
    #
    # @param package [String] The package to copy
    # @param package_path [String] The destination
    #
    # @return [void]
    def copy_package(package, package_path)
      repository_path = File.join(@git_resolver.repository_path(@sources.resolve(package)), '.')

      FileUtils.mkdir_p(package_path)
      FileUtils.cp_r(repository_path, package_path)
      FileUtils.rm_rf(File.join(package_path, '.git'))
    end

    # Writes the `elm-stuff/exact-dependencies.json` file.
    #
    # @param solution [Hash] The solution
    #
    # @return [void]
    def write_exact_dependencies(solution)
      File.binwrite(
        File.join('elm-stuff', 'exact-dependencies.json'),
        JSON.pretty_generate(self.class.exact_dependencies(solution))
      )
    end

    # Returns the exact dependencies from the solution.
    #
    # @param solution [Hash] The solution
    #
    # @return [void]
    def self.exact_dependencies(solution)
      solution.each_with_object({}) do |(key, value), memo|
        version, = version_and_ref value

        memo[key] = version
      end
    end

    # Retruns the version and the ref from the given string.
    #
    # @param value [String] The input
    #
    # @return [Array] The version and the ref as an array
    def self.version_and_ref(value)
      match = value.match(/(.+)\+(.+)/)

      version = match ? match[1] : value
      ref = match ? match[2] : value

      [version, ref]
    end
  end
end
