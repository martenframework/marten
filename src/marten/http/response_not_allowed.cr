module Marten
  module HTTP
    class ResponseNotAllowed < Response
      def initialize(allowed_methods : Array(String))
        super(status: 405)
        self["Allow"] = allowed_methods.map(&.upcase).join(", ")
      end
    end
  end
end
