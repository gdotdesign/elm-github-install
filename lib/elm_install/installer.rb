require_relative './resolver'
require_relative './elm_package'
require_relative './git_resolver'
require_relative './graph_builder'
require_relative './populator'

module ElmInstall
  # This class is responsible getting a solution for the `elm-package.json`
  # file and populating the `elm-stuff` directory with the packages and
  # writing the `elm-stuff/exact-dependencies.json`.
  class Installer
    # Initializes a new installer with the given options.
    #
    # @param options [Hash] The options
    def initialize(options)
      init_options options
      @git_resolver = GitResolver.new directory: cache_directory
      @cache = Cache.new directory: cache_directory
      @populator = Populator.new @git_resolver
      @options = options
    end

    # Initializes the options setting default values.
    #
    # @param options [Hash] The options
    #
    # @return [Hash] The options
    def init_options(options = { verbose: false })
      options[:cache_directory] ||= File.join(Dir.home, '.elm-install')
      @options = options
    end

    # Returns the path to the cache directory
    #
    # @return [String] The path
    def cache_directory
      @options[:cache_directory]
    end

    # Executes the installation
    #
    # :reek:TooManyStatements { max_statements: 7 }
    #
    # @return [void]
    def install
      puts 'Resolving packages...'
      resolver.add_constraints dependencies

      puts 'Solving dependencies...'
      populate_elm_stuff
    rescue
      retry_install
    end

    # Saves the caches
    #
    # @return [void]
    def save
      puts 'Saving package cache...'
      @git_resolver.save
      @cache.save
    end

    # Clears the reference cache and retries installation.
    #
    # @return [void]
    def retry_install
      Logger.arrow(
        'Could not find a solution in local cache, refreshing packages...'
      )

      @git_resolver.clear
      resolver.add_constraints dependencies

      populate_elm_stuff
    rescue Solve::Errors::NoSolutionError => error
      puts 'Could not find a solution:'
      puts error.to_s.indent(2)
    end

    private

    # Populates the `elm-stuff` directory with the packages from
    # the solution.
    #
    # @return [void]
    def populate_elm_stuff
      save
      @populator.populate calculate_solution
      puts 'Packages configured successfully!'
    end

    # Returns the resolver to calculate the solution.
    #
    # @return [Resolver] The resolver
    def resolver
      @resolver ||= Resolver.new @cache, @git_resolver
    end

    # Returns the solution for the given `elm-package.json` file.
    #
    # @return [Hash] The solution
    def calculate_solution
      Solve.it!(
        GraphBuilder.graph_from_cache(@cache, @options),
        resolver.constraints
      )
    end

    # Returns the dependencies form `elm-package.json`.
    #
    # @return [Hash] The dependencies
    def dependencies
      @dependencies ||= ElmPackage.dependencies 'elm-package.json',
                                                silent: false
    end
  end
end
