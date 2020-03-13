module Marten
  module Routing
    module Parameter
      DEFAULT_TYPE = "str"

      alias Types = ::String | Int16 | Int32 | Int64

      @@registry = {} of ::String => Base

      def self.register(id : ::String | Symbol, parameter_klass : Base.class)
        @@registry[id.to_s] = parameter_klass.new
      end

      def self.registry
        @@registry
      end

      register DEFAULT_TYPE, String
      register "int", Integer
      register "slug", Slug
    end
  end
end
