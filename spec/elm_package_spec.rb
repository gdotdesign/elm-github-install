require 'spec_helper'

describe ElmInstall::ElmPackage do
  subject { described_class }

  let(:path) { 'spec/fixtures/elm-package.json' }
  let(:invalid_path) { 'spec/fixtures/invalid-elm-package.json' }
  let(:mismatch_path) { 'spec/fixtures/mismatched-elm-package.json' }

  context 'package mismatch' do
    subject { described_class.dependencies(mismatch_path) }

    it 'should exit' do
      expect(ElmInstall::ElmPackage)
        .to receive(:puts)

      expect(Process).to receive(:exit)
      subject
    end
  end

  context 'missing file' do
    subject { described_class.dependencies('test') }

    it 'should exit' do
      expect(ElmInstall::Logger)
        .to receive(:arrow)
        .with "Could not find file: #{'test'.bold}."

      expect(Process).to receive(:exit)

      expect { subject }.to raise_error(NoMethodError)
    end
  end

  context 'invalid file' do
    subject { described_class.dependencies(invalid_path) }

    it 'should exit' do
      expect(ElmInstall::Logger)
        .to receive(:arrow)
        .with "Invalid JSON in file: #{invalid_path.bold}."

      expect(Process).to receive(:exit)

      expect { subject }.to raise_error(NoMethodError)
    end
  end

  describe '.transform_dependencies' do
    subject { described_class.dependencies(path) }

    it 'should return transformed dependencies' do
      expect(subject)
        .to eq(
          'git@some-domain.com:test/repo' => 'development',
          'https://github.com/base/core' => '2.0.0 <= v < 3.0.0'
        )
    end
  end

  describe '.transform_package' do
    it 'should transform normal packages names to github ones' do
      expect(subject.transform_package('test/repo'))
        .to eq 'https://github.com/test/repo'
    end

    it 'should return valid git urls' do
      expect(subject.transform_package('git@github.com:test/repo'))
        .to eq 'git@github.com:test/repo'
    end
  end
end
