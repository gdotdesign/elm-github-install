describe ElmInstall::Repository do
  subject { described_class.new '', '.' }

  describe '#clone' do
    it 'clones the repository' do
      expect(FileUtils)
        .to receive(:mkdir_p)

      expect(Git)
        .to receive(:clone)
        .with('', '.')
        .and_return(Git::Base.new)

      subject.clone
    end
  end

  describe '#checkout' do
    it 'checks out the given reference' do
      expect_any_instance_of(Git::Base)
        .to receive(:reset_hard)
        .twice

      expect_any_instance_of(Git::Base)
        .to receive(:checkout).with('')

      subject.checkout('')
    end
  end

  describe '#versions' do
    it 'returns the versions of the repository' do
      expect_any_instance_of(Git::Base)
        .to receive(:reset_hard)

      expect_any_instance_of(Git::Base)
        .to receive(:tags)
        .and_return [double(name: 'test'), double(name: '1.0.0')]

      expect(subject.versions)
        .to eq([Semverse::Version.new('1.0.0')])
    end
  end
end
