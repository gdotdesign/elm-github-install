module ElmInstall
  # This class is responsible for populating the `elm-stuff` directory.
  class Populator
    def initialize(git_resolver)
      @git_resolver = git_resolver
    end

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
    def resolve_package(package, version_str)
      version, ref = self.class.version_and_ref(version_str)

      package_name, package_path = Utils.package_version_path package, version

      @git_resolver.repository(package).checkout(ref)

      Logger.dot "#{package_name.bold} - #{version.bold} (#{ref})"

      FileUtils.rm_rf(package_path) if Dir.exist?(package_path)

      copy_package package, package_path
    end

    # Copies the given package from it's repository to the given path.
    def copy_package(package, package_path)
      repository_path = File.join(@git_resolver.repository_path(package), '.')

      FileUtils.mkdir_p(package_path)
      FileUtils.cp_r(repository_path, package_path)
      FileUtils.rm_rf(File.join(package_path, '.git'))
    end

    # Writes the `elm-stuff/exact-dependencies.json` file.
    def write_exact_dependencies(solution)
      File.binwrite(
        File.join('elm-stuff', 'exact-dependencies.json'),
        JSON.pretty_generate(self.class.exact_dependencies(solution))
      )
    end

    # Returns the exact dependencies from the solution.
    def self.exact_dependencies(solution)
      solution.each_with_object({}) do |(key, value), memo|
        version, = version_and_ref value

        memo[GitCloneUrl.parse(key).path.sub(%r{^/}, '')] = version
      end
    end

    def self.version_and_ref(value)
      match = value.match(/(.+)\+(.+)/)

      version = match ? match[1] : value
      ref = match ? match[2] : value

      [version, ref]
    end
  end
end
