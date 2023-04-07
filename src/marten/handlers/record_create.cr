require "./schema"

module Marten
  module Handlers
    # Handler allowing to create a new model record by processing a schema.
    #
    # This handler can be used to process a form, validate its data through the use of a schema, and create a record by
    # using the validated data. It is expected that the handler will be accessed through a GET request first: when this
    # happens the configured template is rendered and displayed, and the configured schema which is initialized can be
    # accessed from the template context in order to render a form for example. When the form is submitted via a POST
    # request, the configured schema is validated using the form data. If the data is valid, the corresponding model
    # record is created and the handler returns an HTTP redirect to a configured success URL.
    #
    # ```
    # class MyFormHandler < Marten::Handlers::RecordCreate
    #   model MyModel
    #   schema MyFormSchema
    #   template_name "my_form.html"
    #   success_route_name "my_form_success"
    # end
    # ```
    #
    # It should be noted that the redirect response issued will be a 302 (found).
    #
    # The model class used to create the new record can be configured through the use of the `#model` macro. The schema
    # used to perform the validation can be defined through the use of the `#schema` macro. Alternatively, the
    # `#schema_class` method can also be overridden to dynamically define the schema class as part of the request
    # handling.
    #
    # The `#template_name` class method allows to define the name of the template to use to render the schema while the
    # `#success_route_name` method can be used to specify the name of a route to redirect to once the schema has been
    # validated. Alternatively, the `#sucess_url` class method can be used to provide a raw URL to redirect to. The same
    # method can also be overridden at the instance level in order to rely on a custom logic to generate the sucess URL
    # to redirect to.
    class RecordCreate < Handlers::Schema
      # Allows to configure the model class that should be used to create the new record.
      macro model(model_klass)
        @record : {{ model_klass }}? = nil

        # Returns the created record upon a valid schema processing, returns `nil` otherwise.
        getter record

        # Allows to set the created record upon a valid schema processing.
        setter record

        # Returns the model used to create the new record.
        def model
          {{ model_klass }}
        end
      end

      # Returns the model used to create the new record.
      def model
        raise_improperly_configured_model
      end

      # Produces the response when the processed schema is valid.
      #
      # By default, this will create the new record and return a 302 redirect targetting the configured success URL.
      def process_valid_schema
        self.record = model.new(schema.validated_data)
        self.record.try(&.save!)

        super
      end

      def record
        raise_improperly_configured_model
      end

      def record=(r)
        raise_improperly_configured_model
      end

      private def raise_improperly_configured_model
        raise Errors::ImproperlyConfigured.new(
          "'#{self.class.name}' must define a model class via the '::model' macro or by overriding the " \
          "'#model' method"
        )
      end
    end
  end
end
