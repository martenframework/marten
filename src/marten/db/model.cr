require "./model/app_config"
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
      include Persistence
      include Table
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
        kwargs.each { |key, v| values[key.to_s] = v }
        assign_field_values(values)
      end
    end
  end
end
