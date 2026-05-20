module Marten
  module DB
    module Field
      # Represents a polymorphic field.
      #
      # A polymorphic field is a field that can store a reference to a record of any of the specified types:
      #
      # ```
      # class MyModel < Marten::Model
      #   # Other fields...
      #   field :owner, :polymorphic, to: [User, Group]
      # end
      # ```
      class Polymorphic < Base
        getter id_field_id
        getter type_field_id

        def initialize(
          @id : ::String,
          @id_field_id : ::String,
          @type_field_id : ::String,
          @to : Array(Model.class),
          @blank = false,
          @null = false,
          @unique = false,
          @index = false,
          @related : Nil | ::String | Symbol = nil,
        )
          @primary_key = false
          @related = @related.try(&.to_s)
        end

        def db_column
          # No-op
        end

        def default
          # No-op
        end

        def from_db(value) : Nil
          # No-op
        end

        def from_db_result_set(result_set : ::DB::ResultSet) : Nil
          # No-op
        end

        def perform_validation(record : Model)
          # No-op
          # Validations should be handled by the underlying fields.
        end

        def relation?
          true
        end

        def relation_name
          @id
        end

        def to_column : Management::Column::Base?
          # No-op
        end

        def to_db(value) : ::DB::Any
          # No-op
        end

        # :nodoc:
        def type_class(type_name : ::String) : Model.class
          @to.find { |type| type.name == type_name } || @to.find!(&.name.ends_with?("::#{type_name}"))
        end

        # :nodoc:
        macro check_definition(field_id, kwargs)
          {% if kwargs.is_a?(NilLiteral) || !kwargs[:to].is_a?(ArrayLiteral) %}
            {% raise "A list of target models must be specified for polymorphic fields ('to' option)" %}
          {% end %}
        end

        # :nodoc:
        macro contribute_to_model(model_klass, field_id, field_ann, kwargs)
          {% polymorphic_target_type_field_id = field_id.stringify + "_type" %}
          {% polymorphic_target_id_field_id = field_id.stringify + "_id" %}
          {% blank = kwargs[:blank].nil? ? true : kwargs[:blank] %}
          {% null = kwargs[:null].nil? ? true : kwargs[:null] %}
          {% index = kwargs[:index].nil? ? false : kwargs[:index] %}
          {% unique = kwargs[:unique].nil? ? false : kwargs[:unique] %}
          {% types = kwargs[:to] %}

          class ::{{ model_klass }}
            @[Marten::DB::Model::Table::FieldInstanceVariable(
              field_klass: {{ @type }},
              field_kwargs: {{ kwargs }},
              field_type: nil,
              no_value: true,
              relation_name: {{ field_id }},
              related_model: ::Marten::DB::Model,
              model_klass: {{ model_klass }}
            )]
            @[Marten::DB::Model::Table::RelationInstanceVariable(
              many: false,
              reverse: false,
              relation_name: {{ field_id }},
            )]
            @{{ field_id }} :{% for type in types %} {{ type }} |{% end %} Nil

            register_field(
              {{ @type }}.new(
                {{ field_id.stringify }},
                {{ polymorphic_target_id_field_id.id.stringify }},
                {{ polymorphic_target_type_field_id.id.stringify }},
                **{{ kwargs }}
              )
            )

            field :{{ polymorphic_target_type_field_id.id }},
              :string,
              max_size: 255,
              blank: {{ blank }},
              null: {{ null }},
              index: {{ index }}
            field :{{ polymorphic_target_id_field_id.id }},
              :polymorphic_reference,
              types: {{ types }},
              blank: {{ blank }},
              null: {{ null }},
              index: {{ index }}

            {% if unique %}
            db_unique_constraint :{{ field_id }}_unique_constraint,
              field_names: [
                {{ polymorphic_target_type_field_id.id.stringify }},
                {{ polymorphic_target_id_field_id.id.stringify }}
              ]
            {% end %}

            {% if index %}
            db_index :{{ field_id }}_index,
              field_names: [
                {{ polymorphic_target_type_field_id.id.stringify }},
                {{ polymorphic_target_id_field_id.id.stringify }}
              ]
            {% end %}

            def {{ field_id }} : {% for type in types %}{{ type }} |{% end %} Nil
              @{{ field_id }} ||= begin
                case {{ polymorphic_target_type_field_id.id }}
                {% for type in types %}
                  when "{{ type.id }}"
                    {{ type }}.get(pk: {{ polymorphic_target_id_field_id.id }})
                {% end %}
                {% for type in types %}
                  when .try { |v| v.ends_with?("::{{ type.id }}") }
                    {{ type }}.get(pk: {{ polymorphic_target_id_field_id.id }})
                {% end %}
                else
                  nil
                end
              end
            end

            def {{ field_id }}! : {% for type, index in types %}{{ type }}{% if index < types.size - 1 %} |{% end %}{% end %} # ameba:disable Layout/LineLength
              {{ field_id }}.not_nil!
            end

            def {{ field_id }}? : ::Bool
              has_type_value = self.class.get_field({{ polymorphic_target_type_field_id.id.stringify }})
                .getter_value?(get_field_value({{ polymorphic_target_type_field_id.id.stringify }}))
              has_id_value = self.class.get_field({{ polymorphic_target_id_field_id.id.stringify }})
                .getter_value?(get_field_value({{ polymorphic_target_id_field_id.id.stringify }}))

              has_type_value && has_id_value
            end

            def {{ field_id }}=(value : Marten::DB::Model?)
              set_field_value({{ polymorphic_target_type_field_id.id.stringify }}, value.try(&.class.name))
              set_field_value({{ polymorphic_target_id_field_id.id.stringify }}, value.try(&.pk))
              @{{ field_id }} = value
            end

            def {{ field_id }}_class : {% for type in types %}{{ type }}.class |{% end %} Nil
              @{{ field_id }}.try(&.class)
            end

            def {{ field_id }}_class! : {% for type, index in types %}{{ type }}.class{% if index < types.size - 1 %} |{% end %}{% end %} # ameba:disable Layout/LineLength
              {{ field_id }}_class.not_nil!
            end

            {% for type in types %}
              def self.with_{{ type.stringify.split("::").last.underscore.id }}_{{ field_id }}
                field = get_field({{ field_id.stringify }}).as(Marten::DB::Field::Polymorphic)
                filter({{ polymorphic_target_type_field_id.id }}: field.type_class("{{ type.id }}").name)
              end

              def {{ type.stringify.split("::").last.underscore.id }}_{{ field_id }} : {{ type }}?
                {{ field_id }}.as?({{ type }})
              end

              def {{ type.stringify.split("::").last.underscore.id }}_{{ field_id }}! : {{ type }}
                {{ field_id }}.as({{ type }})
              end

              def {{ type.stringify.split("::").last.underscore.id }}_{{ field_id }}? : ::Bool
                field = self.class.get_field({{ field_id.stringify }}).as(Marten::DB::Field::Polymorphic)
                {{ field_id }}? &&
                  get_field_value(
                    {{ polymorphic_target_type_field_id.id.stringify }}
                  ) == field.type_class("{{ type.id }}").name
              end
            {% end %}
          end

          {% if !model_klass.resolve.abstract? %}
            {% related_field_name = kwargs[:related] %}

            {% for type in types %}
            ::{{ type }}.register_reverse_relation(
              Marten::DB::ReverseRelation.new(
                {% if !related_field_name.is_a?(NilLiteral) %}
                  {{ related_field_name.id.stringify }},
                {% else %}
                  nil,
                {% end %}
                ::{{ model_klass }},
                {{ field_id.stringify }}
              )
            )
            {% end %}

            # Configure reverse relation methods if applicable (when the 'related' option is set).

            {% if !related_field_name.is_a?(NilLiteral) %}
              class ::{{ model_klass }}
                macro finished
                  {% for type in types %}
                    class ::{{ type }}
                      @[Marten::DB::Model::Table::RelationInstanceVariable(
                        many: true,
                        reverse: true,
                        relation_name: {{ related_field_name.id }}
                      )]
                      @_reverse_polymorphic_{{ related_field_name.id }} : {{ model_klass }}::RelatedQuerySet?

                      def {{ related_field_name.id }}
                        @_reverse_polymorphic_{{ related_field_name.id }} ||=
                          {{ model_klass }}::RelatedQuerySet.new(self, {{ field_id.stringify }}, assign_related: true)
                      end
                    end
                  {% end %}
                end
              end
            {% end %}
          {% end %}
        end
      end
    end
  end
end
