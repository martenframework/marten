module Marten
  module Handlers
    module Defaults
      class ServerError < Template
        template_name DEFAULT_TEMPLATE_NAME

        def dispatch
          super
        rescue ex : Marten::Template::Errors::TemplateNotFound
          raise ex if self.class.template_name != DEFAULT_TEMPLATE_NAME
          HTTP::Response::InternalServerError.new(content: "Internal Server Error", content_type: "text/plain")
        end

        def get_response(content)
          HTTP::Response::InternalServerError.new(content)
        end

        private DEFAULT_TEMPLATE_NAME = "500.html"
      end
    end
  end
end
