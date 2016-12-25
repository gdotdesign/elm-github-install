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
        else
          memo[transform_package(value)] = constraint
        end
      end
    end

    def self.transform_package(key)
      GitCloneUrl.parse(key).to_s
    rescue
      "git@github.com:#{key}"
    end
  end
end
