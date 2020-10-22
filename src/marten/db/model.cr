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
        values = Hash(String, Field::Any).new
        kwargs.each do |key, value|
          if value.is_a?(Model)
            relation_field = self.class.get_relation_field(key.to_s)
            assign_related_object(value, relation_field)
          else
            values[key.to_s] = value
          end
        end
        assign_field_values(values)
      end
    end
  end
end
