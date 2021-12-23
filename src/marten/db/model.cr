require "./model/app_config"
require "./model/comparison"
require "./model/connection"
require "./model/persistence"
require "./model/querying"
require "./model/table"
require "./model/validation"

module Marten
  module DB
    abstract class Model
      include AppConfig

      include Connection
      include Table

      include Comparison
      include Persistence
      include Querying
      include Validation

      def initialize(**kwargs)
        initialize_field_values(**kwargs)
      end

      def initialize(**kwargs, &block)
        initialize_field_values(**kwargs)
        yield self
      end

      private def initialize_field_values(**kwargs)
        values = Hash(String, Field::Any | Model).new

        kwargs.each { |key, value| values[key.to_s] = value }

        self.class.fields.each do |field|
          next if values.has_key?(field.id)
          next if field.default.nil?
          values[field.id] = field.default
        end

        assign_field_values(values)
      end

      macro finished
        {% model_types = Marten::DB::Model.all_subclasses.map(&.name) %}
        {% if model_types.size > 0 %}
          alias Any = {% for t, i in model_types %}{{ t }}{% if i + 1 < model_types.size %} | {% end %}{% end %}
        {% else %}
          alias Any = Nil
        {% end %}
      end
    end
  end
end
