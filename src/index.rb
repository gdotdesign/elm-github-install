require_relative './elm_install/resolver'

module ElmInstall
  module_function

  def resolve
    resolver = Resolver.new verbose: true

    deps = JSON.parse(File.read('elm-package.json'))['dependencies']

    constraints = deps.map do |key, value|
      name = Utils.fix_path(key)
      resolver.add_versions_for_package(key)

      Utils.transform_constraint(value).map do |c|
        [name, c]
      end
    end
    .reduce(&:+)

    resolver.save_cache
    resolver.resolve(constraints)
  end
end

ElmInstall.resolve
