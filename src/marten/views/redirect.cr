module Marten
  module Views
    class Redirect < Base
      class_getter forward_query_string : Bool = false
      class_getter permanent : Bool = false
      class_getter route_name : String?
      class_getter url : String?

      def self.forward_query_string(forward_query_string : Bool)
        @@forward_query_string = forward_query_string
      end

      def self.permanent(permanent : Bool)
        @@permanent = permanent
      end

      def self.route_name(route_name : String?)
        @@route_name = route_name
      end

      def self.url(url : String?)
        @@url = url
      end

      def get
        url = redirect_url
        return HTTP::Response::Gone.new if url.nil?
        self.class.permanent ? HTTP::Response::PermanentRedirect.new(url) : HTTP::Response::Redirect.new(url)
      end

      private def redirect_url
        url = self.class.url || (self.class.route_name && reverse(self.class.route_name.not_nil!, params))
        url = "#{url}?#{request.query_params.as_query}" if self.class.forward_query_string
        url
      end
    end
  end
end
