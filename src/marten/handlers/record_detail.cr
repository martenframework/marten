require "./concerns/record_retrieving"
require "./template"

module Marten
  module Handlers
    # Handler allowing to display a specific model record.
    class RecordDetail < Template
      include RecordRetrieving

      # Returns the name to use to include the model record into the template context (defaults to `record`).
      class_getter record_context_name : String = "record"

      # Allows to configure the name to use to include the model record into the template context.
      def self.record_context_name(name : String | Symbol)
        @@record_context_name = name.to_s
      end

      def context
        {self.class.record_context_name => record}
      end
    end
  end
end
