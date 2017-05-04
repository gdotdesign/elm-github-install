require 'spec_helper'

describe ElmInstall do
  it 'should install packages' do
    expect(ElmInstall::Logger)
      .to receive(:arrow)
      .twice

    expect_any_instance_of(ElmInstall::Installer)
      .to receive(:install)

    subject.install(cache_directory: CACHE_DIRECTORY)
  end
end
