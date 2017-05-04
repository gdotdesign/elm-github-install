describe ElmInstall::DirectorySource do
  let(:dir) { Pathname.new('.') }

  subject { described_class.new dir }

  describe '#fetch' do
    it 'returns the directory' do
      expect(subject.fetch('').path).to eq dir.expand_path.to_s
    end
  end

  describe '#copy_to' do
    it 'symlinks the directory' do
      allow(FileUtils).to receive(:rm_rf)
      expect(FileUtils).to receive(:mkdir_p)
      expect(FileUtils).to receive(:ln_s)
      subject.copy_to(Semverse::Version.new('1.0.0'), dir)
    end
  end

  describe '#versions' do
    let(:identifier) do
      double :identifier, version: Semverse::Version.new('1.0.0')
    end

    it 'returns version' do
      subject.identifier = identifier
      subject.versions([])
    end
  end

  describe '#to_log' do
    it 'returns the url' do
      expect(subject.to_log).to eq dir.expand_path.to_s
    end
  end
end
