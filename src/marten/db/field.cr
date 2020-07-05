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

      register "datetime", DateTime
      register "int", Integer
      register "string", String
      register "uuid", UUID

      protected def self.add_field_to_registry(id : ::String | Symbol, field_klass : Base.class)
        @@registry[id.to_s] = field_klass
      end

      macro finished
        {% field_types = [] of String %}
        {% for k in Marten::DB::Field::Base.all_subclasses %}
          {% ann = k.annotation(Marten::DB::Field::Registration) %}
          {% field_types << ann[:exposed_type] %}
        {% end %}

        alias Any = {% for t, i in field_types %}{{ t }}{% if i + 1 < field_types.size %} | {% end %}{% end %}
      end
    end
  end
end
