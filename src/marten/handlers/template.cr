require "./concerns/rendering"

module Marten
  module Handlers
    # Handler allowing to respond to `GET` requests with the content of a rendered HTML template.
    class Template < Base
      include Rendering

      # Returns a hash containing the template context or `nil`.
      #
      # The default implementation returns `nil`.
      def context
        nil
      end

      def get
        render_to_response(context)
      end
    end
  end
end
