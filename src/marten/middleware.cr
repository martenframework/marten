module Marten
  # Represents an abstract middleware.
  #
  # A middleware is a simple class that implements a `#call` method that can be hooked into Marten's request/response
  # lifecycle. Middlewares can be used to perform simple alterations based on the incoming HTTP request and the returned
  # HTTP response: for example they can be used to activate a specific I18n locale, to identify a currently logged in
  # user, etc.
  abstract class Middleware
    # :nodoc
    property next : Nil | Middleware

    # Calls the middleware for a given HTTP request and returns a HTTP response.
    #
    # This method must be implemented by subclasses: it takes a `request` argument (the current HTTP request) and a
    # `get_response` proc that allows to get the final response. This proc might actually call the next middleware in
    # the chain of configured middlewares, or the final matched handler. That way, the current middleware have the
    # ability to intercept any incoming request and the associated response, and to modify them if applicable.
    abstract def call(
      request : Marten::HTTP::Request,
      get_response : Proc(Marten::HTTP::Response)
    ) : Marten::HTTP::Response

    # :nodoc:
    def chain(request : Marten::HTTP::Request, last_get_response : Proc(Marten::HTTP::Response))
      Marten::HTTP::Response
      if next_middleware = @next
        call(request, ->{ next_middleware.chain(request, last_get_response) })
      else
        call(request, last_get_response)
      end
    end
  end
end
