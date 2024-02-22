module Marten
  module Handlers
    module Defaults
      class BadRequest < Template
        template_name DEFAULT_TEMPLATE_NAME

        def dispatch
          render_to_response(status: 400)
        rescue ex : Marten::Template::Errors::TemplateNotFound
          raise ex if self.class.template_name != DEFAULT_TEMPLATE_NAME
          HTTP::Response::BadRequest.new(content: "Bad Request", content_type: "text/plain")
        end

        private DEFAULT_TEMPLATE_NAME = "400.html"
      end
    end
  end
end
