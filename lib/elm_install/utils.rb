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
    def transform_constraint(constraint)
      constraint.gsub!(/\s/, '')

      CONVERTERS
        .map do |regexp, prefix|
          match = constraint.match(regexp)
          "#{prefix} #{match[1]}" if match
        end
        .compact
        .map { |constraint| Solve::Constraint.new constraint }
    end
  end
end
