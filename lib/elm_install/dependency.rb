module ElmInstall
  # Represents a dependency
  class Dependency < Base
    extend Forwardable

    # @!attribute [r] constraints
    #   The constraints for the dependency
    attr_reader :constraints

    # @!attribute [rw] version
    #   The resolved version for the dependency
    attr_accessor :version

    # @!attribute [r] source
    #   The source to use when resolving the dependency (Git, Directory)
    attr_reader :source

    # @!attribute [r] name
    #   The name of the dependency
    attr_reader :name

    Contract String, Source, ArrayOf[Solve::Constraint] => Dependency
    # Initializes a new dependency
    #
    # @param name [String] The name
    # @param source [Source] The source
    # @param constraints [Array] The contraints
    #
    # @return [Dependency] The dependency instance
    def initialize(name, source, constraints)
      @constraints = constraints
      @source = source
      @name = name
      self
    end
  end
end
