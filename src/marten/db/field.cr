require "./field/base"
require "./field/big_int"
require "./field/bool"
require "./field/date_time"
require "./field/int"
require "./field/string"
require "./field/text"
require "./field/uuid"

require "./field/auto"
require "./field/big_auto"

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

        {% defining_type_method_name = "from_db_result_set" %}
        {% exposed_type = nil %}

        {% method = klass.methods.find { |m| m.name == defining_type_method_name } %}
        {% unless method %}
          {% for ancestor_klass in klass.ancestors %}
            {% method = ancestor_klass.methods.find { |m| m.name == defining_type_method_name } unless method %}
          {% end %}
        {% end %}

        {% exposed_type = method.return_type %}

        {% for method in klass.methods %}
          {% if method.name == "from_db_result_set" %}
            {% exposed_type = method.return_type %}
          {% end %}
        {% end %}
        {% unless exposed_type %}
          {% for parent_klass in klass.ancestors %}
            {% for method in parent_klass.methods %}
              {% if !exposed_type && method.name == "from_db_result_set" %}
                {% exposed_type = method.return_type %}
              {% end %}
            {% end %}
          {% end %}
        {% end %}

        @[Marten::DB::Field::Registration(id: {{ id }}, exposed_type: {{ exposed_type }})]
        class ::{{klass.id}}; end
        add_field_to_registry({{ id }}, {{ klass }})
      end

      register "auto", Auto
      register "big_auto", BigAuto
      register "big_int", BigInt
      register "bool", Bool
      register "date_time", DateTime
      register "int", Int
      register "string", String
      register "text", Text
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
