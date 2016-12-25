module ElmInstall
  module ElmPackage
    module_function

    # TODO: Error handling
    def dependencies(path)
      json = JSON.parse(File.read(path))
      transform_dependencies(
        json['dependencies'],
        json['dependency-sources'].to_h
      )
    end

    def transform_dependencies(raw_dependencies, sources)
      raw_dependencies.each_with_object({}) do |(package, constraint), memo|
        value = sources.fetch(package, constraint)
        if value.is_a?(Hash)
          memo[value['url']] = "ref:#{value['ref']}"
        else
          memo[package] = value
        end
      end
    end
  end
end
