module ElmInstall
  # This module contains utility functions.
  module Utils
    module_function

    # Regexes for converting constraints.
    CONVERTERS = {
      /v<(?!=)(.*)/ => '<',
      /(.*)<=v/ => '>=',
      /v<=(.*)/ => '<=',
      /(.*)<v/ => '>'
    }.freeze

    # Transform constraints form Elm's package format to semver's.
    #
    # @param constraint [String] The input constraint
    #
    # @return [Array] The output constraints
    def transform_constraint(constraint)
      constraint.gsub!(/\s/, '')

      CONVERTERS.map do |regexp, prefix|
        match = constraint.match(regexp)
        "#{prefix} #{match[1]}" if match
      end.compact
    end

    # Returns the path for a package with the given version.
    #
    # @param package [String] The package
    # @param version [String] The version
    #
    # @return [Strin] The path
    def package_version_path(package, version)
      package_name = GitCloneUrl.parse(package).path.sub(%r{^/}, '')
      [package_name, File.join('elm-stuff', 'packages', package_name, version)]
    end
  end
end
