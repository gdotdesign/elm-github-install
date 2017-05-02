module ElmInstall
  # Base class that contains contracts.
  class Base
    include Contracts::Core
    include Contracts::Builtin
  end
end
