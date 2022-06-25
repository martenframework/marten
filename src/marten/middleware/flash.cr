module Marten
  abstract class Middleware
    # Enables the use of flash messages.
    #
    # When this middleware is used, each request will have a flash store initialized and populated from the request's
    # session store. This flash store is a hash-like object that allows to fetch or set values that are associated
    # with specific keys, and that will only be available to the next request (after that they are cleared out).
    #
    # The flash store depends on the presence of a working session store. As such, the `Marten::Middleware::Session`
    # middleware MUST be used along with this middleware. Moreover, this middleware must be placed _after_ the
    # `Marten::Middleware::Session` in the `Marten.settings.middleware` array of middlewares.
    class Flash < Middleware
      def call(request : Marten::HTTP::Request, get_response : Proc(Marten::HTTP::Response)) : Marten::HTTP::Response
        setup_flash(request)

        response = get_response.call

        persist_flash(request)
        response
      end

      private def persist_flash(request)
        request.flash.persist(request.session)
      end

      private def setup_flash(request)
        request.flash = HTTP::FlashStore.from_session(request.session)
      end
    end
  end
end
