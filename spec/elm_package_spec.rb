require 'spec_helper'

describe ElmInstall::ElmPackage do
  subject { described_class.dependencies(path) }

  let(:path) { 'spec/fixtures/elm-package.json' }

  it 'should return transformed dependencies' do
    expect(subject)
      .to eq(
        'git@some-domain.com:test/repo' => 'ref:development',
        'base/core' => '2.0.0 <= v < 3.0.0'
      )
  end
end
