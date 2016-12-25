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
    extend Forwardable

    # Initializes a new installer with the given options.
    def initialize(options = { verbose: false })
      options[:cache_directory] ||= File.join(Dir.home, '.elm-install')
      @git_resolver = GitResolver.new directory: options[:cache_directory]
      @cache = Cache.new directory: options[:cache_directory]
      @populator = Populator.new @git_resolver
      @options = options
    end

    # Executes the installation
    #
    # :reek:TooManyStatements { max_statements: 7 }
    def install
      puts 'Resolving packages...'
      resolver.add_constraints dependencies

      puts 'Solving dependencies...'
      populate_elm_stuff
      begin

        @git_resolver.save
        @cache.save
      rescue
        puts ' ▶ Could not find a solution in local cache, refreshing packages...'

        @git_resolver.clear
        resolver.add_constraints dependencies

        begin
          populate_elm_stuff
          @git_resolver.save
          @cache.save
        rescue Solve::Errors::NoSolutionError => e
          puts 'Could not find a solution:'
          puts indent(e.to_s)
        end
      end
    end

    private

    def indent(str)
      str.split("\n").map { |s| "  #{s}" }.join("\n")
    end

    def end_sucessfully
      puts 'Saving package cache...'
      @cache.save

      puts 'Packages configured successfully!'
    end

    # Populates the `elm-stuff` directory with the packages from
    # the solution.
    def populate_elm_stuff
      @populator.populate calculate_solution
      end_sucessfully
    end

    # Returns the resolver to calculate the solution.
    def resolver
      @resolver ||= Resolver.new @cache, @git_resolver
    end

    # Returns the solution for the given `elm-package.json` file.
    def calculate_solution
      Solve.it!(
        GraphBuilder.graph_from_cache(@cache, @options),
        resolver.constraints
      )
    end

    def dependencies
      @dependencies ||= ElmPackage.dependencies 'elm-package.json'
    end
  end
end
