require 'spec_helper'

describe ElmInstall::Installer do
  subject { described_class.new cache_directory: CACHE_DIRECTORY }

  let(:main_package) do
    { dependencies: { 'base/core' => '1.0.0 <= v < 2.0.0' } }.to_json
  end

  let(:base_package) do
    { dependencies: {} }.to_json
  end

  context 'sucessfull install' do
    before do
      expect(File)
        .to receive(:read)
        .with(File.join(Dir.pwd, 'elm-package.json'))
        .and_return(main_package)
        .twice

      expect(File)
        .to receive(:read)
        .with(File.join(Dir.new(CACHE_DIRECTORY), 'elm-package.json'))
        .and_return(base_package)

      expect_any_instance_of(ElmInstall::GitSource)
        .to receive(:versions)
        .and_return([Semverse::Version.new('1.0.0')])

      expect_any_instance_of(ElmInstall::GitSource)
        .to receive(:fetch)
        .with(Semverse::Version.new('1.0.0'))
        .twice
        .and_return Dir.new(CACHE_DIRECTORY)

      expect(ElmInstall::Logger)
        .to receive(:dot)

      expect(subject)
        .to receive(:puts)
        .exactly(3).times

      expect(File)
        .to receive(:binwrite)
        .with('elm-stuff/exact-dependencies.json', any_args)
        .and_return(0)
    end

    it 'installs dependencies' do
      subject.install
    end
  end

  context 'unsuccessfull install' do
    let(:main_package) do
      { dependencies: { 'base/test' => '1.0.0 <= v < 2.0.0' } }.to_json
    end

    before do
      expect(File)
        .to receive(:read)
        .with(File.join(Dir.pwd, 'elm-package.json'))
        .and_return(main_package)
        .twice

      expect(subject)
        .to receive(:results)
        .and_raise(Solve::Errors::NoSolutionError)

      expect_any_instance_of(ElmInstall::GitSource)
        .to receive(:versions)
        .and_return([])

      expect(ElmInstall::Logger)
        .to receive(:arrow)

      expect(subject)
        .to receive(:puts)
        .exactly(2).times
    end

    it 'does not install anything' do
      subject.install
    end
  end
end
