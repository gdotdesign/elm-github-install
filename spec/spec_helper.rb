require 'simplecov'

CACHE_DIRECTORY = 'spec/cache'.freeze

RSpec.configure do |config|
  config.before do
    allow(Process).to receive(:exit)
    allow(ElmInstall::Logger).to receive(:puts)
    FileUtils.mkdir_p CACHE_DIRECTORY
  end

  config.after do
    FileUtils.rm_rf CACHE_DIRECTORY
    FileUtils.rm_rf 'elm-stuff'
  end
end

SimpleCov.start do
  add_filter '/vendor/'
  add_filter '/spec/'
end

require_relative '../lib/elm_install'
