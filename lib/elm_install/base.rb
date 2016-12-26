module ElmInstall
  # This class is the base for the Cache and GitResolver packages.
  class Base
    extend Forwardable

    attr_reader :cache

    def_delegators :@cache, :each, :key?

    def initialize(options = {})
      @options = options
      @cache = {}
      load
    end

    # Saves the cache into the json file.
    def save
      File.binwrite(file, JSON.pretty_generate(@cache))
    end

    # Loads a cache from the json file.
    def load
      @cache = JSON.parse(File.read(file))
    rescue
      @cache = {}
    end

    def file
      File.join(directory, @file)
    end

    # Returns the directory where the cache is stored.
    def directory
      @options[:directory]
    end
  end
end
