module ElmInstall
  Branch = ADT do
    Just(ref: String) |
    Nothing()
  end

  Uri = ADT do
    Ssh(uri: URI::SshGit::Generic) |
    Http(uri: URI::HTTP) |
    Github(name: String)
  end

  Type = ADT do
    Git(uri: Uri, branch: Branch) {
      def source
        @source ||= GitSource.new uri, branch
      end
    } |
    Directory(path: Dir) {
      def source
        @source ||= DirectorySource.new path
      end
    } |
    Registry(source: Class)
  end
end
