require 'spec_helper'

describe ElmInstall::Populator do
  let(:git_resolver) { ElmInstall::GitResolver.new directory: CACHE_DIRECTORY }

  let(:solution) do
    {
      'https://github.com/base/core' => '1.0.0',
      'https://github.com/test/repo' => '1.0.0+development'
    }
  end

  let(:repo) { double :repository, checkout: true }

  subject { described_class.new git_resolver }

  it 'should populate elm-stuff' do
    expect(git_resolver)
      .to receive(:repository)
      .exactly(2).times
      .and_return repo

    expect(ElmInstall::Logger)
      .to receive(:dot)
      .exactly(2)
      .times

    expect(FileUtils)
      .to receive(:cp_r)
      .with(
        'spec/fixtures/cache/github.com/base/core/.',
        'elm-stuff/packages/base/core/1.0.0'
      )

    expect(FileUtils)
      .to receive(:cp_r)
      .with(
        'spec/fixtures/cache/github.com/test/repo/.',
        'elm-stuff/packages/test/repo/1.0.0'
      )

    subject.populate(solution)
  end
end
