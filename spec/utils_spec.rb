require 'spec_helper'

describe ElmInstall::Utils do
  subject { described_class }

  let(:package_variations) do
    [
      'git@github.com:test/repo',
      'https://github.com/test/repo',
      'git://github.com/test/repo'
    ]
  end

  describe '.package_version_path' do
    it 'should return the path for a package in elm-stuff' do
      package_variations.each do |package|
        expect(subject.package_version_path(package, '1.0.0'))
          .to eq(['test/repo', 'elm-stuff/packages/test/repo/1.0.0'])
      end
    end
  end

  describe '.transform_constraint' do
    it 'should convert basic constraint' do
      expect(subject.transform_constraint('0.1.0 <= v < 1.0.0'))
        .to eq(['< 1.0.0', '>= 0.1.0'])
    end

    it 'should convert advanced constraint' do
      expect(subject.transform_constraint('0.1.0 < v <= 1.0.0'))
        .to eq(['<= 1.0.0', '> 0.1.0'])
    end
  end
end
