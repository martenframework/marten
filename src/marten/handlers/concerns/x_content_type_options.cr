module Marten
  module Handlers
    # Provides helpers around the use of the X-Content-Type-Options header.
    module XContentTypeOptions
      macro included
        @@exempt_from_x_content_type_options : Bool? = false

        extend Marten::Handlers::XContentTypeOptions::ClassMethods

        after_dispatch :apply_x_content_type_options_exemption
      end

      module ClassMethods
        # Allows to define whether or not the handler responses should be exempted from using X-Content-Type-Options.
        #
        # Note that this method is only useful when the `Marten::Middleware::XContentTypeOptions` middleware is being
        # used.
        def exempt_from_x_content_type_options(exempt : Bool) : Nil
          @@exempt_from_x_content_type_options = exempt
        end

        # Returns a boolean indicating if the handler is exempted from using X-Content-Type-Options.
        def exempt_from_x_content_type_options?
          @@exempt_from_x_content_type_options
        end
      end

      private def apply_x_content_type_options_exemption
        return if !self.class.exempt_from_x_content_type_options?

        response!.headers[:"X-Content-Type-Options-Exempt"] = "true"
      end
    end
  end
end
