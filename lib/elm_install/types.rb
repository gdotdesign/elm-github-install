module ElmInstall
  Branch = ADT do
    Just(ref: String) |
      Nothing()
  end

  Uri = ADT do
    Ssh(uri: URI::SshGit::Generic) do
      def to_s
        uri.to_s
      end
    end |

      Http(uri: URI::HTTP) do
        def to_s
          uri.to_s
        end
      end |

      Github(name: String) do
        def to_s
          "https://github.com/#{name}"
        end
      end
  end

  Type = ADT do
    Git(uri: Uri, branch: Branch) do
      def source
        @source ||= GitSource.new uri, branch
      end
    end |

      Directory(path: Pathname) do
        def source
          @source ||= DirectorySource.new path
        end
      end
  end
end
