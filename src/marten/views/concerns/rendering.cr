module Marten
  module Views
    module Rendering
      macro included
        # Returns the configured template name.
        class_getter template : String?

        extend Marten::Views::Rendering::ClassMethods
      end

      module ClassMethods
        # Allows to configure the template that should be rendered by the view.
        def template(template : String?)
          @@template = template
        end
      end

      # Returns a hash containing the template context or `nil`.
      #
      # The default implementation returns `nil`.
      def context
        nil
      end

      # Renders the configured template for a specific `context`.
      def render_to_response(context : Hash?)
        HTTP::Response.new(Marten.templates.get_template(self.class.template.not_nil!).render(context))
      end
    end
  end
end
