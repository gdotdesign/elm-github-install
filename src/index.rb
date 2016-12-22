require 'dep_selector'
require 'tmpdir'
require 'git'
require 'json'
require 'git_clone_url'

class Resolver
  include DepSelector

  attr_reader :graph

  def initialize
    @graph = DependencyGraph.new
  end

  def add_versions_for_package(path)
    repository(path)
      .tags
      .map(&:name)
      .each do |tag|
        add_version_for_package(tag, path)
      end
  end

  def add_version_for_package(tag, path)
    # Create version
    version = package(path).add_version(tag)

    # Checkout tag
    repository(path).checkout(tag)

    # Read elm-package.json
    elm_package_json(path)['dependencies'].each do |key, value|
      version.dependencies << Dependency.new(@graph.package(key), '= 0.1.1')
    end
  end

  def elm_package_json(path)
    JSON.parse(
      File.read(
        File.join(repository_path(path), 'elm-package.json')
      )
    )
  end

  def package(path)
    name = package_name(path)
    @graph.package(name)
  end

  def package_name(path)
    GitCloneUrl.parse(path).path
  end

  def repository(path)
    Git.open(repository_path(path))
  rescue
    Git.clone(path, repository_path(path))
  end

  def repository_path(path)
    File.join(chache_dir, package_name(path))
  end

  def chache_dir
    File.join(Dir.home, '.elm-github-install')
  end
end

resolver = Resolver.new
resolver.add_versions_for_package('git@github.com:gdotdesign/elm-ui')
puts resolver.graph
