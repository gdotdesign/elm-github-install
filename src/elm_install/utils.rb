module ElmInstall
  module Utils
    module_function

    def transform_constraint(constraint)
      dependencies = []
      constraint.gsub!(/\s/,'')

      match = constraint.match(/(.*)<=v/)
      dependencies << ">= #{match[1]}" if match

      match = constraint.match(/(.*)<v/)
      dependencies << "> #{match[1]}" if match

      match = constraint.match(/v<(.*)/)
      dependencies << "< #{match[1]}" if match

      match = constraint.match(/v<=(.*)/)
      dependencies << "<= #{match[1]}" if match

      dependencies
    end

    def fix_path(key)
      GitCloneUrl.parse(key)
      key
    rescue
      "git@github.com:#{key}"
    end
  end
end
