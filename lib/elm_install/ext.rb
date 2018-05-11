# Extensions for the semvese module
module Semverse
  # Added utility functions
  class Version
    # Returns the simple string representation of a version
    #
    # @return [String]
    def to_simple
      if pre_release
        "#{major}.#{minor}.#{patch}-#{pre_release}"
      else
        "#{major}.#{minor}.#{patch}"
      end
    end

    # Tries to parse a version, falling back to nil if fails.
    #
    # @param version [String] The versio to parse
    #
    # @return [Semverse::Version]
    def self.try_new(version)
      new version
    rescue
      nil
    end
  end
end
