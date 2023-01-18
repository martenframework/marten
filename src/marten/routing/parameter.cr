module Marten
  module Routing
    module Parameter
      DEFAULT_TYPE = "str"

      alias Types = Int8 | Int16 | Int32 | Int64 | UInt8 | UInt16 | UInt32 | UInt64 | ::String | ::UUID

      @@registry = {} of ::String => Base

      def self.register(id : ::String | Symbol, parameter_klass : Base.class)
        @@registry[id.to_s] = parameter_klass.new
      end

      def self.registry
        @@registry
      end

      register DEFAULT_TYPE, String
      register "int", Integer
      register "path", Path
      register "slug", Slug
      register "string", String
      register "uuid", UUID
    end
  end
end
