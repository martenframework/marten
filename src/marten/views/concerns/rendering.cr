module Marten
  module Views
    module Rendering
      macro included
        # Returns the configured template name.
        class_getter template_name : String?

        extend Marten::Views::Rendering::ClassMethods
      end

      module ClassMethods
        # Allows to configure the template that should be rendered by the view.
        def template_name(template_name : String?)
          @@template_name = template_name
        end
      end

      # Renders the configured template for a specific `context` object.
      def render_to_response(context : Hash | NamedTuple | Nil | Marten::Template::Context)
        HTTP::Response.new(Marten.templates.get_template(template_name).render(context))
      end

      # Returns the template name that should be rendered by the view.
      def template_name : String
        self.class.template_name || raise Errors::ImproperlyConfigured.new(
          "'#{self.class.name}' must define a template name via the '::template_name' class method method or by " \
          "overriding the '#template_name' method"
        )
      end
    end
  end
end
