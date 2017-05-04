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
      }

    }.to_json
  end

  before do
    expect(File)
      .to receive(:read)
      .and_return(package_json)
      .twice
  end

  describe 'Invalid json' do
    let(:package_json) { '' }

    it 'throws an error' do
      expect(ElmInstall::Logger)
        .to receive(:arrow)
        .twice

      subject
    end
  end

  it 'identifies sources and dependencies' do
    subject
  end
end
