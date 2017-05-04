module ElmInstall
  # This clas handles sources that point to a local directory.
  class DirectorySource < Source
    attr_reader :dir

    Contract Pathname => DirectorySource
    # Initializes a directory source with the given directory.
    #
    # @param dir [Dir] The directory
    #
    # @return [DirectorySource] The directory source instance
    def initialize(dir)
      @dir = dir
      self
    end

    Contract Or[String, Semverse::Version] => Dir
    # Returns the directory
    #
    # @param _ [String] The version
    #
    # @return [Dir] The directory
    def fetch(_)
      Dir.new(@dir.expand_path)
    end

    Contract Semverse::Version, Pathname => nil
    # Copies the directory to the given other directory
    #
    # @param _ [Semverse::Version] The version
    # @param directory [Pathname] The pathname
    #
    # @return nil
    def copy_to(_, directory)
      # Delete the directory to make sure no pervious version remains
      FileUtils.rm_rf(directory) if directory.exist?

      # Create parent directory
      FileUtils.mkdir_p(directory.parent)

      # Create symlink
      FileUtils.ln_s(@dir.expand_path, directory)

      nil
    end

    Contract ArrayOf[Solve::Constraint] => ArrayOf[Semverse::Version]
    # Returns the available versions for a repository
    #
    # @param _ [Array] The constraints
    #
    # @return [Array] The versions
    def versions(_)
      [identifier.version(fetch(''))]
    end

    Contract None => String
    # Returns the log format
    #
    # @return [String]
    def to_log
      @dir.expand_path.to_s
    end
  end
end
