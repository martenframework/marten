module Marten
  module Server
    module Handlers
      # Enforces the verification of the HTTP request host.
      #
      # This handlers simply tries to access the request's host in order to ensure that it matches the list of allowed
      # hosts. This verification is necessary in order to mitigate HTTP Host header attacks.
      class HostVerification
        include ::HTTP::Handler

        def call(context : ::HTTP::Server::Context)
          context.marten.request.host
          call_next(context)
        end
      end
    end
  end
end
