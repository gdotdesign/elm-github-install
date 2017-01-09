module ElmInstall
  # This is a helper module for logging.
  module Logger
    # :nocov:
    # Logs the given message prefixed a green dot.
    #
    # @param message [String] The message to log
    #
    # @return [void]
    def self.dot(message)
      puts '  ● '.green + message
    end

    # Logs the given message prefixed an arrow.
    #
    # @param message [String] The message to log
    #
    # @return [void]
    def self.arrow(message)
      puts "  ▶ #{message}"
    end
    # :nocov:
  end
end
