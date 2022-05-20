require "./field/base"
require "./field/big_int"
require "./field/bool"
require "./field/date"
require "./field/date_time"
require "./field/file"
require "./field/float"
require "./field/int"
require "./field/string"
require "./field/text"
require "./field/uuid"

require "./field/many_to_many"
require "./field/many_to_one"
require "./field/one_to_one"

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

      register "big_int", BigInt
      register "bool", Bool
      register "date", Date
      register "date_time", DateTime
      register "file", File
      register "float", Float
      register "int", Int
      register "many_to_many", ManyToMany
      register "many_to_one", ManyToOne
      register "one_to_one", OneToOne
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
          {% if ann %}
            {% field_types << ann[:exposed_type] %}
          {% end %}
        {% end %}

        alias Any = Symbol | {% for t, i in field_types %}{{ t }}{% if i + 1 < field_types.size %} | {% end %}{% end %}
      end
    end
  end
end
