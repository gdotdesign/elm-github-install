describe ElmInstall do
  it 'should install packages' do
    allow(ElmInstall::Logger)
      .to receive(:arrow)

    expect_any_instance_of(ElmInstall::Installer)
      .to receive(:install)

    subject.install(cache_directory: CACHE_DIRECTORY)
  end
end
