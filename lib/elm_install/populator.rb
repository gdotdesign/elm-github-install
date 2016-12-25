module ElmInstall
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
    def resolve_package(package, version)
      package_name, package_path = Utils.package_version_path package, version

      @git_resolver.repository(package).checkout(version)

      Logger.dot "#{package_name.bold} - #{version.bold}"

      return if Dir.exist?(package_path)

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
      	JSON.pretty_generate(exact_dependencies(solution))
    	)
    end

    # Returns the exact dependencies from the solution.
    def exact_dependencies(solution)
      solution.each_with_object({}) do |(key, value), memo|
        memo[GitCloneUrl.parse(key).path] = value
      end
    end
	end
end
