module Marten
  module Handlers
    # Provides the ability to generate HTTP responses with the content of rendered templates.
    module Rendering
      macro included
        # Returns the configured template name.
        class_getter template_name : String?

        extend Marten::Handlers::Rendering::ClassMethods
      end

      module ClassMethods
        # Allows to configure the template that should be rendered by the handler.
        def template_name(template_name : String?)
          @@template_name = template_name
        end
      end

      # Returns the expected HTTP response for a rendered template content.
      def get_response(content)
        HTTP::Response.new(content)
      end

      # Renders the configured template for a specific `context` object.
      def render_template(context : Hash | NamedTuple | Nil | Marten::Template::Context)
        self.context.merge(context) unless context.nil?
        self.context["handler"] = self
        Marten.templates.get_template(template_name).render(self.context)
      end

      # Renders the configured template for a specific `context` object and produces an HTTP response.
      def render_to_response(context : Hash | NamedTuple | Nil | Marten::Template::Context = nil)
        before_render_response = run_before_render_callbacks

        if before_render_response.is_a?(HTTP::Response)
          before_render_response
        else
          get_response(render_template(context))
        end
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
