module ElmInstall
  # This is a class for reading the `elm-package`.json file and
  # transform it's `dependecies` field to a unified format.
  module ElmPackage
    # Returns the dependencies for the given `elm-package`.
    #
    # @param path [String] The path for the file
    #
    # @return [Hash] The hash of dependenceis (url => version or ref)
    def self.dependencies(path, sources, options = { silent: true })
      json = read path, options
      transform_dependencies(
        json['dependencies'].to_h,
        json['dependency-sources'].to_h,
        sources
      )
    end

    # Reads the given file as JSON.
    #
    # :reek:DuplicateMethodCall
    #
    # @param path [String] The path
    #
    # @return [Hash] The json
    def self.read(path, options = { silent: true })
      JSON.parse(File.read(path))
    rescue JSON::ParserError
      exit "Invalid JSON in file: #{path.bold}.", options
    rescue Errno::ENOENT
      exit "Could not find file: #{path.bold}.", options
    end

    # Exits the current process with the given message.
    #
    # @param message [String] The message
    # @param options [Hash] The options
    #
    # @return [void]
    def self.exit(message, options)
      return {} if options[:silent]
      Logger.arrow message
      Process.exit
    end

    # Transform dependencies from (package name => version) to
    # (url => version or ref) format using the `depdendency-sources` field.
    #
    # @param raw_dependencies [Hash] The raw dependencies
    # @param sources [Hash] The sources for the dependencies
    #
    # @return [Hash] The dependencies
    def self.transform_dependencies(raw_dependencies, dep_sources, sources)
      raw_dependencies.each_with_object({}) do |(package, constraint), memo|
        value = dep_sources.fetch(package, nil)

        transform_dependency package, value, constraint, memo, sources
      end
    end

    # Transforms a dependecy.
    #
    # :reek:LongParameterList
    # :reek:DuplicateMethodCall
    #
    # @param package [String] The package
    # @param value [String] The version
    # @param constraint [String] The constarint
    # @param memo [Hash] The hash to save the dependency to
    #
    # @return [Hash] The memo object
    def self.transform_dependency(package, value, constraint, memo, sources)
      if value.is_a?(Hash)
        sources[package] = value
        memo[package] = value['ref']
      elsif value.is_a?(String)
        sources[package] = transform_package(value)
        memo[package] = constraint
      else
        memo[package] = constraint
      end
    end

    # Transforms a package to it's url for if needed.
    #
    # @param key [String] The package
    #
    # @return [String] The url
    def self.transform_package(key)
      GitCloneUrl.parse(key).to_s.gsub(/\.git$/, '')
    rescue
      "https://github.com/#{key}"
    end
  end
end
