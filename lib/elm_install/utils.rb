module ElmInstall
  # This module contains utility functions.
  module Utils
    include Contracts::Core
    include Contracts::Builtin

    module_function

    # Regexes for converting constraints.
    CONVERTERS = {
      /v<(?!=)(.*)/ => '<',
      /(.*)<=v/ => '>=',
      /v<=(.*)/ => '<=',
      /(.*)<v/ => '>'
    }.freeze

    Contract String => [Solve::Constraint]
    def transform_constraint(elm_constraint)
      elm_constraint.gsub!(/\s/, '')

      CONVERTERS
        .map { |regexp, prefix| [elm_constraint.match(regexp), prefix] }
        .select { |(match)| match }
        .map { |(match, prefix)| "#{prefix} #{match[1]}" }
        .map { |constraint| Solve::Constraint.new constraint }
    end
  end
end
