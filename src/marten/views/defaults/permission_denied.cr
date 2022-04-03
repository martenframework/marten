module Marten
  module Views
    module Defaults
      class PermissionDenied < Template
        template_name DEFAULT_TEMPLATE_NAME

        def dispatch
          super
        rescue error : Marten::Template::Errors::TemplateNotFound
          raise error if self.class.template_name != DEFAULT_TEMPLATE_NAME
          HTTP::Response::Forbidden.new(content: "403 Forbidden", content_type: "text/plain")
        end

        def get_response(content)
          HTTP::Response::Forbidden.new(content)
        end

        private DEFAULT_TEMPLATE_NAME = "403.html"
      end
    end
  end
end
