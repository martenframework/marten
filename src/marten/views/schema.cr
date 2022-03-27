require "./concerns/record_listing"
require "./template"

module Marten
  module Views
    # View allowing to process a form through the use of a schema.
    #
    # This view can be used to process a form and validate its data through the use of a schema. It is expected that the
    # view will be accessed through a GET request first: when this happens the configured template is rendered and
    # displayed, and the configured schema which is initialized can be accessed from the template context in order to
    # render a form for example. When the form is submitted via a POST request, the configured schema is validated using
    # the form data. If the data is valid, the view returns an HTTP redirect to a configured success URL.
    #
    # ```
    # class MyFormView < Marten::Views::Schema
    #   schema MyFormSchema
    #   template_name "my_form.html"
    #   success_route_name "my_form_success"
    # end
    # ```
    #
    # It should be noted that the redirect response issued will be a 302 (found).
    #
    # The schema used to perform the validation can be defined through the use of the `#schema` class method.
    # Alternatively, the `#schema_class` method can also be overridden to dynamically define the schema class as part of
    # the request view handling.
    #
    # The `#template_name` class method allows to define the name of the template to use to render the schema while the
    # `#success_route_name` method can be used to specify the name of a route to redirect to once the schema has been
    # validated. Alternatively, the `#sucess_url` class method can be used to provide a raw URL to redirect to. The same
    # method can also be overridden at the instance level in order to rely on a custom logic to generate the sucess URL
    # to redirect to.
    class Schema < Template
      @schema : Marten::Schema? = nil

      # Returns the configured schema class.
      class_getter schema : Marten::Schema.class | Nil

      # Returns the route name that should be resolved to produce the URL to redirect to when processing a valid schema.
      #
      # Defaults to `nil`.
      class_getter success_route_name : String?

      # Returns the configured raw URL to redirect when processing a valid schema.
      #
      # Defaults to `nil`.
      class_getter success_url : String?

      # Allows to configure the schema class that should be used to process request data.
      def self.schema(schema : Marten::Schema.class | Nil)
        @@schema = schema
      end

      # Allows to set the route name that should be resolved to produce the URL to when processing a valid schema.
      def self.success_route_name(success_route_name : String?)
        @@success_route_name = success_route_name
      end

      # Allows to configure a raw URL to redirect to when processing a valid schema.
      def self.success_url(success_url : String?)
        @@success_url = success_url
      end

      def context
        {"schema" => schema}
      end

      def post
        schema.valid? ? process_valid_schema : process_invalid_schema
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
        @schema ||= schema_class.new(request.data)
      end

      # Returns the schema class that should be used by the view.
      def schema_class
        self.class.schema || raise Errors::ImproperlyConfigured.new(
          "'#{self.class.name}' must define a schema class name via the '::success_route_name' class method method " \
          "or via the '::success_url' class method"
        )
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
          "'#{self.class.name}' must define a success route the '::schema' class method method or by " \
          "overriding the '#schema_class' method"
        )
      end
    end
  end
end
