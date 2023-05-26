require "./field/base"
require "./field/bool"
require "./field/date"
require "./field/date_time"
require "./field/duration"
require "./field/email"
require "./field/file"
require "./field/float"
require "./field/int"
require "./field/json"
require "./field/string"
require "./field/uuid"

module Marten
  abstract class Schema
    module Field
      annotation Registration
      end

      @@registry = {} of ::String => Base.class

      # :nodoc:
      def self.registry
        @@registry
      end

      # Allows to register a new schema field implementation.
      macro register(id, field_klass)
        {% klass = field_klass.resolve %}

        {% defining_type_method_name = "deserialize" %}
        {% exposed_type = nil %}

        {% method = klass.methods.find { |m| m.name == defining_type_method_name } %}
        {% unless method %}
          {% for ancestor_klass in klass.ancestors %}
            {% method = ancestor_klass.methods.find { |m| m.name == defining_type_method_name } unless method %}
          {% end %}
        {% end %}

        {% exposed_type = method.return_type %}

        {% for method in klass.methods %}
          {% if method.name == defining_type_method_name %}
            {% exposed_type = method.return_type %}
          {% end %}
        {% end %}
        {% unless exposed_type %}
          {% for parent_klass in klass.ancestors %}
            {% for method in parent_klass.methods %}
              {% if !exposed_type && method.name == defining_type_method_name %}
                {% exposed_type = method.return_type %}
              {% end %}
            {% end %}
          {% end %}
        {% end %}

        @[Marten::Schema::Field::Registration(id: {{ id }}, exposed_type: {{ exposed_type }})]
        class ::{{klass.id}}; end
        Marten::Schema::Field.add_field_to_registry({{ id }}, {{ klass }})
      end

      # :nodoc:
      def self.add_field_to_registry(id : ::String | Symbol, field_klass : Base.class)
        @@registry[id.to_s] = field_klass
      end

      macro finished
        {% field_types = [] of ::String %}
        {% for k in Marten::Schema::Field::Base.all_subclasses %}
          {% ann = k.annotation(Marten::Schema::Field::Registration) %}
          {% if ann %}
            {% field_types << ann[:exposed_type] %}
          {% end %}
        {% end %}

        alias Any = {% for t, i in field_types %}{{ t }}{% if i + 1 < field_types.size %} | {% end %}{% end %}
      end

      register "bool", Bool
      register "date", Date
      register "date_time", DateTime
      register "duration", Duration
      register "email", Email
      register "file", File
      register "float", Float
      register "int", Int
      register "json", JSON
      register "string", String
      register "uuid", UUID
    end
  end
end
