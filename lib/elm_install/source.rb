module ElmInstall
  # Abstract class for a source
  class Source < Base
    # @overload identifier
    #   @return [Identifier] The identifier
    # @overload identifier=(value)
    #   Sets the identifier
    #   @param [Identifier] The identifier
    attr_accessor :identifier

    # @overload options
    #   @return [Hash] The options
    # @overload options=(value)
    #   Sets the options
    #   @param [Hash] The options
    attr_accessor :options
  end
end
