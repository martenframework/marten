require "./concerns/record_retrieving"
require "./template"

module Marten
  module Handlers
    # Handler allowing to display a specific model record.
    #
    # This handler can be used to showcase a specific model record. It is expected that the handler will be accessed
    # through a GET request only: as part of this request, the configured template is rendered and displayed (and the
    # retrieved model record is inserted into the template context)
    #
    # ```
    # class MyRecordHandler < Marten::Handlers::RecordDetail
    #   model MyModel
    #   template_name "my_record.html"
    # end
    # ```
    #
    # The model class used to retrieve the record can be configured through the use of the `#model` macro. The
    # `#template_name` class method allows to define the name of the template to use to render the model record.
    class RecordDetail < Template
      include RecordRetrieving

      # Returns the name to use to include the model record into the template context (defaults to `record`).
      class_getter record_context_name : String = "record"

      before_render :add_record_to_context

      # Allows to configure the name to use to include the model record into the template context.
      def self.record_context_name(name : String | Symbol)
        @@record_context_name = name.to_s
      end

      private def add_record_to_context : Nil
        context[self.class.record_context_name] = record
      end
    end
  end
end
