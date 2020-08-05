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
        assign_field_values(kwargs.to_h.transform_keys(&.to_s))
      end

      def initialize
      end
    end
  end
end
