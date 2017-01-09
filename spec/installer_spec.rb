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
        .and_return(main_package, base_package, base_package)

      expect_any_instance_of(ElmInstall::Resolver)
        .to receive(:add_constraints)

      expect(subject)
        .to receive(:puts)
        .exactly(4).times

      expect(File)
        .to receive(:binwrite)
        .with('spec/fixtures/cache/ref-cache.json', any_args)

      expect(File)
        .to receive(:binwrite)
        .with('spec/fixtures/cache/cache.json', any_args)

      expect(File)
        .to receive(:binwrite)
        .with('elm-stuff/exact-dependencies.json', any_args)
    end

    it 'should install dependencies' do
      subject.install
    end
  end

  context 'unsuccessfull install' do
    before do
      expect(File)
        .to receive(:read)
        .and_return(main_package, base_package, base_package)

      expect_any_instance_of(ElmInstall::Resolver)
        .to receive(:add_constraints)
        .exactly(2).times

      expect(subject)
        .to receive(:populate_elm_stuff)
        .exactly(2).times
        .and_raise(Solve::Errors::NoSolutionError)

      expect(ElmInstall::Logger)
        .to receive(:arrow)

      expect(subject)
        .to receive(:puts)
        .exactly(4).times
    end

    it 'should install dependencies' do
      subject.install
    end
  end
end
