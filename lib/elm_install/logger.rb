module ElmInstall
  # This is a helper module for logging.
  module Logger
    # :nocov:
    def self.dot(message)
      puts '  ● '.green + message
    end

    def self.arrow(message)
      puts "  ▶ #{message}"
    end
    # :nocov:
  end
end
