module ElmInstall
  # This class is the base for the Cache and GitResolver packages.
  class Base
    extend Forwardable

    attr_reader :cache

    def_delegators :@cache, :each, :key?

    # Initializes a new base for a cache.
    #
    # @param options [Hash] The options
    def initialize(options = {})
      @options = options
      @cache = {}
      load
    end

    # Saves the cache into the json file.
    #
    # @return [void]
    def save
      File.binwrite(file, JSON.pretty_generate(@cache))
    end

    # Loads a cache from the json file.
    #
    # @return [void]
    def load
      @cache = JSON.parse(File.read(file))
    rescue
      @cache = {}
    end

    # Returns the patch of the cache file.
    #
    # @return [String] The path
    def file
      File.join(directory, @file)
    end

    # Returns the path of the directory where the cache is stored.
    #
    # @return [String] The path
    def directory
      @options[:directory]
    end
  end
end
