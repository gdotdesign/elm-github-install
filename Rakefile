require 'bundler/setup'

Bundler::GemHelper.install_tasks

task :ci do
  sh 'rubocop'
  sh 'rubycritic -m --no-browser -s 90 lib'
  sh 'inch suggest lib --pedantic'
  sh 'rspec'
end
