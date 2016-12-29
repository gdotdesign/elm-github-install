module ElmInstall
  # This is a class for reading the `elm-package`.json file and
  # transform it's `dependecies` field to a unified format.
  module ElmPackage
    # Returns the dependencies for the given `elm-package`.
    #
    # @param path [String] The path for the file
    #
    # @return [Hash] The hash of dependenceis (url => version or ref)
    def self.dependencies(path)
      json = read path
      transform_dependencies(
        json['dependencies'].to_h,
        json['dependency-sources'].to_h
      )
    end

    # Reads the given file as JSON.
    #
    # :reek:DuplicateMethodCall
    #
    # @param path [String] The path
    #
    # @return [Hash] The json
    def self.read(path)
      JSON.parse(File.read(path))
    rescue JSON::ParserError
      Logger.arrow "Invalid JSON in file: #{path.bold}."
      Process.exit
    rescue Errno::ENOENT
      Logger.arrow "Could not find file: #{path.bold}."
      Process.exit
    end

    # Transform dependencies from (package name => version) to
    # (url => version or ref) format using the `depdendency-sources` field.
    #
    # @param raw_dependencies [Hash] The raw dependencies
    # @param sources [Hash] The sources for the dependencies
    #
    # @return [Hash] The dependencies
    def self.transform_dependencies(raw_dependencies, sources)
      raw_dependencies.each_with_object({}) do |(package, constraint), memo|
        value = sources.fetch(package, package)

        transform_dependency package, value, constraint, memo
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
    def self.transform_dependency(package, value, constraint, memo)
      if value.is_a?(Hash)
        check_path package, value['url']
        memo[value['url']] = value['ref']
      else
        url = transform_package(value)
        check_path package, url
        memo[url] = constraint
      end
    end

    # Checks if the given url matches the given package.
    #
    # :reek:DuplicateMethodCall
    #
    # @param package [String] The package
    # @param url [String] The url
    #
    # @return [void]
    def self.check_path(package, url)
      uri = GitCloneUrl.parse(url)
      path = uri.path.sub(%r{^/}, '')

      return if path == package

      puts "
  The source of package #{package.bold} is set to #{url.bold} which would
  be install to #{"elm-stuff/#{path}".bold}. This would cause a conflict
  when trying to compile anything.

  The name of a package must match the source url's path.

  #{package.bold} <=> #{path.bold}
      "
      Process.exit
    end

    # Transforms a package to it's url for if needed.
    #
    # @param key [String] The package
    #
    # @return [String] The url
    def self.transform_package(key)
      GitCloneUrl.parse(key).to_s
    rescue
      "https://github.com/#{key}"
    end
  end
end
