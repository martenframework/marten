module Marten
  module Handlers
    # Provides helpers around the use of the X-Frame-Options header.
    module XFrameOptions
      macro included
        @@exempt_from_x_frame_options : Bool? = false

        extend Marten::Handlers::XFrameOptions::ClassMethods

        after_dispatch :apply_x_frame_options_exemption
      end

      module ClassMethods
        # Allows to define whether or not the handler responses should be exempted from using X-Frame-Options.
        #
        # Note that this method is only useful when the `Marten::Middleware::XFrameOptions` is being used.
        def exempt_from_x_frame_options(exempt : Bool) : Nil
          @@exempt_from_x_frame_options = exempt
        end

        # Returns a boolean indicating if the handler is exempted from using X-Frame-Options.
        def exempt_from_x_frame_options?
          @@exempt_from_x_frame_options
        end
      end

      private def apply_x_frame_options_exemption
        return if !self.class.exempt_from_x_frame_options?

        response!.headers[:"X-Frame-Options-Exempt"] = "true"
      end
    end
  end
end
