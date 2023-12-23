require "./concerns/rendering"

module Marten
  module Handlers
    # Handler allowing to respond to `GET` requests with the content of a rendered HTML template.
    class Template < Base
      include Rendering

      def get
        render_to_response(context)
      end
    end
  end
end
