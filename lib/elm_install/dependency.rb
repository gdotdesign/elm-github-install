module ElmInstall
  # Dependency
  class Dependency < Base
    extend Forwardable

    attr_reader :constraints
    attr_accessor :version
    attr_reader :source
    attr_reader :name

    # Initializes a new dependency
    Contract String, Source, ArrayOf[Solve::Constraint] => Dependency
    def initialize(name, source, constraints)
      @constraints = constraints
      @source = source
      @name = name
      self
    end

    # Clones the dependecy with different constraints
    Contract [Solve::Constraint] => Dependency
    def with_different_constraints(constraints)
      self.class.new name, source, constraints
    end
  end
end
