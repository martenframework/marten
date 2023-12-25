require "./concerns/record_listing"
require "./template"
require "./schema/*"

module Marten
  module Handlers
    # Handler allowing to process a form through the use of a schema.
    #
    # This handler can be used to process a form and validate its data through the use of a schema. It is expected that
    # the handler will be accessed through a GET request first: when this happens the configured template is rendered
    # and displayed, and the configured schema which is initialized can be accessed from the template context in order
    # to render a form for example. When the form is submitted via a POST request, the configured schema is validated
    # using the form data. If the data is valid, the handler returns an HTTP redirect to a configured success URL.
    #
    # ```
    # class MyFormHandler < Marten::Handlers::Schema
    #   schema MyFormSchema
    #   template_name "my_form.html"
    #   success_route_name "my_form_success"
    # end
    # ```
    #
    # It should be noted that the redirect response issued will be a 302 (found).
    #
    # The schema used to perform the validation can be defined through the use of the `#schema` macro. Alternatively,
    # the `#schema_class` method can also be overridden to dynamically define the schema class as part of the request
    # handling.
    #
    # The `#template_name` class method allows to define the name of the template to use to render the schema while the
    # `#success_route_name` method can be used to specify the name of a route to redirect to once the schema has been
    # validated. Alternatively, the `#sucess_url` class method can be used to provide a raw URL to redirect to. The same
    # method can also be overridden at the instance level in order to rely on a custom logic to generate the sucess URL
    # to redirect to.
    class Schema < Template
      include Callbacks

      # Returns the name to use to include the schema object into the template context (defaults to `schema`).
      class_getter schema_context_name : String = "schema"

      # Returns the route name that should be resolved to produce the URL to redirect to when processing a valid schema.
      #
      # Defaults to `nil`.
      class_getter success_route_name : String?

      # Returns the configured raw URL to redirect when processing a valid schema.
      #
      # Defaults to `nil`.
      class_getter success_url : String?

      before_render :add_schema_to_context

      # Allows to configure the name to use to include the schema into the template context.
      def self.schema_context_name(name : String | Symbol)
        @@schema_context_name = name.to_s
      end

      # Allows to set the route name that should be resolved to produce the URL to when processing a valid schema.
      def self.success_route_name(success_route_name : String?)
        @@success_route_name = success_route_name
      end

      # Allows to configure a raw URL to redirect to when processing a valid schema.
      def self.success_url(success_url : String?)
        @@success_url = success_url
      end

      # Allows to configure the schema class that should be used to process request data.
      macro schema(schema_klass)
        @schema : {{ schema_klass }}? = nil

        # Returns the schema, initialized using the request data.
        def schema
          @schema ||= schema_class.new(request.data, initial_data)
        end

        # Returns the schema class that should be used by the handler.
        def schema_class
          {{ schema_klass }}
        end
      end

      def initial_data
        Marten::Schema::DataHash.new
      end

      def post
        callbacks_response = run_before_validation_callbacks
        return callbacks_response if !callbacks_response.nil?

        valid_schema = schema.valid?

        callbacks_response = run_after_validation_callbacks
        return callbacks_response if !callbacks_response.nil?

        if valid_schema
          callbacks_response = run_after_successful_validation_callbacks
          callbacks_response.nil? ? process_valid_schema : callbacks_response
        else
          callbacks_response = run_after_failed_validation_callbacks
          callbacks_response.nil? ? process_invalid_schema : callbacks_response
        end
      end

      # Produces the response when the processed schema is invalid.
      #
      # By default, this will render the configured template and return a corresponding HTTP response.
      def process_invalid_schema
        render_to_response(context)
      end

      # Produces the response when the processed schema is valid.
      #
      # By default, this will return a 302 redirect targetting the configured success URL.
      def process_valid_schema
        HTTP::Response::Found.new(success_url)
      end

      def put
        post
      end

      # Returns the schema, initialized using the request data.
      def schema
        raise_improperly_configured_schema
      end

      # Returns the schema class that should be used by the handler.
      def schema_class
        raise_improperly_configured_schema
      end

      # Returns the URL to redirect to after the schema has been validated and processed.
      #
      # By default, the URL will be determined from the configured `#success_url` and `#success_route_name` values. This
      # method can be overridden on subclasses in order to define any arbitrary logics that might be necessary in order
      # to determine the schema success URL.
      def success_url
        (
          self.class.success_url ||
            (self.class.success_route_name && reverse(self.class.success_route_name.not_nil!))
        ).not_nil!
      rescue NilAssertionError
        raise Errors::ImproperlyConfigured.new(
          "'#{self.class.name}' must define a success route via the '#success_route_name' or '#success_url' class " \
          "method, or by overridding the '#success_url' method"
        )
      end

      private def add_schema_to_context : Nil
        context[self.class.schema_context_name] = schema
      end

      private def raise_improperly_configured_schema
        raise Errors::ImproperlyConfigured.new(
          "'#{self.class.name}' must define a schema class name via the '#schema' macro, or by overridding the " \
          "'#schema_class' method"
        )
      end
    end
  end
end
