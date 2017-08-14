describe ElmInstall::Identifier do
  subject { described_class.new Dir.new('.') }

  let(:package_json) do
    {
      'dependencies' =>
      {
        'test/test' => '1.0.0 <= v < 2.0.0',
        'test/ref' => '1.0.0 <= v < 2.0.0',
        'test/dir' => '1.0.0 <= v < 2.0.0'
      },
      'dependency-sources' =>
      {
        'test/test' => 'git@github.com:test/test',
        'test/ref' => {
          url: 'http://www.github.com/test/test.git',
          ref: 'master'
        },
        'test/dir' => '../'
      },
      version: '1.0.0'
    }.to_json
  end

  before do
    allow(File)
      .to receive(:read)
      .and_return(package_json)
  end

  describe 'Invalid json' do
    let(:package_json) { '' }

    it 'throws an error' do
      allow(ElmInstall::Logger)
        .to receive(:arrow)

      subject
    end
  end

  describe '#version' do
    it 'returns the version from the json' do
      expect(subject.version(Dir.new('.')))
        .to eq(Semverse::Version.new('1.0.0'))
    end
  end

  it 'identifies sources and dependencies' do
    subject
  end
end
