require 'git_clone_url'
require 'fileutils'
require 'solve'
require 'json'
require 'git'

require_relative './cache'
require_relative './utils'

module ElmInstall
  class Resolver
    def initialize(options = { verbose: false })
      @cache = Cache.new
      @options = options
    end

    def resolve(constraints)
      populate_elm_stuff Solve.it!(@cache.to_graph, constraints)
    end

    def populate_elm_stuff(solution)
      solution.each do |package, version|
        repository(package).checkout(version)

        package_name = GitCloneUrl.parse(package).path
        package_path = File.join('elm-stuff', 'packages', package_name, version)

        puts " ● #{package_name} - #{version}"

        next if Dir.exists?(package_path)

        FileUtils.mkdir_p(package_path)
        FileUtils.cp_r(repository_path(package), package_path)
        FileUtils.rm_rf(File.join(package_path, '.git'))
      end

      ecxact_deps = solution.each_with_object({}) do |(key, value), memo|
        memo[GitCloneUrl.parse(key).path] = value
      end

      File.binwrite(File.join('elm-stuff', 'ecxact-dependencies.json'), JSON.pretty_generate(ecxact_deps))
    end

    def save_cache
      @cache.save
    end

    def add_versions_for_package(path)
      path = Utils.fix_path(path)

      return if @cache.package?(path)

      puts "Package: #{path} not found in cache, cloning..."

      repository(path)
        .tags
        .map(&:name)
        .each do |tag|
          @cache.ensure_version(path, tag)
          add_version_for_package(tag, path)
        end
    end

    def add_version_for_package(tag, path)
      repository(path).checkout(tag)

      elm_package_json(path)['dependencies'].each do |key, value|
        pkg_name = Utils.fix_path(key)
        add_versions_for_package(key)

        Utils.transform_constraint(value).each do |dep|
          @cache.dependency(path, tag, [pkg_name, dep])
        end
      end
    end

    def elm_package_json(path)
      JSON.parse(File.read(File.join(repository_path(path), 'elm-package.json')))
    rescue
      { 'dependencies' => [] }
    end

    def repository(path)
      repo = Git.open(repository_path(path))
      repo.reset_hard
      repo
    rescue
      Git.clone(path, repository_path(path))
    end

    def repository_path(path)
      File.join(@cache.directory, path)
    end
  end
end
