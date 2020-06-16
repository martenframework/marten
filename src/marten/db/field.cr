require "./field/**"

module Marten
  module DB
    module Field
      annotation Registration
      end

      @@registry = {} of ::String => Base.class

      def self.registry
        @@registry
      end

      macro register(id, field_klass)
        @[Marten::DB::Field::Registration(field_id: {{ id }})]
        class ::{{field_klass.resolve.id}}; end
        add_field_to_registry({{ id }}, {{ field_klass }})
      end

      register "int", Integer
      register "string", String

      protected def self.add_field_to_registry(id : ::String | Symbol, field_klass : Base.class)
        @@registry[id.to_s] = field_klass
      end
    end
  end
end
