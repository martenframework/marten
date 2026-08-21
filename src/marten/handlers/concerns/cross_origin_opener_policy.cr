module Marten
  module Handlers
    # Provides helpers around the use of the Cross-Origin-Opener-Policy header.
    #
    # The methods provided by this concern assume the use of the `Marten::Middleware::CrossOriginOpenerPolicy`
    # middleware. Using these methods in a project where this middleware is not activated has no effect.
    module CrossOriginOpenerPolicy
      macro included
        @@cross_origin_opener_policy : String? = nil
        @@exempt_from_cross_origin_opener_policy : Bool? = false

        class_getter cross_origin_opener_policy

        extend Marten::Handlers::CrossOriginOpenerPolicy::ClassMethods

        after_dispatch :apply_cross_origin_opener_policy
      end

      module ClassMethods
        # Allows to define a custom Cross-Origin-Opener-Policy that will be used for the considered handler only.
        #
        # ```
        # class MyHandler < Marten::Handler
        #   cross_origin_opener_policy :same_origin_allow_popups
        # end
        # ```
        def cross_origin_opener_policy(value : String | Symbol) : Nil
          @@exempt_from_cross_origin_opener_policy = false
          @@cross_origin_opener_policy = value.to_s.tr("_", "-")
        end

        # Allows to define whether or not the handler responses should be exempted from using
        # Cross-Origin-Opener-Policy.
        #
        # Note that this method is only useful when the `Marten::Middleware::CrossOriginOpenerPolicy` middleware is
        # being used.
        def exempt_from_cross_origin_opener_policy(exempt : Bool) : Nil
          @@cross_origin_opener_policy = nil
          @@exempt_from_cross_origin_opener_policy = exempt
        end

        # Returns a boolean indicating if the handler is exempted from using Cross-Origin-Opener-Policy.
        def exempt_from_cross_origin_opener_policy?
          @@exempt_from_cross_origin_opener_policy
        end
      end

      private def apply_cross_origin_opener_policy
        if self.class.exempt_from_cross_origin_opener_policy?
          response!.headers[:"Cross-Origin-Opener-Policy-Exempt"] = "true"
          return
        end

        return unless value = self.class.cross_origin_opener_policy

        response!.headers[:"Cross-Origin-Opener-Policy"] = value
      end
    end
  end
end
