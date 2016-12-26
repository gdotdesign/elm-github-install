require File.expand_path('../lib/elm_install/version', __FILE__)

Gem::Specification.new do |s|
  s.name          = 'elm_install'
  s.version       = ElmInstall::VERSION
  s.authors       = ['Gusztáv Szikszai']
  s.email         = 'gusztav.szikszai@digitalnatives.hu'
  s.homepage      = 'https://github.com/gdotdesign/elm-github-install'
  s.summary       = 'Install Elm packages from git repositories.'
  s.require_paths = ['lib']

  s.files =
    `git ls-files`.split("\n")

  s.test_files =
    `git ls-files -- {test,spec,features}/*`.split("\n")

  s.executables =
    `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }

  s.add_dependency 'git', '~> 1.3'
  s.add_dependency 'git_clone_url', '~> 2.0'
  s.add_dependency 'solve', '~> 3.1'
  s.add_dependency 'commander', '~> 4.4', '>= 4.4.2'
  s.add_dependency 'smart_colored', '~> 1.1', '>= 1.1.1'
  s.add_dependency 'hashdiff', '~> 0.3.1'
  s.add_dependency 'indentation', '~> 0.1.1'

  s.extra_rdoc_files = ['Readme.md']
end
