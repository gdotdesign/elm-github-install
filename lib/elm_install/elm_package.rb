module ElmInstall
  # This is a class for reading the `elm-package`.json file and
  # transform it's `dependecies` field to a unified format.
  module ElmPackage
    def self.dependencies(path)
      json = read path
      transform_dependencies(
        json['dependencies'].to_h,
        json['dependency-sources'].to_h
      )
    end

    # :reek:DuplicateMethodCall
    def self.read(path)
      JSON.parse(File.read(path))
    rescue JSON::ParserError
      Logger.arrow "Invalid JSON in file: #{path.bold}."
      Process.exit
    rescue Errno::ENOENT
      Logger.arrow "Could not find file: #{path.bold}."
      Process.exit
    end

    def self.transform_dependencies(raw_dependencies, sources)
      raw_dependencies.each_with_object({}) do |(package, constraint), memo|
        value = sources.fetch(package, package)

        transform_dependency package, value, constraint, memo
      end
    end

    # :reek:LongParameterList
    # :reek:DuplicateMethodCall
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

    # :reek:DuplicateMethodCall
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

    def self.transform_package(key)
      GitCloneUrl.parse(key).to_s
    rescue
      "git@github.com:#{key}"
    end
  end
end
