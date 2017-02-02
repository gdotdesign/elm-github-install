module ElmInstall
  class Sources < Base
    # Initializes a cache with the given options.
    #
    # @param options [Hash] The options
    def initialize(options = { directory: Dir.pwd })
      @file = 'elm-source-cache.json'
      super options
    end

    def []=(package, source)
      check_source(package, source)
      @cache[package] = source
    end

    def check_source(package, source)
      old_source = @cache[package]
      return unless old_source

      if old_source.is_a?(Hash) && source.is_a?(Hash)
        return if old_source[:ref] == source[:ref] &&
                  old_source[:url] == source[:url]
      else
        return if old_source == source
      end

      puts "
  The source of package #{package.bold} is has bee set to:

    #{old_source.to_s.bold}

  the new dependency would set it to:

    #{source.to_s.bold}

  they do not match, this means that you want to use the same package from
  different sources.
      "

      Process.exit
    end

    def resolve(package)
      if @cache[package].is_a?(Hash)
        @cache[package]['url']
      elsif @cache[package]
        @cache[package]
      else
        ElmPackage.transform_package(package)
      end
    end
  end
end
