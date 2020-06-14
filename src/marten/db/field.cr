module Marten
  module DB
    module Field
      @@registry = {} of ::String => Base.class

      def self.register(id : ::String | Symbol, field_klass : Base.class)
        @@registry[id.to_s] = field_klass
      end

      def self.registry
        @@registry
      end

      register "int", Integer
      register "string", String
    end
  end
end
