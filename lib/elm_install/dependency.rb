module ElmInstall
  # Represents a dependency
  class Dependency < Base
    extend Forwardable

    # @return [Array] The constraints for the dependency
    attr_reader :constraints

    # @overload version
    #   @return [Semverse::Version] The version
    # @overload version=(value)
    #   Sets the version
    #   @param [Semverse::Version] The version
    attr_accessor :version

    # @return [Source] The source to use for resolving (Git, Directory)
    attr_reader :source

    # @return [String] The name of the dependency
    attr_reader :name

    Contract String, Source, ArrayOf[Solve::Constraint] => Dependency
    # Initializes a new dependency.
    #
    # @param constraints [Array<Solve::Constraint>] The contraints
    # @param source [Source] The source
    # @param name [String] The name
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
