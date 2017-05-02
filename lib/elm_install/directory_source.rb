module ElmInstall
  class DirectorySource < Source
    attr_reader :dir

    Contract Pathname => DirectorySource
    def initialize(dir)
      @dir = dir
      self
    end

    Contract Or[String, Semverse::Version] => Dir
    def fetch(_)
      Dir.new(@dir.expand_path)
    end

    Contract Semverse::Version, Pathname => nil
    def copy_to(_, directory)
      # Delete the directory to make sure no pervious version remains
      FileUtils.rm_rf(directory) if directory.exist?

      # Create parent directory
      FileUtils.mkdir_p(directory.parent)

      # Create symlink
      FileUtils.ln_s(@dir.expand_path, directory)

      nil
    end

    Contract None => nil
    def reset
      nil
    end

    # Returns the available versions for a repository
    Contract ArrayOf[Solve::Constraint] => ArrayOf[Semverse::Version]
    def versions(_)
      [ identifier.version(fetch('')) ]
    end
  end
end
