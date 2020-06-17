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
        {% klass = field_klass.resolve %}

        {% exposed_type = nil %}
        {% for method in klass.methods %}
          {% if method.name == "from_db_result_set" %}
            {% exposed_type = method.return_type %}
          {% end %}
        {% end %}

        @[Marten::DB::Field::Registration(id: {{ id }}, exposed_type: {{ exposed_type }})]
        class ::{{klass.id}}; end
        add_field_to_registry({{ id }}, {{ klass }})
      end

      register "int", Integer
      register "string", String

      protected def self.add_field_to_registry(id : ::String | Symbol, field_klass : Base.class)
        @@registry[id.to_s] = field_klass
      end
    end
  end
end
