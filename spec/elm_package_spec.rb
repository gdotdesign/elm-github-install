require 'spec_helper'

describe ElmInstall::ElmPackage do
  subject { described_class }

  let(:path) { 'spec/fixtures/elm-package.json' }

  describe '.transform_dependencies' do
    subject { described_class.dependencies(path) }

    it 'should return transformed dependencies' do
      expect(subject)
        .to eq(
          'git@some-domain.com:test/repo' => 'development',
          'git@github.com:base/core' => '2.0.0 <= v < 3.0.0'
        )
    end
  end

  describe '.transform_package' do
    it 'should transform normal packages names to github ones' do
      expect(subject.transform_package('test/repo'))
        .to eq 'git@github.com:test/repo'
    end

    it 'should return valid git urls' do
      expect(subject.transform_package('git@github.com:test/repo'))
        .to eq 'git@github.com:test/repo'
    end
  end
end
