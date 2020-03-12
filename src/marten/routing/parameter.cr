module Marten
  module Routing
    module Parameter
      DEFAULT_TYPE = "str"

      @@registry = {} of ::String => Base

      def self.register(id : ::String | Symbol, parameter_klass : Base.class)
        @@registry[id.to_s] = parameter_klass.new
      end

      def self.registry
        @@registry
      end

      register DEFAULT_TYPE, String
    end
  end
end
