module Marten
  module Handlers
    # Provides the ability to generate HTTP responses with the content of rendered templates.
    module Rendering
      macro included
        # Returns the configured template name.
        class_getter template_name : String?

        # Returns the configured content type.
        class_getter content_type : String?

        extend Marten::Handlers::Rendering::ClassMethods
      end

      module ClassMethods
        # Allows to configure the content type of the response.
        def content_type(content_type : String?)
          @@content_type = content_type
        end

        # Allows to configure the template that should be rendered by the handler.
        def template_name(template_name : String?)
          @@template_name = template_name
        end
      end

      # Returns the content type of the response.
      def content_type : String
        self.class.content_type || Marten::HTTP::Response::DEFAULT_CONTENT_TYPE
      end

      # Renders the configured template for a specific `context` object and produces an HTTP response.
      def render_to_response(
        context : Hash | NamedTuple | Nil | Marten::Template::Context = nil,
        status : ::HTTP::Status | Int32 = 200
      )
        render(template_name, context: context, status: status, content_type: content_type)
      end

      # Returns the template name that should be rendered by the handler.
      def template_name : String
        self.class.template_name || raise Errors::ImproperlyConfigured.new(
          "'#{self.class.name}' must define a template name via the '::template_name' class method method or by " \
          "overriding the '#template_name' method"
        )
      end
    end
  end
end
