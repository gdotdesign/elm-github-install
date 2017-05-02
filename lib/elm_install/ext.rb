module Semverse
  # Add utility functions
  class Version
    def to_simple
      "#{major}.#{minor}.#{patch}"
    end

    def self.try_new(version)
      new version
    rescue
      nil
    end
  end
end
