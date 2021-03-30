require "./concerns/rendering"

module Marten
  module Views
    class Template < Base
      include Rendering

      def get
        render_to_response(context)
      end
    end
  end
end
