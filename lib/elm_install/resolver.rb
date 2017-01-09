require_relative './cache'
require_relative './utils'

module ElmInstall
  # Resolves git dependencies into the cache.
  class Resolver
    # @return [Array] The constraints
    attr_reader :constraints

    # Initializes a resolver with a chace and git resolver.
    #
    # @param cache [Cache] The cache
    # @param git_resolver [GitResolver] The git resolver
    def initialize(cache, git_resolver)
      @git_resolver = git_resolver
      @constraints = []
      @cache = cache
    end

    # Add constraints, usually from the `elm-package.json`.
    #
    # @param constraints [Hash] The constraints
    #
    # @return [void]
    def add_constraints(constraints)
      @constraints = add_dependencies(constraints) do |package, constraint|
        [package, constraint]
      end
    end

    # Adds dependencies, usually from any `elm-package.json` file.
    #
    # :reek:NestedIterators { max_allowed_nesting: 2 }
    #
    # @param dependencies [Hash] The dependencies
    #
    # @yieldreturn [Array] A constraint
    # @return [void]
    def add_dependencies(dependencies)
      dependencies.flat_map do |package, constraint|
        add_package(package)

        constraints = Utils.transform_constraint(constraint)
        next add_ref_dependency(package, constraint) if constraints.empty?

        constraints.map do |dependency|
          yield package, dependency
        end
      end
    end

    # Adds a dependency by git reference.
    #
    # @param package [String] The package
    # @param ref [String] The reference
    #
    # @return [void]
    def add_ref_dependency(package, ref)
      @git_resolver.repository(package).checkout(ref)
      pkg_version = elm_package(package)['version']
      version = "#{pkg_version}+#{ref}"
      @cache.ensure_version(package, version)
      add_package_dependencies(package, version)
      [[package, "= #{version}"]]
    end

    # Adds a package to the cache, the following things happens:
    # * If there is no local repository it will be cloned
    # * Getting all the tags and adding the valid ones to the cache
    # * Checking out and getting the `elm-package.json` for each version
    #   and adding them recursivly
    #
    # @param package [String] The package
    #
    # @return [void]
    def add_package(package)
      return if @git_resolver.package?(package) && @cache.key?(package)

      @git_resolver
        .repository(package)
        .tags
        .map(&:name)
        .each do |version|
          @cache.ensure_version(package, version)
          add_version(package, version)
        end
    end

    # Adds a package's dependencies to the cache.
    #
    # @param package [String] The package
    # @param version [String] The version
    #
    # @return [void]
    def add_package_dependencies(package, version)
      add_dependencies(elm_dependencies(package)) do |dep_package, constraint|
        add_package(dep_package)
        @cache.dependency(package, version, [dep_package, constraint])
      end
    end

    # Adds a version and it's dependencies to the cache.
    #
    # @param package [String] The package
    # @param version [String] The version
    #
    # @return [void]
    def add_version(package, version)
      @git_resolver
        .repository(package)
        .checkout(version)

      add_package_dependencies(package, version)
    end

    # Gets the `elm-package.json` for a package.
    #
    # @param package [String] The package
    #
    # @return [Hash] The dependencies
    def elm_dependencies(package)
      ElmPackage.dependencies elm_package_path(package)
    rescue
      {}
    end

    # Retruns the contents of the `elm-pacakge.json` of the given package.
    #
    # @param package [String] The package
    #
    # @return [Hash] The contents
    def elm_package(package)
      ElmPackage.read elm_package_path(package)
    end

    # Retruns the path of the `elm-pacakge.json` of the given package.
    #
    # @param package [String] The package
    #
    # @return [String] The path
    def elm_package_path(package)
      File.join(@git_resolver.repository_path(package), 'elm-package.json')
    end
  end
end
