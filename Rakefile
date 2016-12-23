require 'bundler/setup'

Bundler::GemHelper.install_tasks

task :ci do
  sh 'rubocop'
  sh 'rubycritic -m --no-browser -s 90'
end
