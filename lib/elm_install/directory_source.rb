module ElmInstall
  class DirectorySource < Source
    attr_reader :dir

    Contract Dir => DirectorySource
    def initialize(dir)
      @dir = dir
      self
    end

    Contract Or[String, Semverse::Version] => Dir
    def fetch(_)
      @dir
    end

    Contract Semverse::Version, Pathname => nil
    def copy_to(_, directory)
      # Delete the directory to make sure no pervious version remains
      FileUtils.rm_rf(directory) if directory.exist?

      # Create symlink
      FileUtils.ln_s(@dir, directory)

      nil
    end

    # Returns the available versions for a repository
    Contract None => ArrayOf[Semverse::Version]
    def versions
      [ identifier.version(@dir) ]
    end
  end
end
