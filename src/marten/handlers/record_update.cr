require "./concerns/record_retrieving"
require "./schema"

module Marten
  module Handlers
    # Handler allowing to update a model record by processing a schema.
    #
    # This handler can be used to process a form, validate its data through the use of a schema, and update an existing
    # record by using the validated data. It is expected that the handler will be accessed through a GET request first:
    # when this happens the configured template is rendered and displayed, and the configured schema which is
    # initialized can be accessed from the template context in order to render a form for example. When the form is
    # submitted via a POST request, the configured schema is validated using the form data. If the data is valid, the
    # model record that was retrieved is updated and the handler returns an HTTP redirect to a configured success URL.
    #
    # ```
    # class MyFormHandlers < Marten::Handlers::RecordUpdate
    #   model MyModel
    #   schema MyFormSchema
    #   template_name "my_form.html"
    #   success_route_name "my_form_success"
    # end
    # ```
    #
    # It should be noted that the redirect response issued will be a 302 (found).
    #
    # The model class used to update the record can be configured through the use of the `#model` macro. The schema used
    # to perform the validation can be defined through the use of the `#schema` macro. Alternatively, the
    # `#schema_class` method can also be overridden to dynamically define the schema class as part of the request
    # handling.
    #
    # The `#template_name` class method allows to define the name of the template to use to render the schema while the
    # `#success_route_name` method can be used to specify the name of a route to redirect to once the schema has been
    # validated. Alternatively, the `#sucess_url` class method can be used to provide a raw URL to redirect to. The same
    # method can also be overridden at the instance level in order to rely on a custom logic to generate the sucess URL
    # to redirect to.
    class RecordUpdate < Handlers::Schema
      include RecordRetrieving

      # Returns the name to use to include the model record into the template context (defaults to `record`).
      class_getter record_context_name : String = "record"

      before_render :add_record_to_context

      # Allows to configure the name to use to include the model record into the template context.
      def self.record_context_name(name : String | Symbol)
        @@record_context_name = name.to_s
      end

      # Returns a hash of initial data, computed from the considered record, to prepare the schema.
      def initial_data
        initial_data = HTTP::Params::Data.new

        schema_class.fields.each do |field|
          serialized_value = field.serialize(record.get_field_value(field.id))
          if !serialized_value.nil?
            initial_data[field.id] = [serialized_value]
          end
        rescue DB::Errors::UnknownField
          # noop
        end

        initial_data
      end

      def process_valid_schema
        record.update!(schema.validated_data.select(model.fields.map(&.id)))

        super
      end

      private def add_record_to_context : Nil
        context[self.class.record_context_name] = record
      end
    end
  end
end
