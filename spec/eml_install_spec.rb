require 'spec_helper'

describe ElmInstall do
  it 'should install packages' do
    expect_any_instance_of(ElmInstall::Installer)
      .to receive(:install)
    subject.install
  end
end
