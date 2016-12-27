module ElmInstall
  # This is a class for reading the `elm-package`.json file and
  # transform it's `dependecies` field to a unified format.
  module ElmPackage
    # TODO: Error handling
    def self.dependencies(path)
      json = read path
      transform_dependencies(
        json['dependencies'],
        json['dependency-sources'].to_h
      )
    end

    def self.read(path)
      JSON.parse(File.read(path))
    end

    def self.transform_dependencies(raw_dependencies, sources)
      raw_dependencies.each_with_object({}) do |(package, constraint), memo|
        value = sources.fetch(package, package)

        if value.is_a?(Hash)
          memo[value['url']] = value['ref']
          check_path package, value['url']
        else
          url = transform_package(value)
          check_path package, url
          memo[url] = constraint
        end
      end
    end

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
