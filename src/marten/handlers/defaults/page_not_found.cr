module Marten
  module Handlers
    module Defaults
      class PageNotFound < Template
        template_name DEFAULT_TEMPLATE_NAME

        def dispatch
          render_to_response(status: 404)
        rescue ex : Marten::Template::Errors::TemplateNotFound
          raise ex if self.class.template_name != DEFAULT_TEMPLATE_NAME
          HTTP::Response::NotFound.new(content: "The requested resource was not found.", content_type: "text/plain")
        end

        private DEFAULT_TEMPLATE_NAME = "404.html"
      end
    end
  end
end
