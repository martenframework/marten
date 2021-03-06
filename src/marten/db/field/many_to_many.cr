module Marten
  module DB
    module Field
      class ManyToMany < Base
        def initialize(
          @id : ::String,
          @to : Model.class,
          @primary_key = false,
          @blank = false,
          @null = false,
          @unique = false,
          @editable = true,
          @db_column = nil,
          @db_index = true,
          @related : Nil | ::String | Symbol = nil
        )
          @related = @related.try(&.to_s)
        end

        def default
          # No-op
        end

        def from_db_result_set(result_set : ::DB::ResultSet) : Int32 | Int64 | Nil
          # No-op
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
        macro contribute_to_model(model_klass, field_id, field_ann, kwargs)
          {% related_model_klass = kwargs[:to] %}

          {% from_model_name = model_klass.stringify %}
          {% to_model_name = related_model_klass.stringify %}

          {% field_id_string = field_id.stringify %}

          {% through_model_name = "#{model_klass}#{field_id_string.capitalize.id}" %}
          {% through_model_table_name = "#{from_model_name.downcase.id}_#{field_id_string.downcase.id}" %}
          {% through_model_from_field_id = from_model_name.downcase %}
          {% through_model_to_field_id = to_model_name.downcase %}

          {% if through_model_from_field_id == through_model_to_field_id %}
            {% through_model_from_field_id = "from_#{through_model_from_field_id}" %}
            {% through_model_to_field_id = "to_#{through_model_to_field_id}" %}
          {% end %}

          class ::{{ through_model_name.id }} < Marten::DB::Model
            field :id, :big_auto, primary_key: true
            field :{{ through_model_from_field_id.id }}, :one_to_many, to: {{ model_klass }}, on_delete: :cascade
            field :{{ through_model_to_field_id.id }}, :one_to_many, to: {{ related_model_klass }}, on_delete: :cascade
          end
        end
      end
    end
  end
end
