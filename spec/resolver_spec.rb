require 'spec_helper'

describe ElmInstall::Resolver do
  subject { described_class.new cache, git_resolver }

  let(:git_resolver) { ElmInstall::GitResolver.new directory: CACHE_DIRECTORY }
  let(:cache) { ElmInstall::Cache.new directory: CACHE_DIRECTORY }

  let(:directory) { File.join CACHE_DIRECTORY, 'github.com/test/repo' }

  before do
    FileUtils.mkdir_p directory
    Git.init directory
  end

  xit 'asa' do
    subject.add_constraints('git@github.com:test/repo' => 'development')
  end
end
