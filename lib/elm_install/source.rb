module ElmInstall
  # Abstract class for a source
  class Source < Base
    attr_accessor :identifier, :options
  end
end
