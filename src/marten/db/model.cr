require "./model/app_config"
require "./model/connection"
require "./model/querying"
require "./model/table"

module Marten
  module DB
    abstract class Model
      include AppConfig
      include Connection
      include Table
      include Querying

      LOOKUP_SEP = "__"
      PRIMARY_KEY_ALIAS = "pk"

      # :nodoc:
      @new_record : Bool = true

      def initialize(**kwargs)
        assign_field_values(kwargs.to_h.transform_keys(&.to_s))
      end

      def initialize
      end

      protected setter new_record
    end
  end
end
