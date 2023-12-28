module Marten
  module DB
    module Field
      class ManyToMany < Base
        getter through
        getter through_from_field_id
        getter through_to_field_id

        def initialize(
          @id : ::String,
          @to : Model.class,
          @through : Model.class,
          @through_from_field_id : ::String,
          @through_to_field_id : ::String,
          @primary_key = false,
          @blank = false,
          @null = false,
          @unique = false,
          @index = false,
          @db_column = nil,
          @related : Nil | ::String | Symbol = nil
        )
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
        end

        def related_model
          @to
        end

        def relation?
          true
        end

        def relation_name
          @id
        end

        # Returns the field on the through model that points to the model defining the many-to-many field.
        def through_from_field
          through.get_relation_field_context(through_from_field_id).field
        end

        # Returns the field on the through model that points to the model targeted by the many-to-many field.
        def through_to_field
          through.get_relation_field_context(through_to_field_id).field
        end

        def to_column : Management::Column::Base?
          # No-op
        end

        def to_db(value) : ::DB::Any
          # No-op
        end

        # :nodoc:
        macro check_definition(field_id, kwargs)
          {% if kwargs.is_a?(NilLiteral) || kwargs[:to].is_a?(NilLiteral) %}
            {% raise "A related model must be specified for many to many fields ('to' option)" %}
          {% end %}
        end

        # :nodoc:
        macro contribute_to_model(model_klass, field_id, field_ann, kwargs)
          {% if !model_klass.resolve.abstract? %}
            # Automatically creates a "through" model to manage the many-to-many relationship between the considered
            # model and the related model.

            {% related_model_klass = kwargs[:to] %}
            {% if related_model_klass.id.stringify == "self" %}
              {% related_model_klass = model_klass %}
            {% end %}

            {% from_model_name = model_klass.stringify.split("::").last %}
            {% to_model_name = related_model_klass.stringify.split("::").last %}

            {% field_id_string = field_id.stringify %}

            {% through_model_name = "#{model_klass}#{field_id_string.capitalize.id}" %}
            {% through_related_name = "#{from_model_name.downcase.id}_#{field_id_string.downcase.id}" %}
            {% through_from_related_name = through_related_name %}
            {% through_to_related_name = through_related_name %}
            {% through_model_from_field_id = from_model_name.downcase %}
            {% through_model_to_field_id = to_model_name.downcase %}

            {% if through_model_from_field_id == through_model_to_field_id %}
              {% through_from_related_name = "from_" + through_related_name %}
              {% through_to_related_name = "to_" + through_related_name %}
              {% through_model_from_field_id = "from_#{through_model_from_field_id.id}" %}
              {% through_model_to_field_id = "to_#{through_model_to_field_id.id}" %}
            {% end %}

            class ::{{ model_klass }}
              @[Marten::DB::Model::Table::RelationInstanceVariable]
              @_m2m_{{ field_id }} : Marten::DB::Query::ManyToManySet({{ related_model_klass }})?

              register_field(
                {{ @type }}.new(
                  {{ field_id.stringify }},
                  {% unless kwargs.is_a?(NilLiteral) %}**{{ kwargs }}{% end %},
                  through: {{ through_model_name.id }},
                  through_from_field_id: {{ through_model_from_field_id.id.stringify }},
                  through_to_field_id: {{ through_model_to_field_id.id.stringify }}
                )
              )

              def {{ field_id }}
                @_m2m_{{ field_id }} ||= Marten::DB::Query::ManyToManySet({{ related_model_klass }}).new(
                  self,
                  {{ field_id.stringify }},
                  {{ through_to_related_name }},
                  {{ through_model_from_field_id }},
                  {{ through_model_to_field_id }}
                )
              end
            end

            class ::{{ through_model_name.id }} < Marten::DB::Model
              field :id, :big_int, primary_key: true, auto: true
              field(
                :{{ through_model_from_field_id.id }},
                :many_to_one,
                to: {{ model_klass }},
                on_delete: :cascade,
                related: {{ through_from_related_name }}
              )
              field(
                :{{ through_model_to_field_id.id }},
                :many_to_one,
                to: {{ related_model_klass }},
                on_delete: :cascade,
                related: {{ through_to_related_name }}
              )
            end

            {% related_field_name = kwargs[:related] %}

            # Register the reverse relation.

            ::{{ related_model_klass }}.register_reverse_relation(
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

            {% if !related_field_name.is_a?(NilLiteral) %}
              class ::{{ model_klass }}
                macro finished
                  class ::{{ related_model_klass }}
                    @[Marten::DB::Model::Table::RelationInstanceVariable]
                    @_reverse_m2m_{{ related_field_name.id }} : Marten::DB::Query::Set({{ model_klass }})?


                    def {{ related_field_name.id }}
                      @_reverse_m2m_{{ related_field_name.id }} ||= Marten::DB::Query::Set({{ model_klass }}).new
                        .filter(
                          Marten::DB::Query::Node.new(
                            {"{{ through_from_related_name.id }}__{{ through_model_to_field_id.id }}" => self}
                          )
                        )
                    end
                  end
                end
              end
            {% end %}
          {% end %}
        end
      end
    end
  end
end
