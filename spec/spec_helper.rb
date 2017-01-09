require 'simplecov'

CACHE_DIRECTORY = 'spec/fixtures/cache'.freeze

RSpec.configure do |config|
  config.before do
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
