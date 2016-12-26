require 'spec_helper'

describe ElmInstall::Resolver do
  subject { described_class.new cache, git_resolver }

  let(:git_resolver) { ElmInstall::GitResolver.new directory: CACHE_DIRECTORY }
  let(:cache) { ElmInstall::Cache.new directory: CACHE_DIRECTORY }

  let(:directory) { File.join CACHE_DIRECTORY, 'github.com/test/repo' }
  let(:core_directory) { File.join CACHE_DIRECTORY, 'github.com/base/core' }

  let(:package_json) do
    { dependencies: { 'base/core' => '1.0.0 <= v < 2.0.0' } }.to_json
  end

  before do
    FileUtils.mkdir_p directory
    File.binwrite File.join(directory, 'elm-package.json'), package_json
    Git.init directory
  end

  let(:url) { 'git@github.com:test/repo' }

  let(:core_repo) do
    repo = Git.init core_directory
    File.binwrite File.join(core_directory, 'elm-package.json'), '{}'
    repo
  end

  it 'should resolve packages' do
    expect(Git)
      .to receive(:clone) { core_repo }

    expect(Git)
      .to receive(:ls_remote)
      .and_return(tags: { name: '1.0.0' })

    expect(ElmInstall::Logger)
      .to receive(:arrow)
      .with "Package: #{'git@github.com:base/core'.bold} not found in \
             cache, cloning...".gsub(/\s+/, ' ')

    allow_any_instance_of(Git::Remote)
      .to receive(:url)
      .and_return url

    allow_any_instance_of(Git::Base)
      .to receive(:tags)
      .and_return [double(name: '1.0.0')]

    allow_any_instance_of(Git::Base)
      .to receive(:checkout)

    subject
      .instance_variable_get('@git_resolver')
      .instance_variable_get('@check_cache')[directory] = {}

    subject.instance_variable_get('@git_resolver').cache[directory] = {}

    subject.add_constraints(
      url => 'development',
      'git@github.com:base/core' => '1.0.0 <= v < 2.0.0'
    )
  end
end
