module Marten
  module Handlers
    # Provides helpers around the use of the Content-Security header.
    #
    # The methods provided by this concern assume the use of the `Marten::Middleware::ContentSecurityPolicy` middleware.
    # Using these methods in a project where this middleware is not activated has no effect.
    module ContentSecurityPolicy
      macro included
        @@content_security_policy_block : Proc(Marten::HTTP::ContentSecurityPolicy, Nil)?
        @@exempt_from_content_security_policy : Bool? = false

        class_getter content_security_policy_block

        extend Marten::Handlers::ContentSecurityPolicy::ClassMethods

        before_dispatch :apply_content_security_policy_block
        after_dispatch :apply_content_security_policy_exemption
      end

      module ClassMethods
        # Allows to define a custom Content-Security-Policy that will be used for the considered handler only.
        #
        # This method yields a `Marten::HTTP::ContentSecurityPolicy` object that you can use to fully configure the
        # directives that get inserted in the Content-Security-Policy header.
        #
        # ```
        # class MyHandler < Marten::Handler
        #   content_security_policy do |csp|
        #     csp.default_src = {:self, "example.com"}
        #   end
        # end
        # ```
        def content_security_policy(&content_security_policy_block : HTTP::ContentSecurityPolicy ->)
          @@content_security_policy_block = content_security_policy_block
        end

        # Allows to define whether or not the handler responses should be exempted from using Content-Security-Policy.
        #
        # Note that this method is only useful when the `Marten::Middleware::ContentSecurityPolicy` middleware is being
        # used.
        def exempt_from_content_security_policy(exempt : Bool) : Nil
          @@content_security_policy_block = nil
          @@exempt_from_content_security_policy = exempt
        end

        # Returns a boolean indicating if the handler is exempted from using the Content-Security-Policy header.
        def exempt_from_content_security_policy?
          @@exempt_from_content_security_policy
        end
      end

      private def apply_content_security_policy_block
        return if (block = self.class.content_security_policy_block).nil?

        policy = current_content_security_policy
        block.call(policy)
        request.content_security_policy = policy
      end

      private def apply_content_security_policy_exemption
        return if !self.class.exempt_from_content_security_policy?

        response!.headers[:"Content-Security-Policy-Exempt"] = "true"
      end

      private def current_content_security_policy
        request.content_security_policy.try(&.clone) || HTTP::ContentSecurityPolicy.new
      end
    end
  end
end
