require 'solve'
require 'tmpdir'
require 'git'
require 'json'
require 'git_clone_url'

class Resolver
  attr_reader :graph

  def initialize(verbose = false)
    @graph = Solve::Graph.new
    @verbose = verbose
    @cache = {}
  end

  def add_versions_for_package(path)
    path = fix_path(path)
    return if @cache[path]

    puts "Adding versions for: #{path}..." if @verbose

    repository(path)
      .tags
      .map(&:name)
      .each do |tag|
        add_version_for_package(tag, path)
      end

    @cache[path] = true
  end

  def add_version_for_package(tag, path)
    # Create version
    name = package_name(path)
    version = @graph.artifact(name, tag)

    # Checkout tag
    repository(path).checkout(tag)

    # Read elm-package.json
    elm_package_json(path)['dependencies'].each do |key, value|
      pkg_name = package_name(key)
      add_versions_for_package(key)

      transform_constraint(value).each do |dep|
        version.depends(pkg_name, dep)
      end
    end
  rescue
  end

  def fix_path(key)
    GitCloneUrl.parse(key)
    key
  rescue
    "git@github.com:#{key}"
  end

  def transform_constraint(constraint)
    dependencies = []
    constraint.gsub!(/\s/,'')

    match = constraint.match(/(.*)<=v/)
    dependencies << ">= #{match[1]}" if match

    match = constraint.match(/v<(.*)/)
    dependencies << "< #{match[1]}" if match

    dependencies
  end

  def elm_package_json(path)
    JSON.parse(File.read(File.join(repository_path(path), 'elm-package.json')))
  rescue
    { 'dependencies' => [] }
  end

  def package_name(path)
    GitCloneUrl.parse(fix_path(path)).path
  end

  def repository(path)
    Git.open(repository_path(path))
  rescue
    puts "Cloning #{path}..." if @verbose

    Git.clone(path, repository_path(path))
  end

  def repository_path(path)
    File.join(chache_dir, package_name(path))
  end

  def chache_dir
    File.join(Dir.home, '.elm-github-install')
  end

  def self.resolve_elm_package
    resolver = new

    deps = JSON.parse(File.read('elm-package.json'))['dependencies']

    constraints = deps.map do |key, value|
      name = resolver.package_name(key)
      resolver.add_versions_for_package(key)

      resolver.transform_constraint(value).map do |c|
        [name, c]
      end
    end
    .reduce(&:+)

    Solve.it!(resolver.graph, constraints)
  end
end

puts Resolver.resolve_elm_package
